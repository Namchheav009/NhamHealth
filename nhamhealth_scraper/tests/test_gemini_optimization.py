"""Unit tests for Gemini optimization: model fallback, batching, caching, and budget tracking."""
import time
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

from scraper.ai_usage_tracker import AiUsageTracker
from scraper.ingredient_ai_cache import IngredientAiCache
from scraper.ingredient_image_service import (
    AiImageValidator,
    Candidate,
    IngredientImageService,
    LocalCacheProvider,
    TheMealDbProvider,
    WebImageSearchProvider,
)
from scraper.ingredient_normalization_service import normalize_ingredient, normalize_ingredients_batch
from translators.khmer_translator import KhmerTranslator


class GeminiOptimizationTests(unittest.TestCase):

    def setUp(self):
        self.tracker = AiUsageTracker()
        self.cache_dir = Path("output/_test_cache")
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.cache_file = self.cache_dir / "test_ai_cache.json"
        if self.cache_file.exists():
            self.cache_file.unlink()
        self.cache = IngredientAiCache(cache_file=self.cache_file)

    def tearDown(self):
        if self.cache_file.exists():
            self.cache_file.unlink()

    def test_ai_usage_tracker_budget_exhaustion(self):
        """Tracker accurately limits calls to max_ai_requests budget."""
        self.tracker.set_budget(2)
        self.assertTrue(self.tracker.can_call_ai())
        self.assertFalse(self.tracker.is_budget_exhausted())

        self.tracker.record_request("gemini-3.1-flash-lite")
        self.assertEqual(self.tracker.flash_lite_requests, 1)
        self.assertEqual(self.tracker.total_ai_requests, 1)
        self.assertTrue(self.tracker.can_call_ai())

        self.tracker.record_request("gemini-3.6-flash")
        self.assertEqual(self.tracker.flash_requests, 1)
        self.assertEqual(self.tracker.total_ai_requests, 2)
        self.assertFalse(self.tracker.can_call_ai())
        self.assertTrue(self.tracker.is_budget_exhausted())

        summary = self.tracker.summary_string()
        self.assertIn("Flash Lite requests: 1", summary)
        self.assertIn("Flash requests: 1", summary)

    def test_negative_cache_ttl_and_hits(self):
        """Negative cache respects 24h TTL and avoids redundant AI calls."""
        # 1. Set missing entry
        self.cache.set_missing("Wild Betel Leaf", "Wild Betel Leaf", ttl=86400.0)
        self.assertTrue(self.cache.is_negative_cached("Wild Betel Leaf"))

        entry = self.cache.get("Wild Betel Leaf")
        self.assertIsNotNone(entry)
        self.assertEqual(entry["status"], "MISSING")

        # 2. Simulate expired negative cache entry
        entry["timestamp"] = time.time() - 90000.0  # > 24 hours ago
        self.cache.save()
        expired = self.cache.get("Wild Betel Leaf")
        self.assertIsNone(expired)

    def test_multi_candidate_image_validation_single_call_success(self):
        """Single multimodal Gemini call validates and ranks all candidates."""
        validator = AiImageValidator()
        candidates = [
            Candidate("https://example.com/1.jpg", "https://example.com/1", "CC-BY", "Prahok paste 1"),
            Candidate("https://example.com/2.jpg", "https://example.com/2", "CC-BY", "Prahok raw 2"),
        ]

        fake_resp_img = MagicMock()
        fake_resp_img.ok = True
        fake_resp_img.content = b"fake-image-bytes" * 200
        fake_resp_img.headers = {"content-type": "image/jpeg"}

        gemini_response_json = {
            "selectedCandidate": 2,
            "confidence": 0.94,
            "reason": "Authentic Cambodian prahok paste",
            "scores": [
                {"candidate": 1, "score": 0.40, "match": False},
                {"candidate": 2, "score": 0.94, "match": True},
            ],
        }

        with patch.object(validator.session, "get", return_value=fake_resp_img), \
             patch.object(validator, "_call_gemini_multimodal", return_value=gemini_response_json), \
             patch("scraper.ingredient_image_service.settings", SimpleNamespace(
                 ingredient_ai_image_validation=True,
                 gemini_api_key="fake-key",
                 gemini_model="gemini-3.1-flash-lite",
                 gemini_fallback_model="gemini-3.6-flash",
                 ai_fallback_confidence=0.75,
                 ingredient_image_min_confidence=0.80,
                 max_image_bytes=5242880,
                 request_timeout_seconds=5,
             )):
            selected, conf, model_used, reqs_used, details = validator.rank_candidates(
                "Prahok", ["prahok", "fermented fish paste"], candidates
            )

            self.assertIsNotNone(selected)
            self.assertEqual(selected.url, "https://example.com/2.jpg")
            self.assertEqual(conf, 0.94)
            self.assertEqual(model_used, "gemini-3.1-flash-lite")
            # Crucial: exactly 1 Gemini request was made for both candidates
            self.assertEqual(reqs_used, 1)

    def test_fallback_model_invoked_only_on_low_confidence(self):
        """Fallback model gemini-3.6-flash is called only when Flash Lite confidence < 0.75."""
        validator = AiImageValidator()
        candidates = [
            Candidate("https://example.com/1.jpg", "https://example.com/1", "CC-BY", "Slork Ngor"),
        ]

        fake_resp_img = MagicMock()
        fake_resp_img.ok = True
        fake_resp_img.content = b"fake-image-bytes" * 200
        fake_resp_img.headers = {"content-type": "image/jpeg"}

        flash_lite_resp = {
            "selectedCandidate": 1,
            "confidence": 0.52,  # Below 0.75 threshold
            "reason": "Uncertain about leaf type",
        }
        fallback_resp = {
            "selectedCandidate": 1,
            "confidence": 0.91,
            "reason": "Confirmed authentic Cambodian Slork Ngor leaves",
        }

        with patch.object(validator.session, "get", return_value=fake_resp_img), \
             patch.object(validator, "_call_gemini_multimodal", side_effect=[flash_lite_resp, fallback_resp]), \
             patch("scraper.ingredient_image_service.settings", SimpleNamespace(
                 ingredient_ai_image_validation=True,
                 gemini_api_key="fake-key",
                 gemini_model="gemini-3.1-flash-lite",
                 gemini_fallback_model="gemini-3.6-flash",
                 ai_fallback_confidence=0.75,
                 ingredient_image_min_confidence=0.80,
                 max_image_bytes=5242880,
                 request_timeout_seconds=5,
             )):
            selected, conf, model_used, reqs_used, details = validator.rank_candidates(
                "Slork Ngor", ["slork ngor"], candidates
            )

            self.assertIsNotNone(selected)
            self.assertEqual(conf, 0.91)
            self.assertEqual(model_used, "gemini-3.6-flash")
            self.assertEqual(reqs_used, 2)

    def test_batch_translation_single_request(self):
        """Batch translation processes multiple ingredients together in one Gemini call."""
        translator = KhmerTranslator()
        translator.gemini_api_key = "fake-key"
        batch_ingredients = ["Pandan", "Fresh Galangal", "Prahok", "Snake Beans", "Kampot Black Pepper"]

        gemini_batch_reply = [
            {"original": "Pandan", "normalizedName": "Pandan Leaves", "preparationNote": None, "khmerName": "ស្លឹកតើយ", "searchAliases": ["pandan", "pandan leaf"], "confidence": 0.95},
            {"original": "Fresh Galangal", "normalizedName": "Galangal", "preparationNote": "fresh", "khmerName": "រំដេងស្រស់", "searchAliases": ["galangal"], "confidence": 0.95},
            {"original": "Prahok", "normalizedName": "Prahok", "preparationNote": None, "khmerName": "ប្រហុក", "searchAliases": ["prahok"], "confidence": 0.95},
            {"original": "Snake Beans", "normalizedName": "Yardlong Bean", "preparationNote": None, "khmerName": "សណ្តែកកួរ", "searchAliases": ["yardlong bean"], "confidence": 0.95},
            {"original": "Kampot Black Pepper", "normalizedName": "Kampot Pepper", "preparationNote": None, "khmerName": "ម្រេចខ្មៅកំពត", "searchAliases": ["kampot pepper"], "confidence": 0.95},
        ]

        fake_resp = MagicMock()
        fake_resp.ok = True
        fake_resp.json.return_value = {
            "candidates": [{"content": {"parts": [{"text": str(gemini_batch_reply).replace("'", '"').replace("None", "null")}]}}]
        }

        with patch.object(translator.session, "post", return_value=fake_resp):
            results = translator.translate_ingredients_batch(batch_ingredients, max_batch_size=10)

        self.assertEqual(len(results), 5)
        # Verify returned content
        names = {r["original"]: r["khmerName"] for r in results}
        self.assertEqual(names["Pandan"], "ស្លឹកតើយ")
        self.assertEqual(names["Prahok"], "ប្រហុក")

    def test_pre_ai_pipeline_stages(self):
        """Verify pre-AI stages (cache, TheMealDB, title filtering) operate before calling Gemini."""
        # 1. Existing local webp cache hit
        local_provider = LocalCacheProvider()
        lemongrass = local_provider.get("Lemongrass")
        self.assertIsNotNone(lemongrass)

        # 2. Excluded Wikimedia titles are filtered out before AI
        search_provider = WebImageSearchProvider()
        fake_wiki_resp = MagicMock()
        fake_wiki_resp.json.return_value = {
            "query": {
                "pages": {
                    "1": {
                        "title": "File:Map of Cambodia showing prahok regions.png",
                        "imageinfo": [{"url": "https://upload.wikimedia.org/map.png", "mime": "image/png", "width": 600, "height": 600}],
                    },
                    "2": {
                        "title": "File:Prahok dipping sauce.jpg",
                        "imageinfo": [{"url": "https://upload.wikimedia.org/prahok.jpg", "mime": "image/jpeg", "width": 600, "height": 600}],
                    },
                }
            }
        }
        with patch("scraper.ingredient_image_service.requests.get", return_value=fake_wiki_resp):
            candidates = search_provider.search("Prahok")
            # Map should be excluded by title matching; only prahok image kept
            self.assertEqual(len(candidates), 1)
            self.assertIn("Prahok dipping sauce", candidates[0].title)


if __name__ == "__main__":
    unittest.main()

