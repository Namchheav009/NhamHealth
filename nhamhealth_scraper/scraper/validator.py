import math
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse
from PIL import Image

from .nutrition_estimator import estimate_recipe_nutrition


def validate_recipe(recipe: dict, *, require_image: bool = True) -> tuple[list[str], list[str]]:
    """Returns (errors, warnings) using limits Codex found in your backend."""
    errors = []
    warnings = []

    if not isinstance(recipe, dict):
        return ["Recipe must be an object."], []
    for field, limit, required in (("mealName", 150, True), ("khmerName", 150, False),
            ("description", 500, False), ("categoryName", 100, True),
            ("sourceLanguage", 10, True), ("sourceName", 150, True),
            ("sourceUrl", 1000, True), ("sourceImageUrl", 2000, False)):
        value = recipe.get(field)
        if value is None and not required:
            continue
        if not isinstance(value, str) or (required and not value.strip()) or len(value) > limit:
            errors.append(f"{field} must be {'non-empty ' if required else ''}text up to {limit} characters.")
    if errors:
        return errors, warnings
    try:
        url = urlparse(recipe["sourceUrl"])
        if url.scheme not in {"http", "https"} or not url.hostname or url.username:
            raise ValueError()
    except ValueError:
        errors.append("sourceUrl must be an absolute HTTP(S) URL.")
    try:
        if datetime.fromisoformat(recipe.get("scrapedAt") or "").tzinfo is None:
            raise ValueError()
    except (ValueError, TypeError):
        errors.append("scrapedAt must be an ISO timestamp with timezone.")
    for field in ("ingredients", "steps"):
        values = recipe.get(field)
        if not isinstance(values, list) or len(values) > 200 or not all(isinstance(v, dict) for v in values):
            errors.append(f"{field} must be a list of at most 200 objects.")
            return errors, warnings

    meal_name = recipe.get("mealName") or ""
    if not meal_name:
        errors.append("Meal name is required.")
    elif len(meal_name) > 150:
        errors.append("Meal name is longer than 150 characters.")

    description = recipe.get("description")
    if description and len(description) > 500:
        errors.append("Description is longer than 500 characters.")

    servings = recipe.get("servings")
    if isinstance(servings, bool) or not isinstance(servings, int) or not (1 <= servings <= 100):
        errors.append("Servings must be between 1 and 100.")

    cooking_time = recipe.get("cookingTimeMinutes")
    if cooking_time is not None and (isinstance(cooking_time, bool) or not isinstance(cooking_time, int)
                                     or not 0 <= cooking_time <= 1440):
        errors.append("Cooking time must be an integer from 0 to 1440 minutes.")
    if recipe.get("difficulty") not in {None, "EASY", "MEDIUM", "HARD", "NOT_SPECIFIED"}:
        errors.append("Difficulty must be EASY, MEDIUM, HARD or NOT_SPECIFIED.")
    if recipe.get("nutritionBasis") not in {"UNKNOWN", "PER_SERVING", "PER_100G", "WHOLE_RECIPE"}:
        errors.append("Unknown nutrition basis.")
    for field in ("calories", "proteinGrams", "carbohydrateGrams", "fatGrams"):
        value = recipe.get(field)
        if value is not None and (isinstance(value, bool) or not isinstance(value, (int, float))
                                  or not math.isfinite(value) or value < 0):
            errors.append(f"{field} must be a non-negative number or null.")

    ingredients = recipe.get("ingredients") or []
    if not ingredients:
        errors.append("At least one ingredient is required.")

    for index, ingredient in enumerate(ingredients, start=1):
        if not isinstance(ingredient.get("ingredientName"), str) or not ingredient["ingredientName"].strip():
            errors.append(f"Ingredient {index} has no name.")
        if ingredient.get("needsReview"):
            warnings.append(
                f"Ingredient {index} needs review: "
                f"{ingredient.get('originalIngredientText')}"
            )
        quantity = ingredient.get("quantity")
        if quantity is not None and (isinstance(quantity, bool) or not isinstance(quantity, (int, float))
                                     or not math.isfinite(quantity) or not 0 <= quantity <= 99999999.99
                                     or round(quantity, 2) != quantity):
            errors.append(f"Ingredient {index} quantity must be non-negative with at most 2 decimal places.")
        for field, limit in (("ingredientName", 100), ("unit", 30), ("preparationNote", 150), ("originalIngredientText", 2000)):
            value = ingredient.get(field)
            if value is not None and (not isinstance(value, str) or len(value) > limit):
                errors.append(f"Ingredient {index} {field} must be text up to {limit} characters.")
        if ingredient.get("displayOrder") != index:
            errors.append(f"Ingredient {index} displayOrder must be {index}.")

    if not recipe.get("steps"):
        errors.append("At least one cooking step is required.")
    for index, step in enumerate(recipe.get("steps") or [], 1):
        instruction = step.get("instruction") or ""
        if not isinstance(instruction, str):
            errors.append(f"Step {index} instruction must be text.")
            continue
        if not instruction.strip():
            errors.append(f"Step {index} instruction is required.")
        if step.get("stepNumber") != index:
            errors.append(f"Step {index} stepNumber must be {index}.")
        if len(instruction) > 255:
            errors.append(
                f"Step {step.get('stepNumber')} is longer than 255 characters."
            )

    if (recipe.get("calories") is None or recipe.get("proteinGrams") is None) and recipe.get("ingredients"):
        estimate_recipe_nutrition(recipe)

    if recipe.get("calories") is None:
        errors.append("calories is required and must be provided.")
    if recipe.get("proteinGrams") is None:
        errors.append("proteinGrams is required and must be provided.")

    if not recipe.get("categoryName"):
        errors.append(
            "Category could not be mapped automatically. Select it during review."
        )

    if recipe.get("imageDownloadError"):
        warnings.append("imageDownloadError: " + str(recipe["imageDownloadError"]))
    try:
        path = recipe.get("localImagePath")
        if not path or not Path(path).is_file():
            raise ValueError("A real local meal photo is required; use --image-file." if require_image
                             else "Draft has no photo; add one in Admin before publishing.")
        if Path(path).stat().st_size > 5 * 1024 * 1024:
            raise ValueError("Meal photo must be 5 MB or smaller.")
        with Image.open(path) as photo:
            if photo.format != "WEBP":
                raise ValueError("Prepare the photo as WebP using --image-file.")
            if photo.width * photo.height > 25_000_000:
                raise ValueError("Meal photo dimensions are too large.")
            photo.verify()
    except (OSError, ValueError, TypeError) as exc:
        (errors if require_image or recipe.get("localImagePath") else warnings).append(str(exc))

    return errors, warnings
