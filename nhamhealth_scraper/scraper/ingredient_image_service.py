"""Provider-based ingredient-image repair service; no third-party URL is persisted."""
from __future__ import annotations

import base64
import json
import re
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Optional
from urllib.parse import quote

import requests

from .ai_usage_tracker import ai_tracker
from .config import HEADERS, settings
from .image_downloader import download_and_prepare_image, slugify
from .importer import _get_import_token
from .ingredient_ai_cache import ingredient_ai_cache
from .ingredient_image_resolver import canonical_ingredient_name, normalize_ingredient_key
from .ingredient_image_uploader import upload_recipe_ingredient_images
from .recipe_detail import is_safe_url

ALIASES = {
    "prahok": ["Prahok", "Cambodian fermented fish paste", "Khmer fermented fish paste"],
    "kroeung": ["Kroeung", "Cambodian kroeung", "Cambodian spice paste"],
    "slork ngor": ["Slork Ngor Cambodia", "Cambodian Slork Ngor leaves", "young cabbage leaves Cambodia"],
    "kaffir lime": ["Kaffir lime", "makrut lime", "kaffir lime leaves", "makrut lime leaves"],
    "pandan": ["Pandan", "Pandan leaves", "screwpine leaves"],
    "fresh galangal": ["Fresh Galangal", "Galangal", "Cambodian galangal"],
    "snake beans": ["Snake beans", "yardlong bean", "long beans"],
    "kampot black pepper": ["Kampot black pepper", "Kampot pepper", "black peppercorns"],
}

EXCLUDED_TITLE_KEYWORDS = {
    "map", "flag", "diagram", "chart", "icon", "logo", "screenshot",
    "signature", "portrait", "passport", "stamp", "monument", "statue",
    "building", "location", "plan", "poster", "label",
}


@dataclass
class Candidate:
    url: str
    source_url: str
    license: str
    title: str
    mime: str = "image/jpeg"


class ExistingIngredientProvider:
    def missing(self) -> list[dict]:
        try:
            response = requests.get(
                settings.spring_missing_ingredient_images_url,
                headers={"Authorization": f"Bearer {_get_import_token()}"},
                timeout=settings.request_timeout_seconds,
            )
            response.raise_for_status()
            data = response.json()
            return data if isinstance(data, list) else []
        except Exception as exc:
            print(f"  Note: Missing ingredients API unavailable ({exc}).")
            return []


class LocalCacheProvider:
    def get(self, name: str) -> Optional[Path]:
        canonical = canonical_ingredient_name(name)
        for check_dir in [getattr(settings, "ingredient_images_dir", "images/ingredients"), getattr(settings, "trusted_image_dir", "images/ingredients_library")]:
            if check_dir:
                path = Path(check_dir) / f"{slugify(canonical)}.webp"
                if path.is_file():
                    return path
        return None


class TheMealDbProvider:
    def fetch(self, name: str) -> Optional[str]:
        canonical = canonical_ingredient_name(name)
        url = "https://www.themealdb.com/images/ingredients/" + quote(
            canonical.lower().replace(" ", "_"), safe="_-"
        ) + "-medium.png"
        try:
            return download_and_prepare_image(url, slugify(canonical), settings.ingredient_images_dir)
        except Exception:
            return None


