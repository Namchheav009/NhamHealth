"""Repair normalized catalog ingredient names and Khmer translations using batching and AI fallback."""
from __future__ import annotations

from typing import Optional
import requests

from .ai_usage_tracker import ai_tracker
from .config import settings
from .importer import _get_import_token
from .ingredient_ai_cache import ingredient_ai_cache
from .ingredient_image_resolver import canonical_ingredient_name
from translators.culinary_glossary import INGREDIENTS
from translators.khmer_translator import KhmerTranslator


def invalid_khmer(value: Optional[str], english: Optional[str]) -> bool:
    text = (value or "").strip()
    return (
        not text
        or text.lower() == (english or "").strip().lower()
        or "error" in text.lower()
        or not any("\u1780" <= char <= "\u17ff" for char in text)
    )


def repair_ingredient_translations(max_ai_requests: Optional[int] = None) -> dict[str, int]:
    if max_ai_requests is not None or settings.max_ai_requests is not None:
        ai_tracker.set_budget(max_ai_requests or settings.max_ai_requests)

    base = settings.spring_missing_ingredient_images_url.rsplit("/missing-images", 1)[0]
    headers = {"Authorization": f"Bearer {_get_import_token()}"}
    try:
        response = requests.get(base + "/translation-repair", headers=headers, timeout=30)
        if not response.ok:
            raise RuntimeError(f"Translation repair API {response.status_code}: {response.text[:500]}")
        ingredients = response.json()
    except Exception as exc:
        raise RuntimeError(
            f"Translation repair API failed: {exc}. Ensure Spring Boot is running and "
            "the /api/admin/ingredients/translation-repair endpoint is available."
        )

    if not isinstance(ingredients, list):
        raise RuntimeError(
            "Translation repair API returned an unexpected payload: " + str(ingredients)[:500]
        )

    translator = KhmerTranslator()
    totals = {"checked": 0, "translated": 0, "normalized": 0, "unchanged": 0, "failed": 0}

    # Identify items that need translation / normalization
    pending_items: list[tuple[dict, str, str]] = []  # (item, old_name, canonical_name)
    names_to_batch: list[str] = []

    for item in ingredients:
        totals["checked"] += 1
        old = item["name"]
        name = canonical_ingredient_name(old)
        km = (item.get("nameKm") or "").strip()

        if invalid_khmer(km, old):
            # 1. Local Culinary Glossary (Free)
            glossary_km = INGREDIENTS.get(name.lower(), "")
            if glossary_km:
                km = glossary_km
                ai_tracker.record_avoided()
            # 2. Local Persistent AI Cache (Free)
            elif ingredient_ai_cache:
                cached_entry = ingredient_ai_cache.get(name)
                if cached_entry and cached_entry.get("khmerTranslation"):
                    km = cached_entry["khmerTranslation"]
                    ai_tracker.record_cache_hit()

            if not km and settings.ingredient_translation_ai_enabled:
                names_to_batch.append(name)

        pending_items.append((item, old, name))

    # Batch AI Translation for unresolved items
    batch_translations: dict[str, dict] = {}
    if names_to_batch and settings.ingredient_translation_ai_enabled:
        print(f"Batching {len(names_to_batch)} ingredients for Khmer culinary translation...")
        batch_results = translator.translate_ingredients_batch(names_to_batch, max_batch_size=15)
        for res in batch_results:
            batch_translations[res["original"]] = res
            batch_translations[res["normalizedName"]] = res

    # Process and submit updates
    for index, (item, old, name) in enumerate(pending_items, 1):
        km = (item.get("nameKm") or "").strip()
        if invalid_khmer(km, old):
            if name in batch_translations:
                km = batch_translations[name].get("khmerName") or ""
            elif old in batch_translations:
                km = batch_translations[old].get("khmerName") or ""
            elif INGREDIENTS.get(name.lower()):
                km = INGREDIENTS.get(name.lower())
            totals["translated"] += bool(km)

        if not km or invalid_khmer(km, name):
            totals["failed"] += 1
            continue

        if name == old and km == (item.get("nameKm") or "").strip():
            totals["unchanged"] += 1
            continue

        try:
            resp = requests.put(
                base + f"/{item['id']}/translation",
                json={"name": name, "nameKm": km},
                headers=headers,
                timeout=30,
            )
            if resp.ok:
                totals["normalized"] += name != old
                print(f"[{index}/{len(ingredients)}] {old} -> {name} / {km}: UPDATED")
            else:
                totals["failed"] += 1
        except Exception:
            totals["failed"] += 1

    ai_tracker.print_summary()
    return totals
