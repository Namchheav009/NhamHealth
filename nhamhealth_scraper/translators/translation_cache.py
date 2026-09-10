import json
from pathlib import Path
from typing import Any


class TranslationCache:
    """
    Persistent disk cache for translated texts to prevent redundant API calls
    and speed up re-runs.
    """

    def __init__(self, cache_file: Path | str = "output/.translation_cache.json"):
        self.cache_file = Path(cache_file)
        self._cache: dict[str, dict[str, str]] = {}
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

    def get(self, text: str, category: str = "general") -> str | None:
        key = text.strip()
        if not key:
            return ""
        bucket = self._cache.get(category, {})
        return bucket.get(key)

    def set(self, text: str, translation: str, category: str = "general") -> None:
        key = text.strip()
        val = translation.strip()
        if not key or not val:
            return
        if category not in self._cache:
            self._cache[category] = {}
        if self._cache[category].get(key) != val:
            self._cache[category][key] = val
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