class WebImageSearchProvider:
    """Wikimedia Commons API provider with SSRF, title, and MIME filtering."""

    def search(self, name: str) -> list[Candidate]:
        if not settings.image_search_enabled or settings.image_search_provider.lower() != "wikimedia":
            return []
        key = normalize_ingredient_key(name)
        queries = ALIASES.get(key, [name, f"Cambodian {name}"])
        found, seen = [], set()

        for query in queries:
            try:
                resp = requests.get(
                    "https://commons.wikimedia.org/w/api.php",
                    params={
                        "action": "query",
                        "generator": "search",
                        "gsrsearch": query,
                        "gsrnamespace": 6,
                        "gsrlimit": 6,
                        "prop": "imageinfo",
                        "iiprop": "url|mime|size|extmetadata",
                        "format": "json",
                    },
                    headers=HEADERS,
                    timeout=settings.request_timeout_seconds,
                )
                body = resp.json()
                pages = (body.get("query", {}).get("pages", {}) or {}).values()
                for page in pages:
                    info = (page.get("imageinfo") or [{}])[0]
                    url = info.get("url", "")
                    mime = (info.get("mime") or "").lower()
                    title = page.get("title", "")

                    # Stage 5: URL validation & SSRF check
                    if not url or url in seen or not is_safe_url(url):
                        continue

                    # Stage 6: Filename / title matching (reject non-food media)
                    lower_title = title.lower()
                    title_words = set(re.findall(r"\b[a-z]+\b", lower_title))
                    if title_words & EXCLUDED_TITLE_KEYWORDS:
                        continue

                    # Stage 7: MIME & dimension validation (raster only, min 200x200)
                    if mime not in {"image/jpeg", "image/png", "image/webp"}:
                        continue
                    if info.get("width", 0) < 200 or info.get("height", 0) < 200:
                        continue

                    seen.add(url)
                    meta = info.get("extmetadata", {})
                    license_name = (meta.get("LicenseShortName", {}) or {}).get("value", "WIKIMEDIA")
                    found.append(
                        Candidate(
                            url=url,
                            source_url=page.get("descriptionurl", url),
                            license=license_name,
                            title=title,
                            mime=mime,
                        )
                    )
            except requests.RequestException:
                continue

        return found[:6]


