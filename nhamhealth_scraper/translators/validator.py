import re

KHMER_CHAR_REGEX = re.compile(r"[\u1780-\u17FF]")


def contains_khmer(text: str | None) -> bool:
    """Check if the given string contains at least one Khmer Unicode character."""
    if not text:
        return False
    return bool(KHMER_CHAR_REGEX.search(text))


def validate_translation(recipe: dict) -> tuple[bool, str | None]:
    """
    Validate that the translated recipe meets NhamHealth Khmer translation quality standards:
    - Validates presence and Khmer script in mealName, description, steps, and ingredients.
    - Ensures numeric quantities and standard units were preserved without corruption.
    - Checks that ingredient and step lengths match the English source.
    """
    translations = recipe.get("translations")
    if not isinstance(translations, dict):
        return False, "Missing translations container in recipe."

    en = translations.get("en")
    km = translations.get("km")

    if not isinstance(en, dict):
        return False, "Missing English translations (translations.en)."
    if not isinstance(km, dict):
        return False, "Missing Khmer translations (translations.km)."

    # 1. Meal name validation
    km_meal_name = km.get("mealName") or ""
    if not km_meal_name.strip():
        return False, "Khmer meal name is empty."
    if not contains_khmer(km_meal_name):
        return False, f"Khmer meal name '{km_meal_name}' does not contain Khmer script."

    # 2. Description validation (if English has description)
    en_desc = (en.get("description") or "").strip()
    km_desc = (km.get("description") or "").strip()
    if en_desc and not km_desc:
        return False, "English description is present but Khmer description is missing."
    if km_desc and not contains_khmer(km_desc):
        return False, "Khmer description does not contain Khmer script."

    # 3. Ingredients validation
    # 3. Category validation (if English has category)
    en_cat = (en.get("category") or "").strip()
    km_cat = (km.get("category") or "").strip()
    if en_cat and not km_cat:
        return False, "English category is present but Khmer category translation is missing."
    if km_cat and not contains_khmer(km_cat):
        return False, f"Khmer category '{km_cat}' does not contain Khmer script."

    # 4. Ingredients validation
    en_ingredients = en.get("ingredients") or []
    km_ingredients = km.get("ingredients") or []
    if len(en_ingredients) != len(km_ingredients):
        return False, f"Ingredient count mismatch: EN has {len(en_ingredients)}, KM has {len(km_ingredients)}."

    for idx, (en_item, km_item) in enumerate(zip(en_ingredients, km_ingredients), start=1):
        # Name
        km_name = (km_item.get("name") or "").strip()
        if not km_name:
            return False, f"Khmer ingredient #{idx} has empty name."
        if not contains_khmer(km_name):
            return False, f"Khmer ingredient #{idx} '{km_name}' does not contain Khmer script."

        # Numeric quantity preservation
        if en_item.get("quantity") != km_item.get("quantity"):
            return False, (
                f"Ingredient #{idx} quantity modified: "
                f"EN={en_item.get('quantity')}, KM={km_item.get('quantity')}."
            )

        # Unit preservation
        if en_item.get("unit") != km_item.get("unit"):
            return False, (
                f"Ingredient #{idx} unit modified: "
                f"EN={en_item.get('unit')}, KM={km_item.get('unit')}."
            )

        # Note check
        if en_item.get("note") and not km_item.get("note"):
            # If EN had note, KM should ideally have note (warning or soft check)
            pass

    # 4. Steps validation
    en_steps = en.get("steps") or []
    km_steps = km.get("steps") or []
    if len(en_steps) != len(km_steps):
        return False, f"Step count mismatch: EN has {len(en_steps)}, KM has {len(km_steps)}."

    for idx, (en_step, km_step) in enumerate(zip(en_steps, km_steps), start=1):
        km_instruction = km_step if isinstance(km_step, str) else km_step.get("instruction", "")
        if not km_instruction.strip():
            return False, f"Khmer step #{idx} is empty."
        if not contains_khmer(km_instruction):
            return False, f"Khmer step #{idx} does not contain Khmer script."

    return True, None

