import html
import json
import os
import re
import urllib.parse
from typing import Any
import requests
from bs4 import BeautifulSoup

try:
    from scraper.config import settings
except ImportError:
    settings = None

from .culinary_glossary import (
    CATEGORIES,
    COOKING_ACTIONS,
    DISH_NAMES,
    INGREDIENTS,
    POST_TRANSLATION_FIXES,
    PREPARATION_NOTES,
    STANDARD_UNITS,
)
from .translation_cache import translation_cache
from .validator import contains_khmer, validate_translation


class KhmerTranslator:
    """
    Translates scraped and normalized recipes from English to natural Khmer.
    Designed specifically for food and cooking context, avoiding literal machine translations.
    Uses Google Gemini AI as primary culinary translator with model fallback and offline resilience.
    """

    def __init__(self, timeout_seconds: int = 40):
        self.timeout = timeout_seconds
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
                          "(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"
        })
        self.gemini_api_key = (
            getattr(settings, "gemini_api_key", None) if settings else None
        ) or os.getenv("GEMINI_API_KEY", "")
        self.gemini_model = (
            getattr(settings, "gemini_model", None) if settings else None
        ) or os.getenv("GEMINI_MODEL", "gemini-3.5-flash-lite")
        self.gemini_base_url = (
            getattr(settings, "gemini_base_url", None) if settings else None
        ) or os.getenv("GEMINI_BASE_URL", "https://generativelanguage.googleapis.com/v1beta")

        # Candidate models tried in sequence if one encounters 429 quota or 404
        self.candidate_models = list(dict.fromkeys([
            self.gemini_model,
            "gemini-3.5-flash-lite",
            "gemini-flash-latest",
            "gemini-3.5-flash",
            "gemini-3.8-flash",
        ]))

    def translate(self, recipe: dict, force: bool = False) -> dict:
        """
        Accept one normalized recipe object and produce both English and Khmer
        translations according to NhamHealth specifications.

        If already translated and valid, skips translation unless force=True.
        If translation fails, records translationStatus='FAILED' and translationError,
        keeping the original English recipe safely intact.
        """
        if not isinstance(recipe, dict):
            return recipe

        # 1. Check existing translation / skip logic
        if not force and recipe.get("translationStatus") == "COMPLETED":
            translations = recipe.get("translations")
            if isinstance(translations, dict) and translations.get("km"):
                is_valid, _ = validate_translation(recipe)
                if is_valid:
                    return recipe

        # 2. Build or extract the English translations container
        en_translation = self._build_english_translation(recipe)

        # 3. Prepare initial structure
        recipe.setdefault("translations", {})
        recipe["translations"]["en"] = en_translation

        # Ensure nutrition object exists
        recipe["nutrition"] = {
            "calories": recipe.get("calories"),
            "proteinGrams": recipe.get("proteinGrams"),
            "carbsGrams": recipe.get("carbohydrateGrams"),
            "fatGrams": recipe.get("fatGrams"),
        }

        # 4. Attempt translation to Khmer
        try:
            km_translation = None

            # Primary approach: translate entire recipe with Gemini AI in a single culinary pass
            if self.gemini_api_key:
                km_translation = self._translate_recipe_with_gemini(en_translation)

            # Fallback approach: translate field-by-field if Gemini was unavailable or failed
            if not km_translation:
                km_translation = self._translate_to_khmer(en_translation)

            recipe["translations"]["km"] = km_translation

            # Update top-level khmerName and categoryNameKm for backward compatibility with Spring Boot importer
            if km_translation.get("mealName"):
                recipe["khmerName"] = km_translation["mealName"]
            if km_translation.get("category"):
                recipe["categoryNameKm"] = km_translation["category"]

            # Validate translation
            is_valid, error_msg = validate_translation(recipe)
            if is_valid:
                recipe["translationStatus"] = "COMPLETED"
                recipe["translationError"] = None
            else:
                recipe["translationStatus"] = "FAILED"
                recipe["translationError"] = error_msg
        except Exception as exc:
            recipe["translations"]["km"] = None
            recipe["translationStatus"] = "FAILED"
            recipe["translationError"] = str(exc)

        # Save cache if updated
        translation_cache.save()
        return recipe

    def _build_english_translation(self, recipe: dict) -> dict:
        """Extract or normalize English text fields from the recipe."""
        ingredients = []
        for item in recipe.get("ingredients") or []:
            name = (item.get("ingredientName") or item.get("name") or "").strip()
            quantity = item.get("quantity")
            unit = item.get("unit")
            note = item.get("preparationNote") or item.get("note")
            ingredients.append({
                "name": name,
                "quantity": quantity,
                "unit": unit,
                "note": note,
            })

        steps = []
        for step in recipe.get("steps") or []:
            if isinstance(step, str):
                steps.append(step.strip())
            elif isinstance(step, dict):
                inst = (step.get("instruction") or "").strip()
                if inst:
                    steps.append(inst)

        return {
            "mealName": (recipe.get("mealName") or "").strip(),
            "description": (recipe.get("description") or "").strip() or None,
            "category": recipe.get("categoryName") or recipe.get("sourceCategory") or "",
            "ingredients": ingredients,
            "steps": steps,
            "tags": list(recipe.get("tags") or []),
        }

    def _translate_to_khmer(self, en: dict) -> dict:
        """Translate the English translation container into natural Khmer."""
        # 1. Meal Name
        meal_name_en = en.get("mealName") or ""
        meal_name_km = self.translate_meal_name(meal_name_en)

        # 2. Description
        desc_en = en.get("description") or ""
        desc_km = self.translate_sentence(desc_en) if desc_en else None

        # 3. Category
        cat_en = en.get("category") or ""
        cat_km = self.translate_category(cat_en)

        # 4. Ingredients
        km_ingredients = []
        for item in en.get("ingredients") or []:
            name_en = item.get("name") or ""
            note_en = item.get("note")

            name_km = self.translate_ingredient_name(name_en)
            note_km = self.translate_preparation_note(note_en) if note_en else None

            km_ingredients.append({
                "name": name_km,
                # Numeric quantity and standard units are preserved exactly
                "quantity": item.get("quantity"),
                "unit": item.get("unit"),
                "note": note_km,
            })

        # 5. Steps / Instructions
        km_steps = []
        for step_text in en.get("steps") or []:
            step_km = self.translate_instruction(step_text)
            km_steps.append(step_km)

        # 6. Tags
        km_tags = []
        for tag in en.get("tags") or []:
            tag_km = self.translate_term(tag, category="tags")
            km_tags.append(tag_km)

        return {
            "mealName": meal_name_km,
            "description": desc_km,
            "category": cat_km,
            "ingredients": km_ingredients,
            "steps": km_steps,
            "tags": km_tags,
        }

    def _translate_recipe_with_gemini(self, en: dict) -> dict | None:
        """
        Translate an entire recipe container (mealName, description, category,
        ingredients, steps, tags) in a single structured Gemini pass.
        Returns a validated Khmer translation dictionary or None on failure.
        """
        if not self.gemini_api_key:
            return None

        # Prepare compact payload for Gemini
        payload_data = {
            "mealName": en.get("mealName", ""),
            "description": en.get("description"),
            "category": en.get("category", ""),
            "ingredients": [
                {
                    "name": item.get("name", ""),
                    "note": item.get("note"),
                }
                for item in (en.get("ingredients") or [])
            ],
            "steps": en.get("steps") or [],
            "tags": en.get("tags") or [],
        }

        system_instruction = (
            "You are an expert Cambodian culinary chef and professional translator for NhamHealth, "
            "a Cambodian nutrition and meal platform.\n"
            "Translate the recipe from English into natural, authentic Cambodian Khmer (ភាសាខ្មែរ).\n\n"
            "Strict Translation Rules:\n"
            "1. Script: Use ONLY standard Khmer Unicode script (U+1780 to U+17FF). Never output Greek, Thai, Lao, Latin or other foreign alphabets.\n"
            "2. Dish names & Ingredients: Use authentic everyday Cambodian culinary terminology "
            "(e.g. 'Fish Amok' -> 'អាម៉ុកត្រី', 'Papaya Salad' -> 'បុកល្ហុង', 'Pork Rice' -> 'បាយសាច់ជ្រូក', "
            "'fish sauce' -> 'ទឹកត្រី', 'garlic' -> 'ខ្ទឹមស', 'shallots' -> 'ខ្ទឹមក្រហម', 'lime' -> 'ក្រូចឆ្មារ', "
            "'tarantulas' -> 'អាពីង', 'crushed peanuts' -> 'សណ្តែកដីលីងបុក', 'squid' -> 'មឹក', 'steamed' -> 'ចំហុយ').\n"
            "3. Cooking Steps: Translate into clear, natural Cambodian kitchen instructions, ending sentences with '។'. "
            "Avoid stiff or literal translation.\n"
            "4. Schema: Return strictly a JSON object with keys: mealName, description, category, "
            "ingredients (list of objects with 'name' and 'note'), steps (list of strings), tags (list of strings).\n"
            "5. Number of items: You MUST preserve the exact same number of ingredients and steps as the input."
        )

        prompt = (
            f"{system_instruction}\n\n"
            f"Recipe to translate (JSON):\n{json.dumps(payload_data, ensure_ascii=False, indent=2)}"
        )

        req_body = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": 0.2,
                "responseMimeType": "application/json",
            },
        }

        en_ingredients = en.get("ingredients") or []
        en_steps = en.get("steps") or []

        for model in self.candidate_models:
            url = f"{self.gemini_base_url}/models/{model}:generateContent?key={self.gemini_api_key}"
            try:
                resp = self.session.post(url, json=req_body, timeout=self.timeout)
                if not resp.ok:
                    continue
                data = resp.json()
                candidates = data.get("candidates") or []
                if not candidates:
                    continue
                parts = candidates[0].get("content", {}).get("parts") or []
                if not parts or "text" not in parts[0]:
                    continue

                raw_text = parts[0]["text"].strip()
                if raw_text.startswith("```"):
                    lines = raw_text.splitlines()
                    if lines[0].startswith("```"):
                        lines = lines[1:]
                    if lines and lines[-1].startswith("```"):
                        lines = lines[:-1]
                    raw_text = "\n".join(lines).strip()

                parsed = json.loads(raw_text)
                if not isinstance(parsed, dict):
                    continue

                # Validate meal name
                km_meal_name = str(parsed.get("mealName") or "").strip()
                if not km_meal_name or not contains_khmer(km_meal_name):
                    continue

                raw_km_ingredients = parsed.get("ingredients") or []
                if len(raw_km_ingredients) != len(en_ingredients):
                    continue

                raw_km_steps = parsed.get("steps") or []
                if len(raw_km_steps) != len(en_steps):
                    continue

                # Build final km ingredients preserving exact quantities and units
                km_ingredients = []
                for en_item, km_item in zip(en_ingredients, raw_km_ingredients):
                    ing_name = str(km_item.get("name") or "").strip()
                    if not ing_name or not contains_khmer(ing_name):
                        ing_name = self.translate_ingredient_name(en_item.get("name") or "")

                    ing_note = km_item.get("note")
                    if ing_note is not None:
                        ing_note = str(ing_note).strip() or None

                    km_ingredients.append({
                        "name": self._apply_post_fixes(ing_name),
                        "quantity": en_item.get("quantity"),
                        "unit": en_item.get("unit"),
                        "note": self._apply_post_fixes(ing_note) if ing_note else None,
                    })

                # Build final km steps
                km_steps = []
                for en_step_text, km_step_text in zip(en_steps, raw_km_steps):
                    step_str = str(km_step_text).strip()
                    if not step_str or not contains_khmer(step_str):
                        step_str = self.translate_instruction(en_step_text)
                    else:
                        step_str = self._apply_post_fixes(step_str)
                        if en_step_text.strip().endswith(".") and not step_str.endswith("។"):
                            step_str = re.sub(r"[.\s]+$", "", step_str) + "។"
                    km_steps.append(step_str)

                # Category & Description
                km_desc = parsed.get("description")
                if km_desc is not None:
                    km_desc = self._apply_post_fixes(str(km_desc).strip()) or None

                km_cat = str(parsed.get("category") or "").strip()
                if not km_cat or not contains_khmer(km_cat):
                    km_cat = self.translate_category(en.get("category") or "")
                else:
                    km_cat = self._apply_post_fixes(km_cat)

                # Tags
                km_tags = []
                for tag in parsed.get("tags") or []:
                    tag_str = str(tag).strip()
                    if tag_str:
                        km_tags.append(self._apply_post_fixes(tag_str))

                km_result = {
                    "mealName": self._apply_post_fixes(km_meal_name),
                    "description": km_desc,
                    "category": km_cat,
                    "ingredients": km_ingredients,
                    "steps": km_steps,
                    "tags": km_tags,
                }

                # Seed cache
                if en.get("mealName"):
                    translation_cache.set(en["mealName"].strip(), km_result["mealName"], category="meal_names")
                if en.get("category"):
                    translation_cache.set(en["category"].strip(), km_result["category"], category="categories")
                for en_ing, km_ing in zip(en_ingredients, km_ingredients):
                    if en_ing.get("name"):
                        translation_cache.set(en_ing["name"].strip(), km_ing["name"], category="ingredients")
                    if en_ing.get("note") and km_ing.get("note"):
                        translation_cache.set(en_ing["note"].strip(), km_ing["note"], category="notes")
                for en_st, km_st in zip(en_steps, km_steps):
                    translation_cache.set(en_st.strip(), km_st, category="steps")

                return km_result

            except Exception:
                continue

        return None

    def translate_meal_name(self, name: str) -> str:
        """Translate meal name using glossary first, then translation engine."""
        cleaned = name.strip()
        if not cleaned:
            return ""

        cached = translation_cache.get(cleaned, category="meal_names")
        if cached:
            return cached

        lower = cleaned.lower()
        # Exact match
        if lower in DISH_NAMES:
            res = DISH_NAMES[lower]
            translation_cache.set(cleaned, res, category="meal_names")
            return res

        # Check if the name has an em-dash or separator (e.g. "Amok Trey — Fish Amok ...")
        for separator in ("—", "-", ":", "|"):
            if separator in cleaned:
                parts = [p.strip() for p in cleaned.split(separator) if p.strip()]
                for part in parts:
                    if part.lower() in DISH_NAMES:
                        res = DISH_NAMES[part.lower()]
                        translation_cache.set(cleaned, res, category="meal_names")
                        return res

        # Otherwise translate via engine and post-process
        res = self._engine_translate(cleaned)
        res = self._apply_post_fixes(res)
        translation_cache.set(cleaned, res, category="meal_names")
        return res

    def translate_ingredient_name(self, name: str) -> str:
        """Translate ingredient name preserving culinary accuracy."""
        cleaned = name.strip()
        if not cleaned:
            return ""

        cached = translation_cache.get(cleaned, category="ingredients")
        if cached:
            return cached

        lower = cleaned.lower()
        # Direct lookup in culinary glossary
        if lower in INGREDIENTS:
            res = INGREDIENTS[lower]
            translation_cache.set(cleaned, res, category="ingredients")
            return res

        # Check partial/stem matches (e.g., "skinless chicken breast" -> contains "chicken breast")
        for eng_term, km_term in INGREDIENTS.items():
            if re.search(rf"\b{re.escape(eng_term)}\b", lower):
                # If the key match covers most of the term
                if len(eng_term) >= len(lower) * 0.6:
                    translation_cache.set(cleaned, km_term, category="ingredients")
                    return km_term

        # Online translation engine with culinary post-fixes
        res = self._engine_translate(cleaned)
        res = self._apply_post_fixes(res)
        translation_cache.set(cleaned, res, category="ingredients")
        return res

    def translate_preparation_note(self, note: str) -> str:
        """Translate preparation note (e.g. 'chop finely' -> 'ហាន់ឲ្យម៉ត់')."""
        cleaned = note.strip()
        if not cleaned:
            return ""

        cached = translation_cache.get(cleaned, category="notes")
        if cached:
            return cached

        lower = cleaned.lower()
        if lower in PREPARATION_NOTES:
            res = PREPARATION_NOTES[lower]
            translation_cache.set(cleaned, res, category="notes")
            return res

        # Check partial note phrases
        for eng_note, km_note in PREPARATION_NOTES.items():
            if eng_note in lower:
                translation_cache.set(cleaned, km_note, category="notes")
                return km_note

        res = self._engine_translate(cleaned)
        res = self._apply_post_fixes(res)
        translation_cache.set(cleaned, res, category="notes")
        return res

    def translate_category(self, category: str) -> str:
        """Translate meal category name."""
        cleaned = category.strip()
        if not cleaned:
            return ""

        lower = cleaned.lower()
        if lower in CATEGORIES:
            return CATEGORIES[lower]

        res = self._engine_translate(cleaned)
        return self._apply_post_fixes(res)

    def translate_instruction(self, step: str) -> str:
        """Translate cooking instruction/step text into natural cooking Khmer."""
        cleaned = " ".join(step.split())
        if not cleaned:
            return ""

        cached = translation_cache.get(cleaned, category="steps")
        if cached:
            return cached

        res = self._engine_translate(cleaned)
        res = self._apply_post_fixes(res)

        # Ensure sentence ends with Khmer period (។) if English ended with a period
        if cleaned.endswith(".") and not res.endswith("។"):
            res = re.sub(r"[.\s]+$", "", res) + "។"

        translation_cache.set(cleaned, res, category="steps")
        return res

    def translate_sentence(self, text: str) -> str:
        """Translate a descriptive sentence with culinary enhancements."""
        cleaned = " ".join(text.split())
        if not cleaned:
            return ""

        cached = translation_cache.get(cleaned, category="sentences")
        if cached:
            return cached

        res = self._engine_translate(cleaned)
        res = self._apply_post_fixes(res)
        translation_cache.set(cleaned, res, category="sentences")
        return res

    def translate_term(self, term: str, category: str = "general") -> str:
        cleaned = term.strip()
        if not cleaned:
            return ""
        cached = translation_cache.get(cleaned, category=category)
        if cached:
            return cached
        res = self._engine_translate(cleaned)
        res = self._apply_post_fixes(res)
        translation_cache.set(cleaned, res, category=category)
        return res

    def _translate_gemini_text(self, text: str) -> str | None:
        """Translate a single text string using Gemini AI with model fallback."""
        if not self.gemini_api_key or not text.strip():
            return None

        prompt = (
            "You are an expert Cambodian culinary chef and professional translator for NhamHealth.\n"
            "Translate the following food and cooking text into natural, authentic Cambodian Khmer (ភាសាខ្មែរ).\n"
            "Use ONLY standard Khmer Unicode script (U+1780 to U+17FF). Never use Thai, Lao, or Latin letters.\n"
            "Do not translate numbers or standard measurement units (e.g. g, ml, tbsp, tsp, kg).\n"
            "Return ONLY the translated Khmer text, without explanations, markdown, or pronunciation guides.\n\n"
            f"Text: {text.strip()}"
        )

        req_body = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {"temperature": 0.2},
        }

        for model in self.candidate_models:
            url = f"{self.gemini_base_url}/models/{model}:generateContent?key={self.gemini_api_key}"
            try:
                resp = self.session.post(url, json=req_body, timeout=self.timeout)
                if not resp.ok:
                    continue
                data = resp.json()
                candidates = data.get("candidates") or []
                if not candidates:
                    continue
                parts = candidates[0].get("content", {}).get("parts") or []
                if not parts or "text" not in parts[0]:
                    continue
                result = parts[0]["text"].strip()
                if result and contains_khmer(result):
                    return result
            except Exception:
                continue

        return None

    def _engine_translate(self, text: str) -> str:
        """
        Execute translation using the available engines:
        1. Google Gemini AI (if GEMINI_API_KEY configured)
        2. OpenAI LLM (if OPENAI_API_KEY configured)
        3. Google Translate mobile endpoint
        4. Fallback to MyMemory translation API
        5. Local term replacement fallback if offline
        """
        # If text is already mostly Khmer characters, return as is
        if contains_khmer(text) and len(re.findall(r"[\u1780-\u17FF]", text)) > len(text) * 0.5:
            return text

        # 1. Gemini AI translation
        if self.gemini_api_key:
            gemini_res = self._translate_gemini_text(text)
            if gemini_res:
                return gemini_res

        # 2. OpenAI translation if API key is provided
        openai_key = os.getenv("OPENAI_API_KEY")
        if openai_key:
            llm_result = self._try_llm_translate(text, openai_key, None)
            if llm_result:
                return llm_result

        # Primary engine: Google Translate web
        try:
            res = self._translate_google(text)
            if res and contains_khmer(res):
                return res
        except Exception:
            pass

        # Secondary engine: MyMemory API
        try:
            res = self._translate_mymemory(text)
            if res and contains_khmer(res):
                return res
        except Exception:
            pass

        # Fallback: rule-based word-by-word substitution using glossary
        substituted = self._fallback_substitute(text)
        if contains_khmer(substituted):
            return substituted

        raise RuntimeError(f"Unable to translate text to Khmer: '{text[:50]}'")

    def _translate_google(self, text: str) -> str:
        url = "https://translate.google.com/m"
        params = {"sl": "en", "tl": "km", "q": text}
        resp = self.session.get(url, params=params, timeout=self.timeout)
        if not resp.ok:
            raise RuntimeError(f"Google Translate HTTP {resp.status_code}")
        soup = BeautifulSoup(resp.text, "html.parser")
        div = soup.find("div", class_="result-container")
        if div and div.text:
            return html.unescape(div.text.strip())
        raise RuntimeError("No translation result found in Google response.")

    def _translate_mymemory(self, text: str) -> str:
        url = "https://api.mymemory.translated.net/get"
        params = {"q": text, "langpair": "en|km"}
        resp = self.session.get(url, params=params, timeout=self.timeout)
        if not resp.ok:
            raise RuntimeError(f"MyMemory HTTP {resp.status_code}")
        data = resp.json()
        translated = data.get("responseData", {}).get("translatedText")
        if translated:
            return html.unescape(translated.strip())
        raise RuntimeError("No translation in MyMemory response.")

    def _try_llm_translate(self, text: str, openai_key: str | None, gemini_key: str | None) -> str | None:
        """Optional LLM translation when an API key is present."""
        prompt = (
            "You are an expert Cambodian culinary chef and translator. Translate the following text into "
            "natural, authentic Khmer for a recipe. Do not translate numbers or standard units (g, ml, tbsp, etc.). "
            "Return ONLY the Khmer translation without explanation.\n\n"
            f"Text: {text}"
        )
        if openai_key:
            try:
                r = self.session.post(
                    "https://api.openai.com/v1/chat/completions",
                    headers={"Authorization": f"Bearer {openai_key}"},
                    json={
                        "model": "gpt-4o-mini",
                        "messages": [{"role": "user", "content": prompt}],
                        "temperature": 0.2,
                    },
                    timeout=self.timeout,
                )
                if r.ok:
                    return r.json()["choices"][0]["message"]["content"].strip()
            except Exception:
                pass
        return None

    def _apply_post_fixes(self, text: str | None) -> str | None:
        """Apply Cambodian culinary substitutions to correct awkward literal machine translation."""
        if not text:
            return text
        result = text
        for literal, natural in POST_TRANSLATION_FIXES:
            result = result.replace(literal, natural)
        result = result.replace("សាច់សាច់", "សាច់")
        result = result.replace("ដ៏ τέλειο", "ដ៏ល្អឥតខ្ចោះ")
        result = result.replace("τέλειο", "ល្អឥតខ្ចោះ")
        # Remove any stray non-Khmer alphabet characters (Greek, Thai, Cyrillic) if LLM slipped
        result = re.sub(r"[\u0370-\u03FF\u0E00-\u0E7F]+", "", result)
        return result.strip()


    def _fallback_substitute(self, text: str) -> str:
        """Offline fallback using direct dictionary lookups."""
        lower = text.lower().strip()
        if lower in DISH_NAMES:
            return DISH_NAMES[lower]
        if lower in INGREDIENTS:
            return INGREDIENTS[lower]
        if lower in PREPARATION_NOTES:
            return PREPARATION_NOTES[lower]
        if lower in COOKING_ACTIONS:
            return COOKING_ACTIONS[lower]
        if lower in CATEGORIES:
            return CATEGORIES[lower]
        return text


# Global singleton instance
khmer_translator = KhmerTranslator()

