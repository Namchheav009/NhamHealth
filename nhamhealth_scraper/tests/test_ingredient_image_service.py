import unittest
from unittest.mock import patch
from types import SimpleNamespace

from scraper.ingredient_image_service import AiImageValidator, Candidate, WebImageSearchProvider


class IngredientImageServiceTests(unittest.TestCase):
    def test_prahok_search_uses_configured_wikimedia_candidates(self):
        response = type("Response", (), {"json": lambda self: {"query": {"pages": {"1": {
            "title": "File:Prahok.jpg", "descriptionurl": "https://commons.example/Prahok",
            "imageinfo": [{"url": "https://upload.example/prahok.jpg", "mime": "image/jpeg", "width": 640, "height": 480,
                           "extmetadata": {"LicenseShortName": {"value": "CC BY-SA"}}}]}}}}})()
        with patch("scraper.ingredient_image_service.requests.get", return_value=response):
            results = WebImageSearchProvider().search("Prahok")
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0].license, "CC BY-SA")

    def test_low_confidence_candidate_is_rejected(self):
        validator = AiImageValidator()
        with patch("scraper.ingredient_image_service.settings", SimpleNamespace(ingredient_ai_image_validation=False)):
            self.assertIsNone(validator.validate("Prahok", Candidate("https://example/p.jpg", "", "", "")))


if __name__ == "__main__":
    unittest.main()
