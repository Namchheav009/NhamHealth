import json
import re
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup, Tag

from .config import HEADERS, settings
from .ingredient_parser import parse_ingredient_line
from .nutrition_estimator import estimate_recipe_nutrition


KHMER_RE = re.compile(r"[\u1780-\u17FF]")

CATEGORY_MAP = {
    "Noodles & Breakfast": "Breakfast",
    "Samlor & Soups": "Dinner",
    "Amok, Curries & Stir-Fries": "Lunch",
    "Grills & Street Food": "Lunch",
    "Salads & Pickles": "Lunch",
    "Sweets & Drinks": "Snacks",
    "Foundations": "Other",
}

DIFFICULTY_MAP = {
    "beginner": "EASY",
    "intermediate": "MEDIUM",
    "advanced": "HARD",
}


def _duration_to_minutes(value):
    if not value:
        return None

    # Handles common ISO-8601 recipe durations such as PT30M / PT1H20M.
    m = re.fullmatch(r"PT(?:(\d+)H)?(?:(\d+)M)?", str(value).strip())
    if not m:
        return None

    hours = int(m.group(1) or 0)
    minutes = int(m.group(2) or 0)
    return hours * 60 + minutes


def _image_from_jsonld(image):
    if isinstance(image, str):
        return image
    if isinstance(image, list) and image:
        return _image_from_jsonld(image[0])
    if isinstance(image, dict):
        return image.get("url") or image.get("contentUrl")
    return None


def _normalize_jsonld_steps(raw_steps):
    if not raw_steps:
        return []

    if isinstance(raw_steps, str):
        return [{"stepNumber": 1, "instruction": raw_steps.strip()}]

    steps = []

    def add_step(text):
        text = " ".join((text or "").split())
        if text:
            steps.append({"stepNumber": len(steps) + 1, "instruction": text})

    for item in raw_steps:
        if isinstance(item, str):
            add_step(item)
            continue

        if not isinstance(item, dict):
            continue

        item_type = item.get("@type")

        if item_type == "HowToSection":
            for child in item.get("itemListElement", []):
                if isinstance(child, dict):
                    add_step(child.get("text") or child.get("name"))
        else:
            add_step(item.get("text") or item.get("name"))

    return steps


def _find_recipe_jsonld(soup: BeautifulSoup):
    for script in soup.find_all("script", attrs={"type": "application/ld+json"}):
        raw = script.string or script.get_text()
        if not raw.strip():
            continue

        try:
            parsed = json.loads(raw)
        except Exception:
            continue

        candidates = []
        if isinstance(parsed, list):
            candidates.extend(parsed)
        elif isinstance(parsed, dict):
            candidates.extend(parsed.get("@graph", [parsed]))

        for item in candidates:
            if not isinstance(item, dict):
                continue
            type_value = item.get("@type")
            if type_value == "Recipe" or (
                isinstance(type_value, list) and "Recipe" in type_value
            ):
                return item

    return None


def _parse_jsonld_recipe(soup: BeautifulSoup, url: str):
    data = _find_recipe_jsonld(soup)
    if not data:
        return None

    raw_ingredients = data.get("recipeIngredient") or []
    ingredients = []
    for line in raw_ingredients:
        ingredients.extend(parse_ingredient_line(str(line)))

    nutrition = data.get("nutrition") or {}

    calories = nutrition.get("calories")
    if isinstance(calories, str):
        m = re.search(r"[\d.]+", calories)
        calories = float(m.group()) if m else None

    def grams(field):
        value = nutrition.get(field)
        if isinstance(value, str):
            m = re.search(r"[\d.]+", value)
            return float(m.group()) if m else None
        return value

    yield_value = data.get("recipeYield")
    servings = None
    if yield_value is not None:
        m = re.search(r"\d+", str(yield_value))
        servings = int(m.group()) if m else None

    return {
        "mealName": data.get("name"),
        "khmerName": None,
        "description": " ".join(str(data.get("description") or "").split()) or None,
        "sourceCategory": data.get("recipeCategory"),
        "categoryName": None,
        "sourceImageUrl": _image_from_jsonld(data.get("image")),
        "prepTimeMinutes": _duration_to_minutes(data.get("prepTime")),
        "cookingTimeMinutes": _duration_to_minutes(data.get("cookTime")),
        "difficulty": None,
        "servings": servings,
        "calories": calories,
        "proteinGrams": grams("proteinContent"),
        "carbohydrateGrams": grams("carbohydrateContent"),
        "fatGrams": grams("fatContent"),
        "nutritionBasis": "PER_SERVING" if nutrition else "UNKNOWN",
        "ingredients": ingredients,
        "steps": _normalize_jsonld_steps(data.get("recipeInstructions")),
        "sourceLanguage": "en",
        "sourceName": "Cambodian Cookbook",
        "sourceUrl": url,
    }


def _text_between(start: Tag, stop_predicate):
    current = start.find_next()
    while current:
        if isinstance(current, Tag) and stop_predicate(current):
            break
        yield current
        current = current.find_next()


def _find_heading(soup, level: str, contains: str):
    contains_lower = contains.lower()
    for heading in soup.find_all(level):
        text = " ".join(heading.stripped_strings)
        if contains_lower in text.lower():
            return heading
    return None


def _first_paragraph_after(heading: Tag):
    p = heading.find_next("p")
    if p:
        return " ".join(p.stripped_strings)
    return None


