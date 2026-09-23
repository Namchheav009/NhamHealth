import re
from datetime import datetime, timezone

from .nutrition_estimator import estimate_recipe_nutrition
from .ingredient_image_resolver import canonical_ingredient_name
from .ingredient_normalization_service import normalize_ingredient


MAX_STEP_LENGTH = 255


def split_instruction(value: str, limit: int = MAX_STEP_LENGTH) -> list[str]:
    """Split long instructions at sentence or word boundaries for the API."""
    text = " ".join((value or "").split())
    if not text:
        return [""]
    if len(text) <= limit:
        return [text]

    sentences = re.split(r"(?<=[.!?])\s+", text)
    chunks: list[str] = []
    current = ""
    for sentence in sentences:
        remaining = sentence.strip()
        while len(remaining) > limit:
            split_at = remaining.rfind(" ", 0, limit + 1)
            if split_at <= 0:
                split_at = limit
            piece = remaining[:split_at].strip()
            if current:
                chunks.append(current)
                current = ""
            chunks.append(piece)
            remaining = remaining[split_at:].strip()

        candidate = f"{current} {remaining}".strip() if current else remaining
        if current and len(candidate) > limit:
            chunks.append(current)
            current = remaining
        else:
            current = candidate

    if current:
        chunks.append(current)
    return chunks


def normalize_recipe(recipe: dict) -> dict:
    """Convert scraped fields into the exact NhamHealth import shape."""

    normalized_ingredients = []

    for index, item in enumerate(recipe.get("ingredients") or [], start=1):
        identity = normalize_ingredient(item.get("ingredientName") or "")
        normalized_ingredients.append(
            {
                "ingredientName": identity.canonicalName,
                "quantity": item.get("quantity"),
                "unit": item.get("unit"),
                "preparationNote": item.get("preparationNote") or identity.preparationNote,
                "originalIngredientText": item.get("originalIngredientText"),
                "displayOrder": item.get("displayOrder") or index,
                "needsReview": bool(item.get("needsReview")) or identity.needsReview,
                "searchAliases": identity.searchAliases,
                "ingredientType": identity.ingredientType,
            }
        )

    normalized_steps = []

    for step in recipe.get("steps") or []:
        for instruction in split_instruction(step.get("instruction") or ""):
            normalized_steps.append(
                {
                    "stepNumber": len(normalized_steps) + 1,
                    # Your current Add Meal screen needs instruction only.
                    "instruction": instruction,
                    "originalStepTitle": step.get("originalStepTitle"),
                }
            )

    if recipe.get("calories") is None or recipe.get("proteinGrams") is None:
        estimate_recipe_nutrition(recipe)

    normalized = {
        "mealName": " ".join((recipe.get("mealName") or "").split()),
        "khmerName": recipe.get("khmerName"),
        "description": (
            " ".join((recipe.get("description") or "").split())
            if recipe.get("description")
            else None
        ),
        "categoryName": recipe.get("categoryName"),
        "sourceCategory": recipe.get("sourceCategory"),
        "calories": recipe.get("calories"),
        "proteinGrams": recipe.get("proteinGrams"),
        "carbohydrateGrams": recipe.get("carbohydrateGrams"),
        "fatGrams": recipe.get("fatGrams"),
        "nutritionBasis": recipe.get("nutritionBasis") or "PER_SERVING",
        "servings": recipe.get("servings"),
        "cookingTimeMinutes": recipe.get("cookingTimeMinutes"),
        "prepTimeMinutes": recipe.get("prepTimeMinutes"),
        "difficulty": recipe.get("difficulty") or "NOT_SPECIFIED",
        "sourceImageUrl": recipe.get("sourceImageUrl"),
        "imageUrl": recipe.get("sourceImageUrl") or recipe.get("localImagePath"),
        "localImagePath": recipe.get("localImagePath"),
        "imageDownloadError": recipe.get("imageDownloadError"),
        "nutrition": {
            "calories": recipe.get("calories"),
            "proteinGrams": recipe.get("proteinGrams"),
            "carbsGrams": recipe.get("carbohydrateGrams"),
            "fatGrams": recipe.get("fatGrams"),
        },
        "tags": list(recipe.get("tags") or []),
        "translations": recipe.get("translations") or {
            "en": {
                "mealName": " ".join((recipe.get("mealName") or "").split()),
                "description": (
                    " ".join((recipe.get("description") or "").split())
                    if recipe.get("description")
                    else None
                ),
                "category": recipe.get("categoryName") or recipe.get("sourceCategory") or "",
                "ingredients": [
                    {
                        "name": item.get("ingredientName"),
                        "quantity": item.get("quantity"),
                        "unit": item.get("unit"),
                        "note": item.get("preparationNote"),
                    }
                    for item in normalized_ingredients
                ],
                "steps": [
                    step.get("instruction")
                    for step in normalized_steps
                    if step.get("instruction")
                ],
                "tags": list(recipe.get("tags") or []),
            },
            "km": None,
        },
        "translationStatus": recipe.get("translationStatus") or "PENDING",
        "translationError": recipe.get("translationError"),
        "ingredients": normalized_ingredients,
        "steps": normalized_steps,
        "sourceLanguage": recipe.get("sourceLanguage") or "en",
        "sourceName": recipe.get("sourceName"),
        "sourceUrl": recipe.get("sourceUrl"),
        "scrapedAt": datetime.now(timezone.utc).isoformat(),
        "reviewStatus": "PENDING_REVIEW",
        # Important: imported meals should not be public before review.
        "published": False,
    }
    source_ingredients = recipe.get("ingredients") or []
    source_steps = recipe.get("steps") or []
    if (recipe.get("khmerName") and recipe.get("categoryNameKm")
            and (not recipe.get("description") or recipe.get("descriptionKm"))
            and len(source_ingredients) == len(normalized_ingredients)
            and len(source_steps) == len(normalized_steps)
            and all(item.get("ingredientNameKm") for item in source_ingredients)
            and all(step.get("instructionKm") for step in source_steps)):
        normalized["translations"]["km"] = {
            "mealName": recipe["khmerName"],
            "description": recipe.get("descriptionKm"),
            "category": recipe["categoryNameKm"],
            "ingredients": [
                {"name": item["ingredientNameKm"], "quantity": item.get("quantity"),
                 "unit": item.get("unit"), "note": item.get("preparationNoteKm")}
                for item in source_ingredients
            ],
            "steps": [step["instructionKm"] for step in source_steps],
        }
        normalized["categoryNameKm"] = recipe["categoryNameKm"]
        normalized["translationStatus"] = "COMPLETED"
    return normalized
