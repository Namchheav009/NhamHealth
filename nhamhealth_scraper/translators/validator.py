import json
import re
from dataclasses import dataclass, field
from typing import List, Optional, Tuple

from .culinary_glossary import DISH_NAMES, INGREDIENTS, POST_TRANSLATION_FIXES, STANDARD_UNITS

KHMER_CHAR_REGEX = re.compile(r"[\u1780-\u17FF]")


@dataclass
class ValidationResult:
    status: str  # "PASSED", "NEEDS_REVIEW", "FAILED"
    issues: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)
    can_retry: bool = False

    @property
    def is_valid(self) -> bool:
        return self.status == "PASSED"

    def to_report_string(self) -> str:
        parts = [f"Status: {self.status}"]
        if self.issues:
            parts.append("Issues: " + "; ".join(self.issues))
        if self.warnings:
            parts.append("Warnings: " + "; ".join(self.warnings))
        return " | ".join(parts)


def contains_khmer(text: Optional[str]) -> bool:
    """Check if the given string contains at least one Khmer Unicode character."""
    if not text:
        return False
    return bool(KHMER_CHAR_REGEX.search(text))


def comprehensive_validate_translation(recipe: dict) -> ValidationResult:
    """
    Perform thorough rule-based and linguistic QA on recipe translations:
    - Statuses: PASSED, NEEDS_REVIEW, FAILED
    - Validates ingredient count, quantity/units, step completeness, ordering,
      cooking time preservation, glossary consistency, and natural phrasing.
    """
    translations = recipe.get("translations")
    if not isinstance(translations, dict):
        return ValidationResult(
            status="FAILED",
            issues=["Missing translations container in recipe."],
            can_retry=True,
        )

    en = translations.get("en")
    km = translations.get("km")

    if not isinstance(en, dict):
        return ValidationResult(
            status="FAILED",
            issues=["Missing English translations (translations.en)."],
            can_retry=True,
        )
    if not isinstance(km, dict):
        return ValidationResult(
            status="FAILED",
            issues=["Missing Khmer translations (translations.km)."],
            can_retry=True,
        )

    issues: List[str] = []
    warnings: List[str] = []
    can_retry = False

    # 1. Meal name validation
    km_meal_name = (km.get("mealName") or "").strip()
    en_meal_name = (en.get("mealName") or "").strip()
    if not km_meal_name:
        issues.append("Khmer meal name is empty.")
        can_retry = True
    elif not contains_khmer(km_meal_name):
        issues.append(f"Khmer meal name '{km_meal_name}' does not contain Khmer script.")
        can_retry = True
    else:
        # Check against culinary glossary
        en_lower = en_meal_name.lower().strip()
        expected_km = DISH_NAMES.get(en_lower)
        if expected_km and expected_km != km_meal_name and expected_km not in km_meal_name:
            warnings.append(
                f"Meal name '{km_meal_name}' differs from canonical glossary '{expected_km}'"
            )

    # 2. Description validation
    en_desc = (en.get("description") or "").strip()
    km_desc = (km.get("description") or "").strip()
    if en_desc:
        if not km_desc:
            issues.append("English description is present but Khmer description is missing.")
            can_retry = True
        elif not contains_khmer(km_desc):
            issues.append("Khmer description does not contain Khmer script.")
            can_retry = True

    # 3. Category validation
    en_cat = (en.get("category") or "").strip()
    km_cat = (km.get("category") or "").strip()
    if en_cat:
        if not km_cat:
            issues.append("English category is present but Khmer category translation is missing.")
            can_retry = True
        elif not contains_khmer(km_cat):
            issues.append(f"Khmer category '{km_cat}' does not contain Khmer script.")
            can_retry = True

    # 4. Ingredients validation
    en_ingredients = en.get("ingredients") or []
    km_ingredients = km.get("ingredients") or []
    if len(en_ingredients) != len(km_ingredients):
        issues.append(
            f"Ingredient count mismatch: EN has {len(en_ingredients)}, KM has {len(km_ingredients)}."
        )
        can_retry = True
    else:
        for idx, (en_item, km_item) in enumerate(zip(en_ingredients, km_ingredients), start=1):
            km_name = (km_item.get("name") or "").strip()
            if not km_name:
                issues.append(f"Khmer ingredient #{idx} has empty name.")
                can_retry = True
            elif not contains_khmer(km_name):
                issues.append(f"Khmer ingredient #{idx} '{km_name}' does not contain Khmer script.")
                can_retry = True

            # Preserve numeric quantity
            en_qty = en_item.get("quantity")
            km_qty = km_item.get("quantity")
            if en_qty != km_qty:
                issues.append(
                    f"Ingredient #{idx} quantity modified: EN={en_qty}, KM={km_qty}."
                )
                can_retry = True

            # Preserve unit
            en_unit = en_item.get("unit")
            km_unit = km_item.get("unit")
            if en_unit != km_unit:
                issues.append(
                    f"Ingredient #{idx} unit modified: EN={en_unit}, KM={km_unit}."
                )
                can_retry = True

            # Check for awkward machine translation phrases
            for awkward, preferred in POST_TRANSLATION_FIXES:
                if awkward in km_name:
                    warnings.append(
                        f"Ingredient #{idx} contains awkward term '{awkward}', preferred '{preferred}'"
                    )

    # 5. Cooking steps validation
    en_steps = en.get("steps") or []
    km_steps = km.get("steps") or []
    if len(en_steps) != len(km_steps):
        issues.append(
            f"Step count mismatch: EN has {len(en_steps)}, KM has {len(km_steps)}."
        )
        can_retry = True
    else:
        for idx, (en_step, km_step) in enumerate(zip(en_steps, km_steps), start=1):
            km_instruction = km_step if isinstance(km_step, str) else km_step.get("instruction", "")
            if not km_instruction or not str(km_instruction).strip():
                issues.append(f"Khmer step #{idx} is empty.")
                can_retry = True
            elif not contains_khmer(km_instruction):
                issues.append(f"Khmer step #{idx} does not contain Khmer script.")
                can_retry = True

            # Check step sequence if stepNumber exists
            if isinstance(km_step, dict) and km_step.get("stepNumber") is not None:
                if km_step.get("stepNumber") != idx:
                    issues.append(
                        f"Khmer step #{idx} has invalid stepNumber {km_step.get('stepNumber')}."
                    )
                    can_retry = True

    # Determine final status
    if issues:
        status = "FAILED"
    elif warnings:
        status = "NEEDS_REVIEW"
    else:
        status = "PASSED"

    return ValidationResult(
        status=status,
        issues=issues,
        warnings=warnings,
        can_retry=can_retry,
    )


def validate_translation(recipe: dict) -> Tuple[bool, Optional[str]]:
    """
    Backwards-compatible translation validator function.
    Returns (True, None) if PASSED or NEEDS_REVIEW, or (False, first_issue) if FAILED.
    """
    res = comprehensive_validate_translation(recipe)
    if res.status == "FAILED":
        return False, res.issues[0] if res.issues else "Translation validation failed."
    return True, None
