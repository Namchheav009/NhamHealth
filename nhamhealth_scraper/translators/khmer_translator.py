import html
import json
import os
import re
import time
import urllib.parse
from typing import Any
import requests
from bs4 import BeautifulSoup

try:
    from scraper.config import settings
    from scraper.ai_usage_tracker import ai_tracker
    from scraper.ingredient_ai_cache import ingredient_ai_cache
except ImportError:
    settings = None
    ai_tracker = None
    ingredient_ai_cache = None

from .culinary_glossary import (
    CATEGORIES,
    COOKING_ACTIONS,
    DISH_NAMES,
    GLOSSARY_VERSION,
    INGREDIENTS,
    MOODS,
    POST_TRANSLATION_FIXES,
    PREPARATION_NOTES,
    STANDARD_UNITS,
    TAGS,
)
from .translation_cache import compute_recipe_hash, translation_cache
from .validator import (
    ValidationResult,
    comprehensive_validate_translation,
    contains_khmer,
    validate_translation,
)


class KhmerTranslator:
    """
    Translates scraped and normalized recipes from English to natural Khmer.
    Designed specifically for food and cooking context, avoiding literal machine translations.
    Uses Google Gemini AI as primary culinary translator with model fallback and offline resilience.
    """

    def __init__(self, timeout_seconds: int = 25):
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
        ) or os.getenv("GEMINI_MODEL", "gemini-3.1-flash-lite")
        self.gemini_fallback_model = (
            getattr(settings, "gemini_fallback_model", None) if settings else None
        ) or os.getenv("GEMINI_FALLBACK_MODEL", "gemini-3.6-flash")
        self.ai_fallback_confidence = (
            getattr(settings, "ai_fallback_confidence", None) if settings else None
        ) or float(os.getenv("AI_FALLBACK_CONFIDENCE", "0.75"))
        self.gemini_base_url = (
            getattr(settings, "gemini_base_url", None) if settings else None
        ) or os.getenv("GEMINI_BASE_URL", "https://generativelanguage.googleapis.com/v1beta")
        self.glossary_version = (
            getattr(settings, "glossary_version", None) if settings else None
        ) or GLOSSARY_VERSION
        configured_qa_retries = (
            getattr(settings, "max_qa_retries", None) if settings else None
        )
        self.max_qa_retries = configured_qa_retries if configured_qa_retries is not None else 0
        self._gemini_cooldown_until = 0.0
        self._used_rate_limit_fallback = False
        self._recipe_gemini_attempted = False

        # Valid candidate models
        self.candidate_models = [self.gemini_model, self.gemini_fallback_model]

    def translate(self, recipe: dict, force: bool = False) -> dict:
        """
        Accept one normalized recipe object and produce both English and Khmer
        translations according to NhamHealth specifications.

        If already translated and valid, skips translation unless force=True.
        Supports translation memory cache by content hash + glossary version.
        Retries correctable translation errors up to max_qa_retries times.
        """
        if not isinstance(recipe, dict):
            return recipe
        self._used_rate_limit_fallback = False
        self._recipe_gemini_attempted = False

        # 1. Check existing translation / skip logic
        if not force and recipe.get("translationStatus") in ("COMPLETED", "PASSED"):
            translations = recipe.get("translations")
            if isinstance(translations, dict) and translations.get("km"):
                is_valid, _ = validate_translation(recipe)
                if is_valid:
                    return recipe

        # 2. Build or extract the English translations container
        en_translation = self._build_english_translation(recipe)

        recipe.setdefault("translations", {})
        recipe["translations"]["en"] = en_translation

        # Ensure nutrition object exists
        recipe["nutrition"] = {
            "calories": recipe.get("calories"),
            "proteinGrams": recipe.get("proteinGrams"),
            "carbsGrams": recipe.get("carbohydrateGrams"),
            "fatGrams": recipe.get("fatGrams"),
            "isNutritionEstimated": recipe.get("isNutritionEstimated", False),
            "nutritionSource": recipe.get("nutritionSource", "SOURCE_ORIGINAL"),
        }

        recipe_hash = compute_recipe_hash(
            recipe,
            glossary_version=self.glossary_version,
            translation_version="2.0",
        )
        recipe["translationHash"] = recipe_hash
        recipe["glossaryVersion"] = self.glossary_version

        # 3. Check translation cache
        if not force:
            cached_km = translation_cache.get_recipe(recipe_hash)
            if cached_km:
                recipe["translations"]["km"] = cached_km
                validation = comprehensive_validate_translation(recipe)
                if validation.status == "PASSED":
                    recipe["translationStatus"] = "COMPLETED"
                    recipe["translationError"] = None
                    recipe["qaReport"] = validation.to_report_string()
                    self._sync_khmer_fields(recipe, cached_km)
                    return recipe

        # 4. Translation attempts with QA validation and retry
        km_translation = None
        validation = None

        for attempt in range(self.max_qa_retries + 1):
            try:
                # Primary: Gemini structured JSON
                if self.gemini_api_key:
                    km_translation = self._translate_recipe_with_gemini(en_translation)

                # Fallback: rule-based glossary translation
                if not km_translation:
                    km_translation = self._translate_to_khmer(en_translation)

                # Override dish name from canonical glossary
                meal_name_en = en_translation.get("mealName", "")
                glossary_name = self._lookup_dish_name_glossary(meal_name_en)
                if glossary_name:
                    km_translation["mealName"] = glossary_name

                recipe["translations"]["km"] = km_translation
                self._sync_khmer_fields(recipe, km_translation)

                # QA validation
                validation = comprehensive_validate_translation(recipe)

                if self._used_rate_limit_fallback and validation.status == "PASSED":
                    validation.status = "NEEDS_REVIEW"
                    validation.warnings.append(
                        "Gemini was rate-limited; fallback Khmer translation requires review."
                    )

                if validation.status in ("PASSED", "NEEDS_REVIEW"):
                    # Success
                    break

                if not validation.can_retry or attempt == self.max_qa_retries:
                    # Cannot retry or reached maximum attempts
                    break

            except Exception as exc:
                recipe["translations"]["km"] = None
                validation = ValidationResult(
                    status="FAILED",
                    issues=[str(exc)],
                    can_retry=False,
                )
                break

        if validation:
            recipe["translationStatus"] = "COMPLETED" if validation.status == "PASSED" else validation.status
            recipe["translationError"] = "; ".join(validation.issues) if validation.issues else None
            recipe["qaReport"] = validation.to_report_string()
            if validation.status == "PASSED" and km_translation:
                translation_cache.set_recipe(recipe_hash, km_translation)
        else:
            recipe["translationStatus"] = "FAILED"
            recipe["translationError"] = "Translation failed to execute."

        # Translate tags and moods
        if recipe.get("tags"):
            recipe["tagsKm"] = [TAGS.get(t.lower(), t) for t in recipe["tags"]]
        if recipe.get("moods"):
            recipe["moodsKm"] = [MOODS.get(m.lower(), m) for m in recipe["moods"]]

        translation_cache.save()
        return recipe

    def _sync_khmer_fields(self, recipe: dict, km: dict) -> None:
        """Synchronize translated Khmer fields to top-level and ingredient/step structures."""
        if not km:
            return
        if km.get("mealName"):
            recipe["khmerName"] = km["mealName"]
        if km.get("category"):
            recipe["categoryNameKm"] = km["category"]
        if km.get("description"):
            recipe["descriptionKm"] = km["description"]

        km_ingredients = km.get("ingredients") or []
        for i, item in enumerate(recipe.get("ingredients") or []):
            if i < len(km_ingredients):
                item["ingredientNameKm"] = km_ingredients[i].get("name")
                item["preparationNoteKm"] = km_ingredients[i].get("note")

        km_steps = km.get("steps") or []
        for i, step in enumerate(recipe.get("steps") or []):
            if i < len(km_steps):
                step_text = km_steps[i]
                if isinstance(step_text, dict):
                    step_text = step_text.get("instruction")
                if isinstance(step, dict):
                    step["instructionKm"] = step_text

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
        if time.monotonic() < self._gemini_cooldown_until:
            self._used_rate_limit_fallback = True
            return None
        self._recipe_gemini_attempted = True

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
            "You are a master Cambodian culinary chef, food writer, and professional translator for NhamHealth (www.nhamhealth.com).\n"
            "Translate the Cambodian recipe from English into authentic, natural, fluent Cambodian Khmer (ភាសាខ្មែរ) with correct Khmer culinary phrasing.\n\n"
            "Strict Translation Rules:\n"
            "1. Script: Use ONLY standard Khmer Unicode script (U+1780 to U+17FF). Never output Thai, Lao, Latin, or romanized syllables.\n"
            "2. Traditional Dish Names:\n"
            "   - 'Bai — Perfect Jasmine Rice' -> 'បាយម្លិះឈ្ងុយឆ្ងាញ់'\n"
            "   - 'Fish Amok' / 'Amok Trey' -> 'អាម៉ុកត្រី'\n"
            "   - 'Bai Sach Chrouk' -> 'បាយសាច់ជ្រូក'\n"
            "   - 'Ang Dtray Meuk' / 'Grilled Squid' -> 'មឹកអាំងទឹកត្រីកោះកុង'\n"
            "   - 'A-Ping' / 'Fried Tarantulas' -> 'អាពីងបំពង'\n"
            "3. Ingredients (Everyday Cambodian Culinary Terms):\n"
            "   - 'broken rice' -> 'បាយពូត' (NEVER 'អង្ករខូច')\n"
            "   - 'edible tarantulas' / 'tarantulas' -> 'អាពីង' (NEVER 'ត្រីធូណា')\n"
            "   - 'whole small squid' / 'squid' -> 'មឹកស្រស់' / 'មឹក' (NEVER 'ត្រីកោណ')\n"
            "   - 'kaffir lime' -> 'ក្រូចសើច', 'kaffir lime leaves' -> 'ស្លឹកក្រូចសើច' (NEVER 'កាហ្វេអ៊ីន')\n"
            "   - 'pinch salt' / 'pinch of salt' -> 'អំបិលមួយចិប'\n"
            "   - 'firm white freshwater fish' -> 'សាច់ត្រីទឹកសាបស្រស់'\n"
            "   - 'slork ngor' -> 'ស្លឹកញ'\n"
            "   - 'yellow kroeung' -> 'គ្រឿងលឿង'\n"
            "   - 'tuk meric' -> 'ទឹកម្រេចក្រូចឆ្មារ'\n"
            "   - 'thick coconut cream' -> 'ក្បាលខ្ទិះដូងខាប់'\n"
            "   - 'prahok' -> 'ប្រហុក'\n"
            "   - 'palm sugar' -> 'ស្ករត្នោត'\n"
            "   - 'fresh coconut water' -> 'ទឹកដូងស្រស់'\n"
            "   - 'squares banana leaf' -> 'ស្លឹកចេកកាត់បួនជ្រុង'\n"
            "4. Cooking Instructions (Fluent Kitchen Khmer):\n"
            "   - Translate into easy-to-understand, step-by-step Cambodian home kitchen instructions.\n"
            "   - End each complete instruction sentence with Khmer full-stop '។'.\n"
            "   - Example: 'Put the rice in the pot and rinse it with water, rubbing the grains gently with your fingers. Drain the water and repeat three or four times until the water runs mostly clear. If you don't rinse the rice, the cooked rice will be sticky and gummy.'\n"
            "     -> 'ដួសអង្ករដាក់ចូលក្នុងឆ្នាំង រួចលាងជម្រះជាមួយទឹក ដោយយកដៃកូរអង្ករថ្នមៗ។ ចាក់ទឹកចេញ រួចលាងជម្រះសារឡើងវិញ ៣ ទៅ ៤ ដង រហូតដល់ទឹកថ្លា។ ប្រសិនបើមិនលាងជម្រះអង្ករទេ បាយដែលដាំរួចនឹងស្អិតខ្លាំង។'\n"
            "5. Strict Output JSON Schema:\n"
            "   {\n"
            "     \"mealName\": \"<Khmer dish name>\",\n"
            "     \"description\": \"<Khmer description or null>\",\n"
            "     \"category\": \"<Khmer category>\",\n"
            "     \"ingredients\": [{\"name\": \"<Khmer ingredient name>\", \"note\": \"<Khmer preparation note or null>\"}],\n"
            "     \"steps\": [\"<Khmer step 1 instruction>\", \"<Khmer step 2 instruction>\"],\n"
            "     \"tags\": [\"<Khmer tag 1>\"]\n"
            "   }\n"
            "6. Cardinality: You MUST return exactly the same number of ingredients and steps as received."
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
        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": self.gemini_api_key,
        }

        for model in self.candidate_models:
            if ai_tracker and not ai_tracker.can_call_ai():
                break
            if ai_tracker:
                ai_tracker.record_request(model)
            url = f"{self.gemini_base_url}/models/{model}:generateContent?key={self.gemini_api_key}"
            try:
                resp = None
                for retry in range(5):
                    resp = self.session.post(url, headers=headers, json=req_body, timeout=self.timeout)
                    if resp.status_code in (429, 503):
                        wait_seconds = 12.0 * (retry + 1)
                        try:
                            err_data = resp.json()
                            msg = err_data.get("error", {}).get("message", "")
                            match = re.search(r"retry in ([0-9.]+)s", msg)
                            if match:
                                wait_seconds = float(match.group(1)) + 1.0
                        except Exception:
                            pass
                        wait_seconds = min(max(wait_seconds, 15.0), 60.0)
                        self._gemini_cooldown_until = time.monotonic() + wait_seconds
                        self._used_rate_limit_fallback = True
                        print(
                            f"  [Gemini Rate-Limit] Using fallback translation; "
                            f"Gemini paused for {wait_seconds:.1f}s."
                        )
                        return None
                    break


                if not resp or not resp.ok:
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
                    canonical_name = INGREDIENTS.get(
                        str(en_item.get("name") or "").strip().lower()
                    )
                    if canonical_name:
                        ing_name = canonical_name
                    elif not ing_name or not contains_khmer(ing_name):
                        ing_name = self.translate_ingredient_name(en_item.get("name") or "")

                    ing_note = km_item.get("note")
                    canonical_note = PREPARATION_NOTES.get(
                        str(en_item.get("note") or "").strip().lower()
                    )
                    if canonical_note:
                        ing_note = canonical_note
                    elif ing_note is not None:
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

                canonical_category = CATEGORIES.get(
                    str(en.get("category") or "").strip().lower()
                )
                km_cat = canonical_category or str(parsed.get("category") or "").strip()
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

    def _lookup_dish_name_glossary(self, name: str) -> str | None:
        """Return the DISH_NAMES glossary entry for a meal name, or None if not found."""
        cleaned = name.strip()
        cleaned = " ".join((name or "").strip().split())
        if not cleaned:
            return None
        lower = cleaned.lower()
        # Normalize typographic quotes and apostrophes
        normalized = cleaned.replace("’", "'").replace("‘", "'").replace("“", '"').replace("”", '"')
        lower = normalized.lower()
        if lower in DISH_NAMES:
            return DISH_NAMES[lower]
        for separator in ("—", "-", ":", "|"):
            if separator in cleaned:
                parts = [p.strip() for p in cleaned.split(separator) if p.strip()]
            if separator in normalized:
                parts = [p.strip() for p in normalized.split(separator) if p.strip()]
                # Try the full compound first (longest match)
                compound = " — ".join(parts).lower()
                if compound in DISH_NAMES:
                    return DISH_NAMES[compound]
                for part in parts:
                    if part.lower() in DISH_NAMES:
                        return DISH_NAMES[part.lower()]
        return None

    def translate_meal_name(self, name: str) -> str:
        """Translate meal name using glossary first, then translation engine."""
        cleaned = name.strip()
        cleaned = " ".join((name or "").strip().split())
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
        # Check glossary with normalized apostrophes/dashes
        glossary_res = self._lookup_dish_name_glossary(cleaned)
        if glossary_res:
            translation_cache.set(cleaned, glossary_res, category="meal_names")
            return glossary_res

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
        cleaned = " ".join((name or "").strip().split())
        if not cleaned:
            return ""

        cached = translation_cache.get(cleaned, category="ingredients")
        if cached:
            return cached

        lower = cleaned.lower()
        normalized = cleaned.replace("’", "'").replace("‘", "'").replace("“", '"').replace("”", '"')
        lower = normalized.lower()
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
        if (
            not self.gemini_api_key
            or not text.strip()
            or self._recipe_gemini_attempted
            or time.monotonic() < self._gemini_cooldown_until
        ):
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

        headers = {
            "Content-Type": "application/json",
            "x-goog-api-key": self.gemini_api_key,
        }

        for model in self.candidate_models:
            url = f"{self.gemini_base_url}/models/{model}:generateContent?key={self.gemini_api_key}"
            for retry_attempt in range(2):
                try:
                    resp = self.session.post(url, headers=headers, json=req_body, timeout=self.timeout)
                    if resp.status_code in (429, 503):
                        self._gemini_cooldown_until = time.monotonic() + 60.0
                        self._used_rate_limit_fallback = True
                        return None
                    if not resp.ok:
                        break
                    data = resp.json()
                    candidates = data.get("candidates") or []
                    if not candidates:
                        break
                    parts = candidates[0].get("content", {}).get("parts") or []
                    if not parts or "text" not in parts[0]:
                        break
                    result = parts[0]["text"].strip()
                    if result and contains_khmer(result):
                        return result
                except Exception:
                    break

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


    def translate_ingredients_batch(
        self,
        ingredient_names: list[str],
        max_batch_size: int = 15,
    ) -> list[dict[str, Any]]:
        """
        Batch translate and normalize ingredient names into authentic natural Khmer.
        Batch size: up to 10-20 ingredients per Gemini request.
        Uses primary model gemini-3.1-flash-lite, fallback to gemini-3.6-flash if confidence < 0.75.
        Results are cached in translation memory and persistent ingredient_ai_cache.
        """
        results_by_name: dict[str, dict[str, Any]] = {}
        unresolved: list[str] = []

        for raw_name in ingredient_names:
            name = (raw_name or "").strip()
            if not name:
                continue

            # 1. Local Culinary Glossary (Free)
            lower_name = name.lower()
            if lower_name in INGREDIENTS:
                km = INGREDIENTS[lower_name]
                if ai_tracker:
                    ai_tracker.record_avoided()
                results_by_name[name] = {
                    "original": name,
                    "normalizedName": name,
                    "preparationNote": None,
                    "khmerName": km,
                    "searchAliases": [name],
                    "confidence": 1.0,
                    "modelUsed": "glossary",
                }
                continue

            # 2. Local Translation Memory Cache (Free)
            cached_km = translation_cache.get(name, category="ingredients")
            if cached_km:
                if ai_tracker:
                    ai_tracker.record_cache_hit()
                results_by_name[name] = {
                    "original": name,
                    "normalizedName": name,
                    "preparationNote": None,
                    "khmerName": cached_km,
                    "searchAliases": [name],
                    "confidence": 1.0,
                    "modelUsed": "cache",
                }
                continue

            # 3. Persistent AI Cache (Free)
            if ingredient_ai_cache:
                ai_entry = ingredient_ai_cache.get(name)
                if ai_entry and ai_entry.get("khmerTranslation"):
                    if ai_tracker:
                        ai_tracker.record_cache_hit()
                    results_by_name[name] = {
                        "original": name,
                        "normalizedName": ai_entry.get("normalizedName", name),
                        "preparationNote": None,
                        "khmerName": ai_entry["khmerTranslation"],
                        "searchAliases": ai_entry.get("searchAliases", [name]),
                        "confidence": ai_entry.get("aiConfidence", 1.0),
                        "modelUsed": ai_entry.get("modelUsed", "ai_cache"),
                    }
                    continue

            unresolved.append(name)

        # Batch unresolved ingredients in chunks (up to max_batch_size, e.g. 15)
        for i in range(0, len(unresolved), max_batch_size):
            chunk = unresolved[i:i + max_batch_size]

            if not self.gemini_api_key or (ai_tracker and not ai_tracker.can_call_ai()):
                # Fallback to local / engine translate for each item
                for item in chunk:
                    try:
                        km = self._engine_translate(item)
                    except Exception:
                        km = self._fallback_substitute(item)
                    results_by_name[item] = {
                        "original": item,
                        "normalizedName": item,
                        "preparationNote": None,
                        "khmerName": km,
                        "searchAliases": [item],
                        "confidence": 0.5,
                        "modelUsed": "fallback_engine",
                    }
                continue

            prompt = (
                "You are an expert Cambodian culinary taxonomist and translator for NhamHealth (www.nhamhealth.com).\\n"
                "Normalize and translate each ingredient into natural Cambodian Khmer (ភាសាខ្មែរ).\\n\\n"
                "Strict Rules:\\n"
                "1. Use ONLY standard Khmer Unicode script (U+1780 to U+17FF) for khmerName. Never use Thai, Lao, or Latin syllables.\\n"
                "2. Standardize culinary terms (e.g. 'Pandan' -> 'ស្លឹកតើយ', 'Fresh Galangal' -> 'រំដេងស្រស់', 'Prahok' -> 'ប្រហុក', 'Snake Beans' -> 'សណ្តែកកួរ', 'Kampot Black Pepper' -> 'ម្រេចខ្មៅកំពត').\\n"
                "3. Extract any preparation note if present (e.g., 'fresh', 'diced', 'minced', 'roasted') or null.\\n"
                "4. Provide 2-3 alternate English searchAliases for each ingredient for image searching.\\n"
                "5. Provide a confidence score between 0.0 and 1.0 for each item.\\n\\n"
                f"Input Ingredients:\\n{json.dumps(chunk, ensure_ascii=False, indent=2)}\\n\\n"
                "Return JSON array ONLY:\\n"
                "[\\n"
                "  {\\n"
                '    "original": "Pandan",\\n'
                '    "normalizedName": "Pandan Leaves",\\n'
                '    "preparationNote": null,\\n'
                '    "khmerName": "ស្លឹកតើយ",\\n'
                '    "searchAliases": ["pandan", "pandan leaf", "screwpine leaves"],\\n'
                '    "confidence": 0.95\\n'
                "  }\\n"
                "]"
            )

            req_body = {
                "contents": [{"parts": [{"text": prompt}]}],
                "generationConfig": {
                    "temperature": 0.2,
                    "responseMimeType": "application/json",
                },
            }
            headers = {
                "Content-Type": "application/json",
                "x-goog-api-key": self.gemini_api_key,
            }

            parsed_list = None
            model_used = self.gemini_model

            # 1. Primary Model: gemini-3.1-flash-lite
            if ai_tracker and ai_tracker.can_call_ai():
                ai_tracker.record_request(self.gemini_model)
                url = f"{self.gemini_base_url}/models/{self.gemini_model}:generateContent?key={self.gemini_api_key}"
                try:
                    resp = self.session.post(url, headers=headers, json=req_body, timeout=self.timeout)
                    if resp.ok:
                        data = resp.json()
                        candidates = data.get("candidates") or []
                        if candidates:
                            text = candidates[0].get("content", {}).get("parts", [{}])[0].get("text", "").strip()
                            if text.startswith("```"):
                                lines = text.splitlines()
                                if lines[0].startswith("```"):
                                    lines = lines[1:]
                                if lines and lines[-1].startswith("```"):
                                    lines = lines[:-1]
                                text = "\n".join(lines).strip()
                            parsed_list = json.loads(text)
                except Exception:
                    parsed_list = None

            # Check if primary model confidence is adequate
            avg_conf = 0.0
            if isinstance(parsed_list, list) and len(parsed_list) == len(chunk):
                scores = [float(p.get("confidence", 0.0)) for p in parsed_list if isinstance(p, dict)]
                avg_conf = sum(scores) / len(scores) if scores else 0.0

            # 2. Fallback Model: gemini-3.6-flash (ONLY if Flash Lite failed or confidence < threshold)
            if (not parsed_list or avg_conf < self.ai_fallback_confidence) and (ai_tracker and ai_tracker.can_call_ai()):
                model_used = self.gemini_fallback_model
                ai_tracker.record_request(self.gemini_fallback_model)
                url = f"{self.gemini_base_url}/models/{self.gemini_fallback_model}:generateContent?key={self.gemini_api_key}"
                try:
                    resp = self.session.post(url, headers=headers, json=req_body, timeout=self.timeout)
                    if resp.ok:
                        data = resp.json()
                        candidates = data.get("candidates") or []
                        if candidates:
                            text = candidates[0].get("content", {}).get("parts", [{}])[0].get("text", "").strip()
                            if text.startswith("```"):
                                lines = text.splitlines()
                                if lines[0].startswith("```"):
                                    lines = lines[1:]
                                if lines and lines[-1].startswith("```"):
                                    lines = lines[:-1]
                                text = "\n".join(lines).strip()
                            parsed_list = json.loads(text)
                except Exception:
                    pass

            if isinstance(parsed_list, list):
                for entry in parsed_list:
                    if not isinstance(entry, dict):
                        continue
                    orig = entry.get("original") or ""
                    norm = entry.get("normalizedName") or orig
                    km = self._apply_post_fixes(entry.get("khmerName") or "")
                    aliases = entry.get("searchAliases") or [norm]
                    conf = float(entry.get("confidence", 0.8))

                    results_by_name[orig] = {
                        "original": orig,
                        "normalizedName": norm,
                        "preparationNote": entry.get("preparationNote"),
                        "khmerName": km,
                        "searchAliases": aliases,
                        "confidence": conf,
                        "modelUsed": model_used,
                    }
                    if km and contains_khmer(km):
                        translation_cache.set(orig, km, category="ingredients")
                        if ingredient_ai_cache:
                            ingredient_ai_cache.set(
                                name_or_key=orig,
                                normalized_name=norm,
                                khmer_translation=km,
                                search_aliases=aliases,
                                ai_confidence=conf,
                                model_used=model_used,
                                status="FOUND",
                            )

            # Any items still missing from this chunk get fallback translation
            for item in chunk:
                if item not in results_by_name:
                    try:
                        km = self._engine_translate(item)
                    except Exception:
                        km = self._fallback_substitute(item)
                    results_by_name[item] = {
                        "original": item,
                        "normalizedName": item,
                        "preparationNote": None,
                        "khmerName": km,
                        "searchAliases": [item],
                        "confidence": 0.5,
                        "modelUsed": "fallback_engine",
                    }

        translation_cache.save()
        return [results_by_name[name] for name in ingredient_names if name in results_by_name]


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

