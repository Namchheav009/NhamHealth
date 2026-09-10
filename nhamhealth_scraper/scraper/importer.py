import json
from pathlib import Path

import requests

from .config import settings
from .validator import validate_recipe


_cached_import_token: str | None = None


def _response_error(response) -> str:
    try:
        error = response.json()
        return error.get("message") or error.get("detail") or str(error)
    except ValueError:
        return response.text[:1000]


def _get_import_token() -> str:
    """Return a configured token or log in once for this import process."""
    global _cached_import_token

    configured_token = getattr(settings, "spring_import_token", "").strip()
    if configured_token:
        return configured_token
    if _cached_import_token:
        return _cached_import_token

    email = getattr(settings, "spring_admin_email", "").strip()
    password = getattr(settings, "spring_admin_password", "")
    if not email or not password:
        raise ValueError(
            "Configure SPRING_ADMIN_EMAIL and SPRING_ADMIN_PASSWORD in .env "
            "(or provide SPRING_IMPORT_TOKEN) before importing."
        )

    login_url = getattr(
        settings,
        "spring_admin_login_url",
        "http://localhost:8080/api/admin/auth/login",
    )
    response = requests.post(
        login_url,
        json={"email": email, "password": password},
        timeout=getattr(settings, "request_timeout_seconds", 25),
    )
    if response.status_code == 202:
        raise RuntimeError(
            "Admin login requires a verification code. Complete the OTP login "
            "and put the returned accessToken in SPRING_IMPORT_TOKEN."
        )
    if not response.ok:
        raise RuntimeError(f"Admin login API {response.status_code}: {_response_error(response)}")

    try:
        body = response.json()
    except ValueError as exception:
        raise RuntimeError("Admin login returned an invalid JSON response.") from exception
    token = str(body.get("accessToken") or "").strip()
    role = str((body.get("user") or {}).get("role") or "").upper()
    if not token or role != "ADMIN":
        raise RuntimeError("Admin login did not return an ADMIN access token.")

    _cached_import_token = token
    return token


def _api_recipe_payload(recipe: dict) -> dict:
    """
    Strip scraper-only helper fields before sending to Spring Boot.
    Spring Boot resolves ingredient names to ingredient IDs.
    """
    km_trans = (recipe.get("translations") or {}).get("km") if isinstance(recipe.get("translations"), dict) else None
    khmer_name = recipe.get("khmerName") or (km_trans.get("mealName") if isinstance(km_trans, dict) else None)
    description_km = km_trans.get("description") if isinstance(km_trans, dict) else None
    category_km = (km_trans.get("category") if isinstance(km_trans, dict) else None) or recipe.get("categoryNameKm")
    km_ingredients = (km_trans.get("ingredients") or []) if isinstance(km_trans, dict) else []
    km_steps = (km_trans.get("steps") or []) if isinstance(km_trans, dict) else []

    payload_ingredients = []
    for idx, item in enumerate(recipe.get("ingredients") or []):
        km_item = km_ingredients[idx] if idx < len(km_ingredients) else {}
        payload_ingredients.append({
            "ingredientName": item.get("ingredientName"),
            "quantity": item.get("quantity"),
            "unit": item.get("unit"),
            "preparationNote": item.get("preparationNote"),
            "ingredientNameKm": km_item.get("name") or km_item.get("ingredientName"),
            "preparationNoteKm": km_item.get("note") or km_item.get("preparationNote"),
            "originalIngredientText": item.get("originalIngredientText"),
            "displayOrder": item.get("displayOrder"),
        })

    payload_steps = []
    for idx, step in enumerate(recipe.get("steps") or []):
        if not step.get("instruction"):
            continue
        km_step = km_steps[idx] if idx < len(km_steps) else None
        instruction_km = km_step if isinstance(km_step, str) else (km_step.get("instruction") if isinstance(km_step, dict) else None)
        payload_steps.append({
            "stepNumber": step.get("stepNumber"),
            "instruction": step.get("instruction"),
            "instructionKm": instruction_km,
        })

    return {
        "mealName": recipe.get("mealName"),
        "khmerName": khmer_name,
        "description": recipe.get("description"),
        "descriptionKm": description_km,
        "categoryName": recipe.get("categoryName"),
        "categoryNameKm": category_km,
        "calories": recipe.get("calories"),
        "proteinGrams": recipe.get("proteinGrams"),
        "carbohydrateGrams": recipe.get("carbohydrateGrams"),
        "fatGrams": recipe.get("fatGrams"),
        "nutritionBasis": recipe.get("nutritionBasis"),
        "servings": recipe.get("servings"),
        "cookingTimeMinutes": recipe.get("cookingTimeMinutes"),
        "difficulty": recipe.get("difficulty"),
        "ingredients": payload_ingredients,
        "steps": payload_steps,
        "sourceLanguage": recipe.get("sourceLanguage") or "en",
        "sourceName": recipe.get("sourceName"),
        "sourceUrl": recipe.get("sourceUrl"),
        "sourceImageUrl": recipe.get("sourceImageUrl"),
        "scrapedAt": recipe.get("scrapedAt"),
        "reviewStatus": "PENDING_REVIEW",
        "published": False,
    }


def import_recipe(recipe: dict) -> dict:
    errors, _ = validate_recipe(recipe, require_image=False)
    if errors:
        raise ValueError("Import validation failed: " + "; ".join(errors))
    if any(item.get("needsReview") for item in recipe.get("ingredients", [])):
        raise ValueError("Review flagged ingredients and set needsReview=false before importing saved JSON.")
    import_token = _get_import_token()
    image_path = recipe.get("localImagePath")

    files = {"recipe": (None, json.dumps(_api_recipe_payload(recipe), ensure_ascii=False), "application/json")}
    handles = []

    try:
        if image_path:
            path = Path(image_path)
            handle = path.open("rb")
            handles.append(handle)
            files["image"] = (
                path.name,
                handle,
                "image/webp",
            )

        headers = {"Authorization": f"Bearer {import_token}"}

        response = requests.post(
            settings.spring_import_url,
            files=files,
            headers=headers,
            timeout=60,
        )

        if response.status_code == 409:
            return {
                "mealName": recipe.get("mealName"),
                "skipped": True,
                "reason": "Meal name or source URL is already imported.",
            }
        if not response.ok:
            raise RuntimeError(f"Import API {response.status_code}: {_response_error(response)}")

        if response.content:
            try:
                return response.json()
            except ValueError:
                return {"message": response.text}

        return {"message": "Imported successfully."}

    finally:
        for handle in handles:
            handle.close()
