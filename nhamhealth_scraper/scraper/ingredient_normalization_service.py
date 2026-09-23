"""Single conservative identity normalizer for scraping, repair, and image search."""
from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Optional

from .ingredient_ai_cache import ingredient_ai_cache


@dataclass
class NormalizedIngredient:
    canonicalName: str
    preparationNote: str | None
    searchAliases: list[str]
    needsReview: bool = False
    ingredientType: str = "FOOD"
    composite: list[str] | None = None


RULES = {
    "fresh galangal": ("Galangal", "fresh", ["galangal", "fresh galangal"]),
    "green unripe papaya": ("Green Papaya", None, ["green papaya", "unripe papaya"]),
    "pinch salt": ("Salt", None, ["salt"]),
    "ripe durian flesh": ("Durian", "ripe flesh", ["durian", "ripe durian"]),
    "whole small squid": ("Squid", "whole, small", ["squid", "small squid"]),
    "thick coconut milk": ("Coconut Milk", "thick", ["coconut milk", "thick coconut milk"]),
    "tuk trey fish sauce": ("Fish Sauce", None, ["fish sauce", "tuk trey", "tuk trey fish sauce"]),
    "bird s eye chilly": ("Bird's Eye Chilli", None, ["bird's eye chilli", "bird eye chili", "thai chilli"]),
    "broken rice bai pou": ("Broken Rice", None, ["broken rice", "bai pou", "cambodian broken rice"]),
    "cambodian jasmine rice phka rumduol if you can find it": (
        "Phka Rumduol Jasmine Rice",
        None,
        ["phka rumduol rice", "cambodian jasmine rice", "phka rumduol jasmine rice"],
    ),
    "kampot black pepper": ("Kampot Pepper", None, ["kampot pepper", "kampot black pepper", "cambodian kampot pepper"]),
    "kampot black peppercorn": ("Kampot Pepper", None, ["kampot pepper", "kampot black pepper", "cambodian kampot pepper"]),
    "kampot salt field sea salt": ("Sea Salt", None, ["sea salt", "kampot sea salt", "cambodian sea salt"]),
    "snake beans": ("Yardlong Bean", None, ["snake beans", "long beans", "yardlong beans"]),
    "pandan": ("Pandan Leaves", None, ["pandan", "pandan leaf", "screwpine leaves"]),
}

COMPOSITES = {
    "cucumber tomato and a fried egg": ["Cucumber", "Tomato", "Egg"],
    "spring onion and a pinch of white pepper": ["Spring Onion", "White Pepper"],
    "cilantro and scallion": ["Cilantro", "Scallion"],
    "white pepper and fish sauce": ["White Pepper", "Fish Sauce"],
}

EQUIPMENT = {"green bamboo tube", "bamboo skewers per squid"}


def _key(value: str) -> str:
    return " ".join(re.sub(r"[^a-z0-9]+", " ", (value or "").lower()).split())


def normalize_ingredient(value: str) -> NormalizedIngredient:
    key = _key(value)
    if key in EQUIPMENT:
        return NormalizedIngredient(value.title(), None, [], True, "EQUIPMENT")
    if key in COMPOSITES:
        return NormalizedIngredient(value.title(), None, [], True, "FOOD", COMPOSITES[key])
    if key in RULES:
        name, note, aliases = RULES[key]
        return NormalizedIngredient(name, note, aliases)

    # Check persistent AI cache
    cached = ingredient_ai_cache.get(value)
    if cached and cached.get("normalizedName"):
        return NormalizedIngredient(
            cached["normalizedName"],
            cached.get("preparationNote"),
            cached.get("searchAliases") or [key] if key else [],
            False,
        )

    return NormalizedIngredient(" ".join(p.capitalize() for p in key.split()), None, [key] if key else [], False)


def normalize_ingredients_batch(values: list[str]) -> list[NormalizedIngredient]:
    """Batch-normalizes a list of ingredient strings using local rules and persistent cache."""
    return [normalize_ingredient(v) for v in values]
