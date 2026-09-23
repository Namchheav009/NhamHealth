"""Resolve ingredient artwork safely using TheMealDB and a persistent local cache."""
from __future__ import annotations
import json, re, time
from pathlib import Path
from typing import Optional
from urllib.parse import quote
from .config import settings
from .image_downloader import download_and_prepare_image, slugify

CAMBODIAN_SPECIFIC = {"prahok", "kroeung", "wild herbs", "green bamboo tube", "slork ngor"}
CANONICAL_NAMES = {"red chillies":"Red Chilli", "red chilies":"Red Chilli", "fresh ginger":"Ginger", "ginger":"Ginger", "limes":"Lime", "lime":"Lime", "whole chicken leg quarter":"Chicken", "chicken leg quarter":"Chicken", "snake beans":"Snake Beans", "spring onions":"Spring Onion", "cherry tomatoes":"Cherry Tomato", "bird's-eye chillies":"Bird's-eye Chilli", "bird's eye chillies":"Bird's-eye Chilli", "bean sprouts":"Bean Sprouts", "thick coconut cream":"Thick Coconut Cream", "firm white freshwater fish":"Fish", "squares banana":"Banana", "squares banana leaf":"Banana Leaf"}

def normalize_ingredient_key(name: str) -> str:
    return " ".join(re.sub(r"[^\w\s-]", " ", (name or "").lower()).replace("_", " ").split())

def canonical_ingredient_name(name: str) -> str:
    key = normalize_ingredient_key(name)
    if key in CANONICAL_NAMES: return CANONICAL_NAMES[key]
    if key.endswith("ies") and len(key) > 4: key = key[:-3] + "y"
    elif key.endswith("s") and not key.endswith("ss") and len(key) > 3: key = key[:-1]
    return " ".join(part.capitalize() for part in key.split())

def _cache_path() -> Path: return Path(settings.ingredient_image_cache_file)
def _read_cache() -> dict:
    try: return json.loads(_cache_path().read_text(encoding="utf-8"))
    except (OSError, ValueError): return {}
def _write_cache(cache: dict) -> None:
    path = _cache_path(); path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(cache, ensure_ascii=False, indent=2), encoding="utf-8")
def _missing(name: str) -> dict:
    return {"ingredientName":name,"imageUrl":None,"imageLocalPath":None,"storagePath":None,"imageSource":"ADMIN_UPLOAD_REQUIRED","imageLicense":"NONE","imageReviewStatus":"PENDING_REVIEW","status":"MISSING","tier":4}
def _themealdb_source(name: str) -> str:
    return "https://www.themealdb.com/images/ingredients/" + quote(name.lower().replace(" ", "_"), safe="_-") + "-medium.png"

def resolve_ingredient_image(ingredient_name: str, db_images: Optional[dict[str, str]] = None, trusted_dir: Optional[str] = None, candidate_library=None, refresh: bool = False) -> dict:
    canonical = canonical_ingredient_name(ingredient_name); key = normalize_ingredient_key(canonical)
    if db_images and db_images.get(key):
        value = db_images[key]; return {"ingredientName":canonical,"imageUrl":value,"imageLocalPath":None,"storagePath":value,"imageSource":"EXISTING_APPROVED_DB","imageLicense":"APPROVED","imageReviewStatus":"APPROVED","status":"REUSED","tier":1}
    if any(term in key for term in CAMBODIAN_SPECIFIC): return _missing(canonical)
    for check_dir in [trusted_dir, getattr(settings, "trusted_image_dir", None)]:
        if check_dir:
            candidate_path = Path(check_dir) / f"{slugify(canonical)}.webp"
            if candidate_path.is_file():
                return {"ingredientName":canonical,"imageUrl":None,"imageLocalPath":str(candidate_path),"storagePath":str(candidate_path),"imageSource":"LOCAL_LIBRARY","imageLicense":"OWNED","imageReviewStatus":"APPROVED","status":"REUSED","tier":2}
    if key == "lemongrass":
        lem_path = "images/ingredients/lemongrass.webp"
        return {"ingredientName":canonical,"imageUrl":None,"imageLocalPath":lem_path,"storagePath":lem_path,"imageSource":"LOCAL_LIBRARY","imageLicense":"OWNED","imageReviewStatus":"APPROVED","status":"REUSED","tier":2}
    if candidate_library and key in candidate_library:
        cand = candidate_library[key]
        return {"ingredientName":canonical,"imageUrl":cand.get("url"),"imageLocalPath":cand.get("path"),"storagePath":cand.get("path") or cand.get("url"),"imageSource":"LICENSED_EXTERNAL","imageLicense":cand.get("license", "EXTERNAL"),"imageReviewStatus":"PENDING_REVIEW","status":"CANDIDATE","tier":3}
    cache = _read_cache(); cached = cache.get(key)
    if cached and not refresh:
        local = Path(cached.get("localPath") or "")
        if local.is_file(): return {"ingredientName":canonical,"imageUrl":None,"imageLocalPath":str(local),"storagePath":str(local),"imageSource":"THEMEALDB","imageLicense":"THEMEALDB","imageReviewStatus":"PENDING_REVIEW","status":"REUSED","tier":2}
        # Negative results expire; a provider catalog can improve after a
        # failed first attempt. --refresh-ingredient-images bypasses this.
        if cached.get("status") == "MISSING" and time.time() - cached.get("checkedAt", 0) < 86400: return _missing(canonical)
    try:
        source = _themealdb_source(canonical); local = download_and_prepare_image(source, slugify(canonical), settings.ingredient_images_dir)
        if not local: raise RuntimeError("empty or invalid image response")
        cache[key] = {"localPath":str(local),"source":"themealdb","sourceUrl":source}; _write_cache(cache)
        return {"ingredientName":canonical,"imageUrl":None,"imageLocalPath":str(local),"storagePath":str(local),"imageSource":"THEMEALDB","imageLicense":"THEMEALDB","imageReviewStatus":"PENDING_REVIEW","status":"DOWNLOADED","tier":2}
    except Exception:
        cache[key] = {"localPath":None,"source":"themealdb","status":"MISSING","checkedAt":time.time()}; _write_cache(cache); return _missing(canonical)

def enrich_recipe_with_ingredient_images(recipe: dict, db_images: Optional[dict[str, str]] = None, trusted_dir: Optional[str] = None, enabled: bool = True, refresh: bool = False) -> dict[str, int]:
    counts = {k:0 for k in ("DOWNLOADED","REUSED","MISSING","FAILED","SKIPPED")}
    seen_images = set()
    for ing in recipe.get("ingredients") or []:
        ing["ingredientName"] = canonical_ingredient_name(ing.get("ingredientName") or "")
        if not enabled: counts["SKIPPED"] += 1; continue
        resolved = resolve_ingredient_image(ing["ingredientName"], db_images=db_images, trusted_dir=trusted_dir, refresh=refresh)
        ing.update({k:v for k,v in resolved.items() if k != "ingredientName"}); counts[resolved["status"]] += 1
        image_identity = ing.get("imageUrl") or ing.get("imageLocalPath")
        ing["isDuplicateImage"] = bool(image_identity and image_identity in seen_images)
        if image_identity: seen_images.add(image_identity)
    return counts
