"""Persistent cache for ingredient AI normalization, translations, and images with negative TTL."""
from __future__ import annotations

import json
import re
import time
from pathlib import Path
from typing import Any, Optional

from .config import settings


def normalize_ingredient_key(name: str) -> str:
    return " ".join(re.sub(r"[^\w\s-]", " ", (name or "").lower()).replace("_", " ").split())


class IngredientAiCache:
    """
    Persists AI-derived metadata (normalization, Khmer translation, aliases, image, confidence, model).
    Supports a TTL (default 24h) for negative / MISSING results to prevent quota burning.
    """

    def __init__(self, cache_file: Optional[str | Path] = None):
        self.cache_file = Path(cache_file or getattr(settings, "ingredient_ai_cache_file", "output/ingredient_ai_cache.json"))
        self._cache: dict[str, dict[str, Any]] = {}
        self.load()

    def load(self) -> None:
        if self.cache_file.is_file():
            try:
                self._cache = json.loads(self.cache_file.read_text(encoding="utf-8"))
            except (OSError, ValueError):
                self._cache = {}
        else:
            self._cache = {}

    def save(self) -> None:
        try:
            self.cache_file.parent.mkdir(parents=True, exist_ok=True)
            self.cache_file.write_text(
                json.dumps(self._cache, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
        except OSError:
            pass

    def get(self, name_or_key: str, default_ttl: float = 86400.0) -> Optional[dict[str, Any]]:
        key = normalize_ingredient_key(name_or_key)
        entry = self._cache.get(key)
        if not entry:
            return None

        status = entry.get("status")
        timestamp = entry.get("timestamp", 0)
        ttl = entry.get("ttl", default_ttl)

        # Negative cache expiration check (24 hours TTL)
        if status == "MISSING":
            if (time.time() - timestamp) > ttl:
                # Expired negative cache entry
                return None
            return entry

        # Successful / FOUND entries persist indefinitely
        return entry

    def is_negative_cached(self, name_or_key: str, default_ttl: float = 86400.0) -> bool:
        entry = self.get(name_or_key, default_ttl=default_ttl)
        return bool(entry and entry.get("status") == "MISSING")

    def set(
        self,
        name_or_key: str,
        normalized_name: str,
        khmer_translation: Optional[str] = None,
        search_aliases: Optional[list[str]] = None,
        selected_image: Optional[str] = None,
        image_url: Optional[str] = None,
        ai_confidence: float = 0.0,
        model_used: Optional[str] = None,
        status: str = "FOUND",
        ttl: float = 86400.0,
    ) -> dict[str, Any]:
        key = normalize_ingredient_key(name_or_key)
        entry = {
            "ingredientKey": key,
            "ingredientName": name_or_key,
            "normalizedName": normalized_name,
            "khmerTranslation": khmer_translation,
            "searchAliases": search_aliases or [],
            "selectedImage": selected_image,
            "imageUrl": image_url,
            "aiConfidence": float(ai_confidence or 0.0),
            "modelUsed": model_used or "none",
            "status": status,
            "timestamp": time.time(),
            "ttl": ttl,
        }
        self._cache[key] = entry
        self.save()
        return entry

    def set_missing(
        self,
        name_or_key: str,
        normalized_name: str,
        search_aliases: Optional[list[str]] = None,
        khmer_translation: Optional[str] = None,
        ttl: float = 86400.0,
    ) -> dict[str, Any]:
        return self.set(
            name_or_key=name_or_key,
            normalized_name=normalized_name,
            khmer_translation=khmer_translation,
            search_aliases=search_aliases or [],
            selected_image=None,
            image_url=None,
            ai_confidence=0.0,
            model_used="none",
            status="MISSING",
            ttl=ttl,
        )


# Global singleton cache instance
ingredient_ai_cache = IngredientAiCache()

