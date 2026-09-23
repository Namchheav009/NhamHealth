import hashlib
import json
from pathlib import Path
from typing import Any, Dict, Optional


def compute_recipe_hash(
    recipe: dict,
    glossary_version: str = "2.0",
    translation_version: str = "1.0",
) -> str:
    """
    Compute a deterministic SHA-256 hash using recipe content,
    glossary version, and translation version.
    """
    content = {
        "mealName": (recipe.get("mealName") or "").strip().lower(),
        "description": (recipe.get("description") or "").strip().lower(),
        "ingredients": [
            {
                "name": (i.get("ingredientName") or i.get("name") or "").strip().lower(),
                "quantity": i.get("quantity"),
                "unit": (i.get("unit") or "").strip().lower(),
            }
            for i in (recipe.get("ingredients") or [])
        ],
        "steps": [
            s.get("instruction", "").strip().lower() if isinstance(s, dict) else str(s).strip().lower()
            for s in (recipe.get("steps") or [])
        ],
        "glossary_version": glossary_version,
        "translation_version": translation_version,
    }
    raw = json.dumps(content, sort_keys=True, ensure_ascii=True)
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


class TranslationCache:
    """
    Persistent disk cache for translated texts and full-recipe translations
    to prevent redundant API calls and speed up re-runs.
    """

    def __init__(self, cache_file: Path | str = "output/.translation_cache.json"):
        self.cache_file = Path(cache_file)
        self._cache: Dict[str, Any] = {}
        self._dirty = False
        self.load()

    def load(self) -> None:
        if self.cache_file.exists():
            try:
                data = json.loads(self.cache_file.read_text(encoding="utf-8"))
                if isinstance(data, dict):
                    self._cache = data
            except Exception:
                self._cache = {}
        else:
            self._cache = {}
        self._dirty = False

    def get(self, text: str, category: str = "general") -> Optional[str]:
        key = text.strip()
        if not key:
            return ""
        bucket = self._cache.get(category, {})
        if isinstance(bucket, dict):
            return bucket.get(key)
        return None

    def set(self, text: str, translation: str, category: str = "general") -> None:
        key = text.strip()
        val = translation.strip()
        if not key or not val:
            return
        if category not in self._cache or not isinstance(self._cache[category], dict):
            self._cache[category] = {}
        if self._cache[category].get(key) != val:
            self._cache[category][key] = val
            self._dirty = True

    def get_recipe(self, recipe_hash: str) -> Optional[dict]:
        recipes_bucket = self._cache.get("recipes", {})
        if isinstance(recipes_bucket, dict):
            return recipes_bucket.get(recipe_hash)
        return None

    def set_recipe(self, recipe_hash: str, translation_data: dict) -> None:
        if "recipes" not in self._cache or not isinstance(self._cache["recipes"], dict):
            self._cache["recipes"] = {}
        self._cache["recipes"][recipe_hash] = translation_data
        self._dirty = True

    def save(self) -> None:
        if not self._dirty:
            return
        try:
            self.cache_file.parent.mkdir(parents=True, exist_ok=True)
            temp_file = self.cache_file.with_suffix(".tmp")
            temp_file.write_text(json.dumps(self._cache, ensure_ascii=False, indent=2), encoding="utf-8")
            temp_file.replace(self.cache_file)
            self._dirty = False
        except Exception:
            pass


# Global singleton instance
translation_cache = TranslationCache()
