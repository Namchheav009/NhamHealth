"""Move approved scraper ingredient images into NhamHealth shared storage.

The scraper never receives a Supabase service key.  It asks the authenticated
Spring Boot admin endpoint to validate and store each image instead.
"""
from __future__ import annotations

import hashlib
from pathlib import Path
from typing import Callable

import requests

from .config import settings
from .image_downloader import _to_webp, download_and_prepare_image, slugify
from .importer import _get_import_token, _response_error


def _is_already_stored(url: object) -> bool:
    value = str(url or "").strip()
    return value.startswith("/uploads/ingredient-images/") or "/storage/v1/object/public/" in value


def _prepared_image_path(ingredient: dict) -> Path | None:
    """Return a local WebP copy of a resolved ingredient image, if available."""
    local_path = Path(str(ingredient.get("storagePath") or ""))
    if local_path.is_file():
        # Local library files are already curated.  The backend still validates
        # their bytes when they are uploaded.
        if local_path.suffix.lower() == ".webp":
            return local_path
        output = Path("images/ingredient-staging") / f"{slugify(local_path.stem)}.webp"
        output.parent.mkdir(parents=True, exist_ok=True)
        return _to_webp(local_path.read_bytes(), output, settings.max_image_bytes)

    source_url = str(ingredient.get("imageUrl") or "").strip()
    if not source_url.startswith(("https://", "http://")):
        return None
    digest = hashlib.sha256(source_url.encode("utf-8")).hexdigest()[:12]
    name = f"{slugify(str(ingredient.get('ingredientName') or 'ingredient'))}-{digest}"
    try:
        path = download_and_prepare_image(source_url, name, "images/ingredient-staging")
        return Path(path) if path else None
    except Exception:
        return None


def upload_recipe_ingredient_images(
    recipe: dict,
    *,
    post: Callable = requests.post,
    token_getter: Callable[[], str] = _get_import_token,
) -> list[str]:
    """Upload each unique resolved image and replace its URL with a stored URL.

    Failed optional images do not block importing the meal.  Their external URL
    is removed so the database never silently depends on an unowned image host.
    """
    warnings: list[str] = []
    uploaded_by_source: dict[str, str] = {}
    token: str | None = None

    for ingredient in recipe.get("ingredients") or []:
        source_url = str(ingredient.get("imageUrl") or "").strip()
        local_identity = str(ingredient.get("imageLocalPath") or ingredient.get("storagePath") or "").strip()
        source_key = source_url or local_identity
        if not source_key or _is_already_stored(source_url):
            continue
        if source_key in uploaded_by_source:
            ingredient["imageUrl"] = uploaded_by_source[source_key]
            ingredient["imageSource"] = "SCRAPED_TO_SUPABASE"
            continue

        prepared = _prepared_image_path(ingredient)
        if prepared is None or not prepared.is_file():
            message = f"Ingredient image unavailable for {ingredient.get('ingredientName') or 'ingredient'}"
        else:
            try:
                if token is None:
                    token = token_getter()
                with prepared.open("rb") as image_file:
                    response = post(
                        settings.spring_ingredient_image_upload_url,
                        files={"file": (prepared.name, image_file, "image/webp")},
                        headers={"Authorization": f"Bearer {token}"},
                        timeout=60,
                    )
                if response.ok:
                    stored_url = str(response.json().get("imageUrl") or "").strip()
                    if not stored_url:
                        raise RuntimeError("image upload response did not include imageUrl")
                    uploaded_by_source[source_key] = stored_url
                    ingredient["imageUrl"] = stored_url
                    ingredient["imageSource"] = "SCRAPED_TO_SUPABASE"
                    ingredient["imageUploadError"] = None
                    continue
                message = _response_error(response)
            except Exception as exc:
                message = str(exc)

        ingredient["imageUrl"] = None
        ingredient["imageSource"] = "ADMIN_UPLOAD_REQUIRED"
        ingredient["imageReviewStatus"] = "PENDING_REVIEW"
        ingredient["imageUploadError"] = message
        warnings.append(f"Ingredient image not uploaded for {ingredient.get('ingredientName') or 'ingredient'}: {message}")

    return warnings