class AiImageValidator:
    """Multi-candidate image evaluator using primary Flash Lite and conditional Flash fallback."""

    def __init__(self):
        self.session = requests.Session()

    def _call_gemini_multimodal(self, model: str, parts: list[dict], timeout: int = 60) -> Optional[dict]:
        if not settings.gemini_api_key:
            return None
        url = f"{settings.gemini_base_url}/models/{model}:generateContent?key={settings.gemini_api_key}"
        payload = {
            "contents": [{"parts": parts}],
            "generationConfig": {
                "temperature": 0.2,
                "responseMimeType": "application/json",
            },
        }
        try:
            resp = self.session.post(url, json=payload, headers=HEADERS, timeout=timeout)
            if not resp.ok:
                return None
            data = resp.json()
            candidates = data.get("candidates") or []
            if not candidates:
                return None
            content_parts = candidates[0].get("content", {}).get("parts") or []
            if not content_parts or "text" not in content_parts[0]:
                return None
            text = content_parts[0]["text"].strip()
            if text.startswith("```"):
                lines = text.splitlines()
                if lines[0].startswith("```"):
                    lines = lines[1:]
                if lines and lines[-1].startswith("```"):
                    lines = lines[:-1]
                text = "\n".join(lines).strip()
            return json.loads(text)
        except Exception:
            return None

    def rank_candidates(
        self,
        name: str,
        aliases: list[str],
        candidates: list[Candidate],
    ) -> tuple[Optional[Candidate], float, str, int, dict]:
        """
        Send all candidate images in ONE Gemini request.
        Calls primary model (gemini-3.1-flash-lite).
        Falls back to gemini-3.6-flash ONLY if primary fails, confidence < threshold, or unparseable.
        Returns: (selected_candidate, confidence, model_used, gemini_requests_used, details_dict)
        """
        if not settings.ingredient_ai_image_validation or not settings.gemini_api_key or not candidates:
            return None, 0.0, "none", 0, {}

        # Fetch candidate image bytes
        valid_candidates: list[tuple[Candidate, bytes, str]] = []
        for cand in candidates[:6]:
            try:
                res = self.session.get(cand.url, headers=HEADERS, timeout=settings.request_timeout_seconds)
                if res.ok and len(res.content) <= settings.max_image_bytes and len(res.content) >= 1024:
                    mime = res.headers.get("content-type", cand.mime).split(";")[0].strip().lower()
                    if mime in {"image/jpeg", "image/png", "image/webp"}:
                        valid_candidates.append((cand, res.content, mime))
            except Exception:
                continue

        if not valid_candidates:
            return None, 0.0, "none", 0, {}

        # Build prompt and multi-candidate parts
        instruction_prompt = (
            f"You validate and rank ingredient photos for a Cambodian nutrition and recipe app.\n"
            f"Target ingredient: {name}\n"
            f"Aliases / alternate names: {', '.join(aliases) if aliases else 'none'}\n\n"
            f"Below are {len(valid_candidates)} candidate photos numbered 1 to {len(valid_candidates)}.\n"
            f"Carefully evaluate each candidate.\n"
            f"Rules:\n"
            f"1. Select the SINGLE BEST candidate photo clearly depicting the raw/fresh/standard culinary ingredient '{name}'.\n"
            f"2. Strictly REJECT: cooked dishes, restaurant plates, logos, screenshots, packaging, drawings, maps, or unrelated foods.\n"
            f"3. If no candidate clearly and accurately represents '{name}', set selectedCandidate to null and confidence to 0.0.\n"
            f"4. Otherwise, set selectedCandidate to the 1-based index (1 to {len(valid_candidates)}), provide confidence (0.0 to 1.0), and individual scores.\n\n"
            f"Return JSON ONLY:\n"
            f"{{\n"
            f'  "selectedCandidate": 1,\n'
            f'  "confidence": 0.94,\n'
            f'  "reason": "...",\n'
            f'  "scores": [\n'
            f'    {{"candidate": 1, "score": 0.94, "match": true, "reason": "..."}}\n'
            f"  ]\n"
            f"}}"
        )

        parts: list[dict] = [{"text": instruction_prompt}]
        for idx, (cand, img_bytes, mime) in enumerate(valid_candidates, 1):
            parts.append({"text": f"Candidate {idx} (Title: {cand.title}):"})
            parts.append({"inline_data": {"mime_type": mime, "data": base64.b64encode(img_bytes).decode()}})

        # Primary Model attempt
        primary_model = settings.gemini_model
        fallback_model = settings.gemini_fallback_model
        threshold = settings.ai_fallback_confidence

        if not ai_tracker.can_call_ai():
            return None, 0.0, "budget_exhausted", 0, {}

        ai_tracker.record_request(primary_model)
        requests_used = 1
        model_used = primary_model

        result = self._call_gemini_multimodal(primary_model, parts)
        primary_conf = float(result.get("confidence", 0.0)) if result else 0.0
        selected_idx = result.get("selectedCandidate") if result else None

        # Check if primary model succeeded with sufficient confidence
        if result and isinstance(result, dict) and primary_conf >= threshold:
            selected_cand = valid_candidates[selected_idx - 1][0] if (selected_idx and 1 <= selected_idx <= len(valid_candidates)) else None
            return selected_cand, primary_conf, primary_model, requests_used, result

        # Fallback condition: Flash Lite failed or confidence < threshold
        if ai_tracker.can_call_ai():
            ai_tracker.record_request(fallback_model)
            requests_used += 1
            model_used = fallback_model

            fb_result = self._call_gemini_multimodal(fallback_model, parts)
            if fb_result and isinstance(fb_result, dict):
                fb_conf = float(fb_result.get("confidence", 0.0))
                fb_idx = fb_result.get("selectedCandidate")
                selected_cand = valid_candidates[fb_idx - 1][0] if (fb_idx and 1 <= fb_idx <= len(valid_candidates)) else None
                return selected_cand, fb_conf, fallback_model, requests_used, {
                    "primaryConfidence": primary_conf,
                    **fb_result,
                }
            return None, 0.0, fallback_model, requests_used, {"primaryConfidence": primary_conf}

        # If fallback not possible (e.g. budget limit reached), return primary result
        selected_cand = valid_candidates[selected_idx - 1][0] if (selected_idx and 1 <= selected_idx <= len(valid_candidates)) else None
        return selected_cand, primary_conf, primary_model, requests_used, result or {}

    def validate(self, name: str, candidate: Candidate) -> Optional[dict]:
        """Single candidate validation for backward compatibility."""
        if not settings.ingredient_ai_image_validation or not settings.gemini_api_key:
            return None
        cand, conf, _, _, details = self.rank_candidates(name, [name], [candidate])
        if cand and conf >= settings.ingredient_image_min_confidence:
            return {"match": True, "confidence": conf, "reason": details.get("reason", "Matched by AI")}
        return None


