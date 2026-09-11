"""
Intelligent nutrition estimation engine for Cambodian / Southeast Asian recipes.
Calculates realistic macronutrients (calories, protein, carbs, fat) per serving
from parsed ingredient names, quantities, and units.
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class NutrientProfile:
    calories: float
    protein: float
    carbs: float
    fat: float


# Reference macros per 100g
NUTRITION_DATABASE: dict[str, NutrientProfile] = {
    # Meats
    "pork": NutrientProfile(242, 26.0, 0.0, 14.0),
    "pork shoulder": NutrientProfile(240, 25.0, 0.0, 15.0),
    "pork belly": NutrientProfile(518, 9.3, 0.0, 53.0),
    "pork loin": NutrientProfile(198, 27.0, 0.0, 9.0),
    "pork rib": NutrientProfile(277, 20.0, 0.0, 21.0),
    "ground pork": NutrientProfile(260, 25.0, 0.0, 17.0),
    "minced pork": NutrientProfile(260, 25.0, 0.0, 17.0),
    "chicken": NutrientProfile(190, 27.0, 0.0, 8.5),
    "chicken breast": NutrientProfile(165, 31.0, 0.0, 3.6),
    "chicken thigh": NutrientProfile(209, 26.0, 0.0, 10.9),
    "chicken wing": NutrientProfile(222, 24.0, 0.0, 13.0),
    "beef": NutrientProfile(250, 26.0, 0.0, 15.0),
    "beef flank": NutrientProfile(200, 27.0, 0.0, 10.0),
    "duck": NutrientProfile(201, 19.0, 0.0, 14.0),

    # Seafood
    "squid": NutrientProfile(92, 15.6, 3.1, 1.4),
    "calamari": NutrientProfile(92, 15.6, 3.1, 1.4),
    "cuttlefish": NutrientProfile(79, 16.2, 0.8, 0.7),
    "octopus": NutrientProfile(82, 14.9, 2.2, 1.0),
    "prawn": NutrientProfile(99, 24.0, 0.2, 0.3),
    "prawns": NutrientProfile(99, 24.0, 0.2, 0.3),
    "shrimp": NutrientProfile(99, 24.0, 0.2, 0.3),
    "fish": NutrientProfile(105, 20.0, 0.0, 2.5),
    "snakehead": NutrientProfile(100, 19.0, 0.0, 2.0),
    "catfish": NutrientProfile(120, 18.0, 0.0, 5.0),
    "tilapia": NutrientProfile(96, 20.0, 0.0, 1.7),
    "salmon": NutrientProfile(208, 20.0, 0.0, 13.0),
    "crab": NutrientProfile(87, 18.0, 0.0, 1.0),
    "clam": NutrientProfile(86, 12.0, 5.0, 2.0),
    "mussel": NutrientProfile(86, 12.0, 5.0, 2.0),
    "dried shrimp": NutrientProfile(253, 62.0, 1.0, 3.0),

    # Fermented & Pastes
    "prahok": NutrientProfile(110, 18.0, 2.0, 3.0),
    "fish paste": NutrientProfile(110, 18.0, 2.0, 3.0),
    "shrimp paste": NutrientProfile(100, 15.0, 2.0, 2.0),
    "kapi": NutrientProfile(100, 15.0, 2.0, 2.0),
    "kroeung": NutrientProfile(90, 2.5, 18.0, 1.5),

    # Eggs & Tofu
    "egg": NutrientProfile(143, 12.6, 0.7, 9.5),
    "eggs": NutrientProfile(143, 12.6, 0.7, 9.5),
    "fried egg": NutrientProfile(196, 13.6, 0.8, 15.0),
    "egg yolk": NutrientProfile(322, 15.9, 3.6, 26.5),
    "egg white": NutrientProfile(52, 10.9, 0.7, 0.2),
    "tofu": NutrientProfile(76, 8.0, 1.9, 4.8),

    # Rice, Noodles & Starches
    "rice": NutrientProfile(365, 7.1, 80.0, 0.7),
    "broken rice": NutrientProfile(365, 7.1, 80.0, 0.7),
    "jasmine rice": NutrientProfile(365, 7.1, 80.0, 0.7),
    "sticky rice": NutrientProfile(370, 6.8, 82.0, 0.6),
    "glutinous rice": NutrientProfile(370, 6.8, 82.0, 0.6),
    "cooked rice": NutrientProfile(130, 2.7, 28.0, 0.3),
    "rice noodle": NutrientProfile(364, 3.4, 83.0, 0.6),
    "rice noodles": NutrientProfile(364, 3.4, 83.0, 0.6),
    "nom banh chok": NutrientProfile(120, 2.0, 26.0, 0.3),
    "kuy teav": NutrientProfile(364, 3.4, 83.0, 0.6),
    "egg noodle": NutrientProfile(384, 14.0, 71.0, 4.4),
    "egg noodles": NutrientProfile(384, 14.0, 71.0, 4.4),
    "glass noodle": NutrientProfile(351, 0.2, 86.0, 0.1),
    "glass noodles": NutrientProfile(351, 0.2, 86.0, 0.1),
    "vermicelli": NutrientProfile(360, 3.0, 82.0, 0.5),
    "tapioca": NutrientProfile(358, 0.2, 88.0, 0.1),
    "flour": NutrientProfile(364, 10.0, 76.0, 1.0),
    "cornstarch": NutrientProfile(381, 0.3, 91.0, 0.1),
    "baguette": NutrientProfile(265, 9.0, 49.0, 3.2),
    "bread": NutrientProfile(265, 9.0, 49.0, 3.2),

    # Coconut & Liquids
    "coconut milk": NutrientProfile(230, 2.3, 5.5, 24.0),
    "coconut cream": NutrientProfile(330, 3.5, 6.6, 34.7),
    "coconut water": NutrientProfile(19, 0.7, 3.7, 0.2),
    "grated coconut": NutrientProfile(354, 3.3, 15.0, 33.5),
    "shredded coconut": NutrientProfile(354, 3.3, 15.0, 33.5),
    "water": NutrientProfile(0, 0.0, 0.0, 0.0),
    "stock": NutrientProfile(15, 2.0, 1.0, 0.5),
    "broth": NutrientProfile(15, 2.0, 1.0, 0.5),
    "bone broth": NutrientProfile(20, 3.0, 0.5, 0.8),

    # Oils & Fats
    "oil": NutrientProfile(884, 0.0, 0.0, 100.0),
    "cooking oil": NutrientProfile(884, 0.0, 0.0, 100.0),
    "vegetable oil": NutrientProfile(884, 0.0, 0.0, 100.0),
    "sesame oil": NutrientProfile(884, 0.0, 0.0, 100.0),
    "lard": NutrientProfile(902, 0.0, 0.0, 100.0),
    "pork fat": NutrientProfile(850, 2.0, 0.0, 95.0),
    "butter": NutrientProfile(717, 0.9, 0.1, 81.0),

    # Sugars & Sweeteners
    "palm sugar": NutrientProfile(383, 0.5, 95.0, 0.2),
    "sugar": NutrientProfile(387, 0.0, 100.0, 0.0),
    "white sugar": NutrientProfile(387, 0.0, 100.0, 0.0),
    "brown sugar": NutrientProfile(380, 0.1, 98.0, 0.0),
    "honey": NutrientProfile(304, 0.3, 82.0, 0.0),

    # Sauces & Seasonings
    "fish sauce": NutrientProfile(57, 10.0, 4.0, 0.0),
    "soy sauce": NutrientProfile(60, 8.0, 5.0, 0.0),
    "thick soy sauce": NutrientProfile(150, 4.0, 33.0, 0.0),
    "dark soy sauce": NutrientProfile(150, 4.0, 33.0, 0.0),
    "sweet soy sauce": NutrientProfile(180, 3.0, 42.0, 0.0),
    "oyster sauce": NutrientProfile(120, 3.0, 26.0, 0.5),
    "vinegar": NutrientProfile(18, 0.1, 4.0, 0.0),
    "rice vinegar": NutrientProfile(18, 0.1, 4.0, 0.0),
    "lime juice": NutrientProfile(25, 0.4, 8.0, 0.1),
    "lemon juice": NutrientProfile(25, 0.4, 8.0, 0.1),
    "tamarind": NutrientProfile(115, 1.5, 27.0, 0.3),
    "salt": NutrientProfile(0, 0.0, 0.0, 0.0),
    "black pepper": NutrientProfile(250, 10.0, 64.0, 3.0),
    "white pepper": NutrientProfile(250, 10.0, 64.0, 3.0),
    "pepper": NutrientProfile(250, 10.0, 64.0, 3.0),
    "kampot pepper": NutrientProfile(250, 10.0, 64.0, 3.0),
    "msg": NutrientProfile(0, 0.0, 0.0, 0.0),

    # Aromatics & Herbs
    "garlic": NutrientProfile(149, 6.4, 33.0, 0.5),
    "shallot": NutrientProfile(72, 2.5, 17.0, 0.1),
    "shallots": NutrientProfile(72, 2.5, 17.0, 0.1),
    "onion": NutrientProfile(40, 1.1, 9.3, 0.1),
    "ginger": NutrientProfile(80, 1.8, 18.0, 0.8),
    "galangal": NutrientProfile(80, 1.8, 18.0, 0.8),
    "lemongrass": NutrientProfile(99, 1.8, 25.0, 0.5),
    "chili": NutrientProfile(40, 1.9, 9.0, 0.4),
    "chilies": NutrientProfile(40, 1.9, 9.0, 0.4),
    "chilli": NutrientProfile(40, 1.9, 9.0, 0.4),
    "chillis": NutrientProfile(40, 1.9, 9.0, 0.4),
    "kaffir lime leaf": NutrientProfile(25, 1.0, 5.0, 0.2),
    "kaffir lime leaves": NutrientProfile(25, 1.0, 5.0, 0.2),
    "lime leaves": NutrientProfile(25, 1.0, 5.0, 0.2),
    "basil": NutrientProfile(23, 3.1, 2.7, 0.6),
    "holy basil": NutrientProfile(23, 3.1, 2.7, 0.6),
    "cilantro": NutrientProfile(23, 2.1, 3.7, 0.5),
    "coriander": NutrientProfile(23, 2.1, 3.7, 0.5),
    "scallion": NutrientProfile(32, 1.8, 7.3, 0.2),
    "scallions": NutrientProfile(32, 1.8, 7.3, 0.2),
    "spring onion": NutrientProfile(32, 1.8, 7.3, 0.2),
    "mint": NutrientProfile(44, 3.3, 8.4, 0.7),
    "herb": NutrientProfile(25, 2.0, 4.0, 0.5),
    "herbs": NutrientProfile(25, 2.0, 4.0, 0.5),
    "turmeric": NutrientProfile(120, 3.0, 25.0, 1.0),

    # Vegetables & Fruits
    "morning glory": NutrientProfile(19, 2.6, 3.1, 0.2),
    "water spinach": NutrientProfile(19, 2.6, 3.1, 0.2),
    "green beans": NutrientProfile(47, 2.8, 8.4, 0.4),
    "long beans": NutrientProfile(47, 2.8, 8.4, 0.4),
    "yardlong beans": NutrientProfile(47, 2.8, 8.4, 0.4),
    "cucumber": NutrientProfile(15, 0.7, 3.6, 0.1),
    "tomato": NutrientProfile(18, 0.9, 3.9, 0.2),
    "carrot": NutrientProfile(41, 0.9, 9.6, 0.2),
    "daikon": NutrientProfile(18, 0.6, 4.1, 0.1),
    "white radish": NutrientProfile(18, 0.6, 4.1, 0.1),
    "radish": NutrientProfile(18, 0.6, 4.1, 0.1),
    "cabbage": NutrientProfile(25, 1.3, 5.8, 0.1),
    "eggplant": NutrientProfile(25, 1.0, 6.0, 0.2),
    "pea eggplant": NutrientProfile(30, 1.2, 7.0, 0.3),
    "papaya": NutrientProfile(43, 0.5, 11.0, 0.3),
    "green papaya": NutrientProfile(35, 0.6, 8.0, 0.2),
    "mango": NutrientProfile(60, 0.8, 15.0, 0.4),
    "green mango": NutrientProfile(50, 0.7, 12.0, 0.3),
    "durian": NutrientProfile(147, 1.5, 27.0, 5.3),
    "bamboo shoot": NutrientProfile(27, 2.6, 5.2, 0.3),
    "bamboo shoots": NutrientProfile(27, 2.6, 5.2, 0.3),
    "bean sprouts": NutrientProfile(30, 3.0, 6.0, 0.2),
    "mushroom": NutrientProfile(28, 3.1, 3.3, 0.3),
    "mushrooms": NutrientProfile(28, 3.1, 3.3, 0.3),
    "wood ear": NutrientProfile(25, 1.0, 6.0, 0.2),
    "straw mushroom": NutrientProfile(25, 2.5, 4.0, 0.3),

    # Nuts & Seeds
    "peanut": NutrientProfile(585, 24.0, 21.0, 50.0),
    "peanuts": NutrientProfile(585, 24.0, 21.0, 50.0),
    "roasted peanuts": NutrientProfile(585, 24.0, 21.0, 50.0),
    "cashew": NutrientProfile(553, 18.0, 30.0, 44.0),
    "sesame": NutrientProfile(573, 18.0, 23.0, 50.0),
    "sesame seeds": NutrientProfile(573, 18.0, 23.0, 50.0),
}

# Non-edible tools/vessels mentioned in ingredient lists (0 weight / 0 calories)
NON_EDIBLE_ITEMS = {
    "skewer", "skewers", "bamboo skewer", "bamboo skewers",
    "bamboo tube", "bamboo tubes", "toothpick", "toothpicks",
    "banana leaf", "banana leaves", "parchment paper", "twine"
}


def is_non_edible(name: str) -> bool:
    cleaned = name.lower().strip()
    return any(item in cleaned for item in NON_EDIBLE_ITEMS)


def estimate_ingredient_weight_grams(name: str, quantity: float | None, unit: str | None) -> float:
    """Convert a recipe ingredient amount and unit into estimated grams."""
    name_lower = name.lower()

    if is_non_edible(name):
        return 0.0

    qty = float(quantity) if quantity is not None and quantity > 0 else 1.0
    u = (unit or "").lower().strip().rstrip(".")

    # Direct mass
    if u in ("g", "gram", "grams"):
        return qty
    if u in ("kg", "kilogram", "kilograms"):
        return qty * 1000.0
    if u in ("mg", "milligram", "milligrams"):
        return qty / 1000.0

    # Volume (assume ~1g/ml density for sauces/water/broth)
    if u in ("ml", "milliliter", "milliliters"):
        return qty
    if u in ("l", "liter", "liters", "litre", "litres"):
        return qty * 1000.0
    if u in ("tbsp", "tablespoon", "tablespoons"):
        return qty * 15.0
    if u in ("tsp", "teaspoon", "teaspoons"):
        return qty * 5.0
    if u in ("cup", "cups"):
        if "rice" in name_lower or "flour" in name_lower:
            return qty * 185.0
        if "coconut milk" in name_lower or "water" in name_lower or "stock" in name_lower:
            return qty * 240.0
        return qty * 200.0

    # Piece / discrete counts
    if u in ("clove", "cloves"):
        return qty * 3.5
    if u in ("stalk", "stalks"):
        return qty * 15.0
    if u in ("thumb", "thumbs"):
        return qty * 15.0
    if u in ("leaf", "leaves"):
        return qty * 1.0
    if u in ("slice", "slices"):
        return qty * 12.0
    if u in ("pinch", "pinches"):
        return qty * 1.0
    if u in ("bunch", "bunches"):
        return qty * 40.0
    if u in ("handful", "handfuls"):
        return qty * 25.0
    if u in ("can", "cans"):
        return qty * 400.0
    if u in ("bowl", "bowls"):
        return qty * 250.0

    # Piece / each
    if u in ("piece", "pieces", "", "each", "whole"):
        if "egg" in name_lower:
            return qty * 50.0
        if "chicken" in name_lower and ("thigh" in name_lower or "breast" in name_lower):
            return qty * 150.0
        if "squid" in name_lower:
            return qty * 150.0
        if "fish" in name_lower:
            return qty * 200.0
        if "carrot" in name_lower or "daikon" in name_lower:
            return qty * 100.0
        if "cucumber" in name_lower:
            return qty * 100.0
        if "tomato" in name_lower:
            return qty * 80.0
        if "shallot" in name_lower or "onion" in name_lower:
            return qty * 30.0
        if "chili" in name_lower:
            return qty * 5.0
        if "lime" in name_lower or "lemon" in name_lower:
            return qty * 30.0
        return qty * 50.0

    # Default fallback
    return qty * 30.0


def find_closest_nutrient_profile(name: str) -> NutrientProfile:
    """Find the best matching macro profile from the culinary database."""
    name_clean = name.lower()

    # Direct match
    if name_clean in NUTRITION_DATABASE:
        return NUTRITION_DATABASE[name_clean]

    # Keyword match with priority to longer specific matches
    matches = []
    for key, profile in NUTRITION_DATABASE.items():
        if key in name_clean:
            matches.append((len(key), profile))

    if matches:
        matches.sort(key=lambda x: x[0], reverse=True)
        return matches[0][1]

    # Broad category heuristics
    if any(m in name_clean for m in ("pork", "pig", "ham", "bacon")):
        return NUTRITION_DATABASE["pork"]
    if any(m in name_clean for m in ("chicken", "poultry", "fowl")):
        return NUTRITION_DATABASE["chicken"]
    if any(m in name_clean for m in ("beef", "cow", "steak", "veal")):
        return NUTRITION_DATABASE["beef"]
    if any(m in name_clean for m in ("fish", "salmon", "trout", "carp", "tilapia")):
        return NUTRITION_DATABASE["fish"]
    if any(m in name_clean for m in ("seafood", "prawn", "shrimp", "squid", "calamari")):
        return NUTRITION_DATABASE["prawn"]
    if any(m in name_clean for m in ("rice", "grain")):
        return NUTRITION_DATABASE["rice"]
    if any(m in name_clean for m in ("noodle", "noodles", "pasta")):
        return NUTRITION_DATABASE["rice noodle"]
    if any(m in name_clean for m in ("sugar", "sweetener", "syrup")):
        return NUTRITION_DATABASE["sugar"]
    if any(m in name_clean for m in ("oil", "fat", "grease")):
        return NUTRITION_DATABASE["oil"]
    if any(m in name_clean for m in ("sauce", "paste", "dip")):
        return NUTRITION_DATABASE["fish sauce"]

    # Conservative vegetable / aromatic default
    return NutrientProfile(30, 1.5, 5.0, 0.3)


def estimate_recipe_nutrition(recipe: dict[str, Any]) -> dict[str, float]:
    """
    Calculate and populate recipe nutritional values per serving:
    - calories (kcal)
    - proteinGrams (g)
    - carbohydrateGrams (g)
    - fatGrams (g)
    - nutritionBasis = "PER_SERVING"
    """
    ingredients = recipe.get("ingredients") or []
    servings = recipe.get("servings")
    if not servings or not isinstance(servings, (int, float)) or servings <= 0:
        servings = 4

    total_cal = 0.0
    total_pro = 0.0
    total_carb = 0.0
    total_fat = 0.0

    for item in ingredients:
        name = item.get("ingredientName") or item.get("name") or item.get("originalIngredientText") or ""
        if not name or is_non_edible(name):
            continue

        weight_g = estimate_ingredient_weight_grams(name, item.get("quantity"), item.get("unit"))
        if weight_g <= 0:
            continue

        profile = find_closest_nutrient_profile(name)
        factor = weight_g / 100.0

        total_cal += profile.calories * factor
        total_pro += profile.protein * factor
        total_carb += profile.carbs * factor
        total_fat += profile.fat * factor

    # Sanity minimums if recipe had edible ingredients
    if ingredients and total_cal < 50:
        total_cal = 200.0 * servings
        total_pro = 15.0 * servings
        total_carb = 20.0 * servings
        total_fat = 5.0 * servings

    cal_per_serving = round(total_cal / servings)
    pro_per_serving = round(total_pro / servings, 1)
    carb_per_serving = round(total_carb / servings, 1)
    fat_per_serving = round(total_fat / servings, 1)

    recipe["calories"] = float(cal_per_serving)
    recipe["proteinGrams"] = pro_per_serving
    recipe["carbohydrateGrams"] = carb_per_serving
    recipe["fatGrams"] = fat_per_serving
    recipe["nutritionBasis"] = "PER_SERVING"

    recipe["nutrition"] = {
        "calories": float(cal_per_serving),
        "proteinGrams": pro_per_serving,
        "carbsGrams": carb_per_serving,
        "fatGrams": fat_per_serving,
    }

    return {
        "calories": float(cal_per_serving),
        "proteinGrams": pro_per_serving,
        "carbohydrateGrams": carb_per_serving,
        "fatGrams": fat_per_serving,
    }