def _extract_cambodian_cookbook_html(soup: BeautifulSoup, url: str):
    h1 = soup.find("h1")
    if not h1:
        raise ValueError("Recipe page has no H1 title.")

    meal_name = " ".join(h1.stripped_strings).strip()

    khmer_name = None
    current = h1.find_next()
    while current and getattr(current, "name", None) not in {"h2"}:
        text = " ".join(current.stripped_strings) if isinstance(current, Tag) else ""
        if text and KHMER_RE.search(text) and len(text) <= 80:
            khmer_name = text
            break
        current = current.find_next()

    description = _first_paragraph_after(h1)

    full_text = soup.get_text("\n", strip=True)

    def int_after(label):
        m = re.search(rf"{re.escape(label)}\s*(\d+)\s*min", full_text, flags=re.I)
        return int(m.group(1)) if m else None

    prep_minutes = int_after("Prep")
    cook_minutes = int_after("Cook")

    servings = None
    m = re.search(r"Serves\s*(\d+)", full_text, flags=re.I)
    if m:
        servings = int(m.group(1))

    difficulty = None
    m = re.search(r"Level\s*(Beginner|Intermediate|Advanced)", full_text, flags=re.I)
    if m:
        difficulty = DIFFICULTY_MAP.get(m.group(1).lower())

    source_category = None
    category_name = None
    for source, mapped in CATEGORY_MAP.items():
        if soup.find("a", string=lambda s: s and source.lower() in s.lower()):
            source_category = source
            category_name = mapped
            break

    source_image_url = None
    for attrs in (
        {"property": "og:image"},
        {"name": "twitter:image"},
    ):
        meta = soup.find("meta", attrs=attrs)
        if meta and meta.get("content"):
            source_image_url = urljoin(url, meta["content"])
            break

    if not source_image_url:
        image = soup.find(
            "img",
            alt=lambda value: value and meal_name.lower() in value.lower(),
        ) or soup.find("img")
        if image:
            candidate = (
                image.get("src")
                or image.get("data-src")
                or image.get("data-lazy-src")
            )
            if candidate:
                source_image_url = urljoin(url, candidate)

    ingredients_heading = _find_heading(soup, "h2", "Ingredients")
    method_heading = _find_heading(soup, "h2", "Method")

    ingredients = []
    if ingredients_heading:
        seen_li = set()
        display_order = 1

        for node in _text_between(
            ingredients_heading,
            lambda tag: (
                tag.name == "h2"
                and "method" in " ".join(tag.stripped_strings).lower()
            )
            or (
                tag.name == "h3"
                and "stock the pantry" in " ".join(tag.stripped_strings).lower()
            ),
        ):
            if not isinstance(node, Tag) or node.name != "li":
                continue

            marker = id(node)
            if marker in seen_li:
                continue
            seen_li.add(marker)

            line = " ".join(node.stripped_strings)
            if not line:
                continue

            for parsed in parse_ingredient_line(line):
                parsed["displayOrder"] = display_order
                display_order += 1
                ingredients.append(parsed)

    steps = []
    if method_heading:
        current = method_heading.find_next()
        pending_title = None

        while current:
            if isinstance(current, Tag) and current.name == "h2" and current is not method_heading:
                break

            if isinstance(current, Tag) and current.name == "h3":
                title_text = " ".join(current.stripped_strings)
                if re.search(r"\bStep\s*\d+\b", title_text, flags=re.I):
                    pending_title = re.sub(
                        r"^\s*Step\s*\d+\s*:\s*",
                        "",
                        title_text,
                        flags=re.I,
                    ).strip()

                    p = current.find_next("p")
                    if p:
                        instruction = " ".join(p.stripped_strings)
                        if instruction:
                            steps.append(
                                {
                                    "stepNumber": len(steps) + 1,
                                    # Current NhamHealth Admin UI only needs instruction.
                                    "instruction": instruction,
                                    # Preserved for review but importer may ignore it.
                                    "originalStepTitle": pending_title or None,
                                }
                            )
            current = current.find_next()

    return {
        "mealName": meal_name,
        "khmerName": khmer_name,
        "description": description,
        "sourceCategory": source_category,
        "categoryName": category_name,
        "sourceImageUrl": source_image_url,
        "prepTimeMinutes": prep_minutes,
        "cookingTimeMinutes": cook_minutes,
        "difficulty": difficulty,
        "servings": servings,
        # This site does not show nutrition on the inspected recipe page.
        # Do not invent zeros.
        "calories": None,
        "proteinGrams": None,
        "carbohydrateGrams": None,
        "fatGrams": None,
        "nutritionBasis": "UNKNOWN",
        "ingredients": ingredients,
        "steps": steps,
        "sourceLanguage": "en",
        "sourceName": "Cambodian Cookbook",
        "sourceUrl": url,
    }


def scrape_recipe(url: str) -> dict:
    response = requests.get(
        url,
        headers=HEADERS,
        timeout=settings.request_timeout_seconds,
    )
    response.raise_for_status()

    soup = BeautifulSoup(response.text, "lxml")

    # Prefer structured Recipe schema when the site provides it.
    recipe = _parse_jsonld_recipe(soup, url)

    # Use site-specific fallback for fields not present in Recipe JSON-LD.
    fallback = _extract_cambodian_cookbook_html(soup, url)

    if recipe is None:
        recipe = fallback
    else:
        for key, value in fallback.items():
            if recipe.get(key) in (None, "", [], "UNKNOWN"):
                recipe[key] = value

    if recipe.get("calories") is None or recipe.get("proteinGrams") is None:
        estimate_recipe_nutrition(recipe)

    return recipe