class SupabaseImageUploader:
    def upload_and_update(self, ingredient: dict, local_path: Path | str, source: str, license: str) -> Optional[str]:
        recipe = {
            "ingredients": [
                {
                    "ingredientName": ingredient["name"],
                    "imageLocalPath": str(local_path),
                    "storagePath": str(local_path),
                    "imageSource": source,
                    "imageLicense": license,
                }
            ]
        }
        if upload_recipe_ingredient_images(recipe):
            return None
        url = recipe["ingredients"][0].get("imageUrl")
        if not url:
            return None
        endpoint = settings.spring_missing_ingredient_images_url.rsplit("/missing-images", 1)[0] + f"/{ingredient['id']}/image"
        try:
            response = requests.put(
                endpoint,
                json={"imageUrl": url, "imageSource": source, "imageLicense": license},
                headers={"Authorization": f"Bearer {_get_import_token()}"},
                timeout=60,
            )
            response.raise_for_status()
            return url
        except Exception:
            return None


class IngredientImageService:
    def __init__(self, max_ai_requests: Optional[int] = None):
        self.cache = LocalCacheProvider()
        self.mealdb = TheMealDbProvider()
        self.web = WebImageSearchProvider()
        self.ai = AiImageValidator()
        self.uploader = SupabaseImageUploader()
        self.seen_images: set[str] = set()
        if max_ai_requests is not None or settings.max_ai_requests is not None:
            ai_tracker.set_budget(max_ai_requests or settings.max_ai_requests)

    def repair(self, ingredients: Optional[list[dict]] = None) -> dict[str, int]:
        summary = {"added": 0, "themealdb": 0, "ai_searched": 0, "missing": 0, "cache_hits": 0}
        target_list = ingredients if ingredients is not None else ExistingIngredientProvider().missing()

        for index, ingredient in enumerate(target_list, 1):
            name = ingredient["name"]
            canonical = canonical_ingredient_name(name)
            key = normalize_ingredient_key(name)
            aliases = ALIASES.get(key, [name, f"Cambodian {name}"])
            print(f"\n{name}")

            # Stage 1: Existing ingredient image
            if ingredient.get("imageUrl"):
                ai_tracker.record_avoided()
                print("  Existing Image: FOUND")
                print("  Result: FOUND")
                continue

            # Stage 2: Local cache & negative TTL cache
            cached_entry = ingredient_ai_cache.get(name)
            if cached_entry:
                if cached_entry.get("status") == "FOUND" and (
                    cached_entry.get("selectedImage") or cached_entry.get("imageUrl")
                ):
                    ai_tracker.record_cache_hit()
                    summary["cache_hits"] += 1
                    local = cached_entry.get("selectedImage")
                    source = "LOCAL_CACHE"
                    license = "OWNED"
                    print("  Cache: HIT")
                    if self.uploader.upload_and_update(ingredient, local, source, license):
                        summary["added"] += 1
                        print("  Result: FOUND")
                    else:
                        print("  Result: FOUND (Cached)")
                    continue
                elif cached_entry.get("status") == "MISSING":
                    # Negative cache hit within 24-hour TTL
                    ai_tracker.record_cache_hit()
                    summary["cache_hits"] += 1
                    summary["missing"] += 1
                    print("  Cache: HIT (MISSING)")
                    print("  Result: MISSING")
                    continue

            # Check local library files
            local_path = self.cache.get(name)
            if local_path:
                ai_tracker.record_cache_hit()
                summary["cache_hits"] += 1
                source = "LOCAL_CACHE"
                license = "OWNED"
                print("  Cache: HIT")
                if self.uploader.upload_and_update(ingredient, local_path, source, license):
                    summary["added"] += 1
                    print("  Result: FOUND")
                else:
                    print("  Result: FOUND (Local file)")
                continue

            print("  Cache: MISS")

            # Stage 4: TheMealDB
            mealdb_path = self.mealdb.fetch(canonical)
            if mealdb_path:
                ai_tracker.record_avoided()
                summary["themealdb"] += 1
                source = "THEMEALDB"
                license = "THEMEALDB"
                print("  TheMealDB: FOUND")
                ingredient_ai_cache.set(
                    name_or_key=name,
                    normalized_name=canonical,
                    search_aliases=aliases,
                    selected_image=str(mealdb_path),
                    model_used="none",
                    status="FOUND",
                )
                if self.uploader.upload_and_update(ingredient, mealdb_path, source, license):
                    summary["added"] += 1
                    print("  Result: FOUND")
                else:
                    print("  Result: FOUND (TheMealDB)")
                continue

            print("  TheMealDB: MISS")

            # Check AI budget before performing web search & AI validation
            if not ai_tracker.can_call_ai():
                print(f"  [Budget limit reached] Consumed {ai_tracker.total_ai_requests} AI requests. Stopping AI processing safely and saving progress.")
                break

            # Stage 5-7: Web Image Search + Filtering
            candidates = self.web.search(name)
            # Stage 8: Duplicate detection
            filtered_candidates = [c for c in candidates if c.url not in self.seen_images]
            print(f"  Search: {len(filtered_candidates)} candidates")

            if not filtered_candidates:
                ingredient_ai_cache.set_missing(name, normalized_name=canonical, search_aliases=aliases, ttl=86400.0)
                summary["missing"] += 1
                print("  Result: MISSING")
                continue

            # Multi-candidate single-request AI ranking
            selected_cand, confidence, model_used, reqs_used, details = self.ai.rank_candidates(
                name=canonical,
                aliases=aliases,
                candidates=filtered_candidates,
            )

            if reqs_used > 1:
                print(f"  Flash Lite confidence: {details.get('primaryConfidence', 0.0):.2f}")
                print(f"  Fallback: {model_used}")
            elif model_used != "none":
                print(f"  AI model: {model_used}")
            print(f"  Gemini requests used: {reqs_used}")

            if selected_cand and confidence >= settings.ingredient_image_min_confidence:
                self.seen_images.add(selected_cand.url)
                downloaded = download_and_prepare_image(
                    selected_cand.url,
                    slugify(canonical),
                    settings.ingredient_images_dir,
                )
                if downloaded:
                    uploaded_url = self.uploader.upload_and_update(
                        ingredient, downloaded, "WIKIMEDIA", selected_cand.license
                    )
                    ingredient_ai_cache.set(
                        name_or_key=name,
                        normalized_name=canonical,
                        search_aliases=aliases,
                        selected_image=str(downloaded),
                        image_url=uploaded_url,
                        ai_confidence=confidence,
                        model_used=model_used,
                        status="FOUND",
                    )
                    summary["added"] += 1
                    summary["ai_searched"] += 1
                    print("  Result: FOUND")
                    continue

            # If no candidate matched or confidence was insufficient
            ingredient_ai_cache.set_missing(name, normalized_name=canonical, search_aliases=aliases, ttl=86400.0)
            summary["missing"] += 1
            print("  Result: MISSING")

        ai_tracker.print_summary()
        return summary
