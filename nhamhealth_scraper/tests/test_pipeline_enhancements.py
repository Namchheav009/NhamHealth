import unittest
from unittest.mock import MagicMock, patch

from scraper.ingredient_image_resolver import (
    normalize_ingredient_key,
    resolve_ingredient_image,
    enrich_recipe_with_ingredient_images,
)
from scraper.nutrition_estimator import estimate_recipe_nutrition
from scraper.ingredient_image_uploader import upload_recipe_ingredient_images
from scraper.recipe_detail import _duration_to_minutes, is_safe_url
from translators.culinary_glossary import DISH_NAMES, GLOSSARY_VERSION
from translators.khmer_translator import KhmerTranslator
from translators.translation_cache import compute_recipe_hash, TranslationCache
from translators.validator import comprehensive_validate_translation


class PipelineEnhancementsTests(unittest.TestCase):

    def test_bai_sach_chrouk_and_fish_amok_canonical_translations(self):
        """Verify authentic Cambodian dish names in culinary glossary v2.0."""
        self.assertEqual(DISH_NAMES.get("bai sach chrouk"), "បាយសាច់ជ្រូក")
        self.assertEqual(DISH_NAMES.get("fish amok"), "អាម៉ុកត្រី")
        self.assertEqual(GLOSSARY_VERSION, "2.0")

    def test_duration_parsing_without_overlap(self):
        """Verify durations convert to integer minutes and do not invent sums."""
        self.assertEqual(_duration_to_minutes("PT30M"), 30)
        self.assertEqual(_duration_to_minutes("PT1H15M"), 75)
        self.assertEqual(_duration_to_minutes("1 hr 20 mins"), 80)
        self.assertEqual(_duration_to_minutes("45 min"), 45)
        self.assertEqual(_duration_to_minutes("25"), 25)
        self.assertIsNone(_duration_to_minutes(None))
        self.assertIsNone(_duration_to_minutes(""))
        self.assertIsNone(_duration_to_minutes("invalid-duration"))

    def test_ssrf_safe_url_validation(self):
        """Verify SSRF protection rejects private, loopback, and metadata URLs."""
        self.assertTrue(is_safe_url("https://cambodiancookbook.com/recipes/amok"))
        self.assertTrue(is_safe_url("http://example.com/recipe"))
        # Blocked addresses
        self.assertFalse(is_safe_url("http://localhost:8080/secret"))
        self.assertFalse(is_safe_url("http://127.0.0.1:8080/api"))
        self.assertFalse(is_safe_url("http://169.254.169.254/latest/meta-data/"))
        self.assertFalse(is_safe_url("http://192.168.1.1/admin"))
        self.assertFalse(is_safe_url("http://10.0.0.1/internal"))
        self.assertFalse(is_safe_url("file:///etc/passwd"))
        self.assertFalse(is_safe_url(""))

    def test_4_tier_ingredient_image_resolution(self):
        """Verify 4-tier ingredient image resolution and review statuses."""
        # Tier 1: Existing DB approved
        db_images = {"pork": "https://storage.supabase.co/pork_approved.webp"}
        t1 = resolve_ingredient_image("Pork", db_images=db_images)
        self.assertEqual(t1["tier"], 1)
        self.assertEqual(t1["imageSource"], "EXISTING_APPROVED_DB")
        self.assertEqual(t1["imageReviewStatus"], "APPROVED")
        self.assertEqual(t1["imageUrl"], "https://storage.supabase.co/pork_approved.webp")

        # Tier 2: Local library
        t2 = resolve_ingredient_image("Lemongrass", db_images={})
        self.assertEqual(t2["tier"], 2)
        self.assertEqual(t2["imageSource"], "LOCAL_LIBRARY")
        self.assertEqual(t2["imageReviewStatus"], "APPROVED")
        self.assertTrue("lemongrass" in t2["storagePath"])

        # Tier 3: External licensed candidate (must NOT be automatically approved)
        candidates = {
            "exotic fruit": {
                "url": "https://images.example.com/fruit.jpg",
                "path": "candidates/fruit.jpg",
                "license": "CC-BY-4.0",
            }
        }
        t3 = resolve_ingredient_image("Exotic Fruit", db_images={}, candidate_library=candidates)
        self.assertEqual(t3["tier"], 3)
        self.assertEqual(t3["imageSource"], "LICENSED_EXTERNAL")
        self.assertEqual(t3["imageReviewStatus"], "PENDING_REVIEW")

        # Tier 4: Unknown ingredient requires admin upload
        t4 = resolve_ingredient_image("Completely Unknown Wild Herb", db_images={})
        self.assertEqual(t4["tier"], 4)
        self.assertEqual(t4["imageSource"], "ADMIN_UPLOAD_REQUIRED")
        self.assertIsNone(t4["imageUrl"])
        self.assertEqual(t4["imageReviewStatus"], "PENDING_REVIEW")

    def test_enrich_recipe_detects_duplicate_ingredient_images(self):
        """Avoid duplicate ingredient images within the same recipe."""
        recipe = {
            "ingredients": [
                {"ingredientName": "Pork", "quantity": 300, "unit": "g"},
                {"ingredientName": "Pork Loin", "quantity": 200, "unit": "g"},
            ]
        }
        # Provide same image for both
        db_images = {
            "pork": "https://storage.example/pork.webp",
            "pork loin": "https://storage.example/pork.webp",
        }
        enrich_recipe_with_ingredient_images(recipe, db_images=db_images)
        self.assertFalse(recipe["ingredients"][0]["isDuplicateImage"])
        self.assertTrue(recipe["ingredients"][1]["isDuplicateImage"])

    @patch("scraper.ingredient_image_uploader.download_and_prepare_image")
    def test_uploads_each_external_ingredient_image_once_and_reuses_stored_url(self, download):
        class Response:
            ok = True
            def json(self):
                return {"imageUrl": "https://project.supabase.co/storage/v1/object/public/nhamhealth-images/ingredient-images/pork.webp"}

        download.return_value = __file__
        post = MagicMock(return_value=Response())
        recipe = {"ingredients": [
            {"ingredientName": "Pork", "imageUrl": "https://images.example/pork.jpg"},
            {"ingredientName": "Pork loin", "imageUrl": "https://images.example/pork.jpg"},
        ]}
        warnings = upload_recipe_ingredient_images(recipe, post=post, token_getter=lambda: "admin-token")

        self.assertEqual(warnings, [])
        self.assertEqual(post.call_count, 1)
        self.assertTrue(recipe["ingredients"][0]["imageUrl"].endswith("ingredient-images/pork.webp"))
        self.assertEqual(recipe["ingredients"][0]["imageUrl"], recipe["ingredients"][1]["imageUrl"])

    def test_estimated_nutrition_labels_correctly(self):
        """Nutrition estimation sets isNutritionEstimated=True and preserves values."""
        recipe = {
            "servings": 2,
            "ingredients": [
                {"ingredientName": "chicken breast", "quantity": 300, "unit": "g"},
                {"ingredientName": "jasmine rice", "quantity": 200, "unit": "g"},
            ],
        }
        estimate_recipe_nutrition(recipe)
        self.assertTrue(recipe["isNutritionEstimated"])
        self.assertEqual(recipe["nutritionSource"], "ESTIMATED_CALCULATED")
        self.assertGreater(recipe["calories"], 100)
        self.assertGreater(recipe["proteinGrams"], 10)

    def test_translation_qa_validation_statuses(self):
        """Test PASSED, NEEDS_REVIEW, and FAILED validation outputs."""
        # Valid recipe
        valid_recipe = {
            "translations": {
                "en": {
                    "mealName": "Bai Sach Chrouk",
                    "description": "Grilled pork with broken rice",
                    "category": "Breakfast",
                    "ingredients": [{"name": "pork", "quantity": 200, "unit": "g"}],
                    "steps": ["Grill the marinated pork."],
                },
                "km": {
                    "mealName": "បាយសាច់ជ្រូក",
                    "description": "សាច់ជ្រូកអាំងជាមួយបាយ",
                    "category": "អាហារពេលព្រឹក",
                    "ingredients": [{"name": "សាច់ជ្រូក", "quantity": 200, "unit": "g"}],
                    "steps": ["អាំងសាច់ជ្រូកដែលបានប្រឡាក់។"],
                },
            }
        }
        res_pass = comprehensive_validate_translation(valid_recipe)
        self.assertEqual(res_pass.status, "PASSED")
        self.assertTrue(res_pass.is_valid)

        # Quantity mismatch -> FAILED
        mismatched_recipe = {
            "translations": {
                "en": {
                    "mealName": "Fish Amok",
                    "ingredients": [{"name": "fish", "quantity": 500, "unit": "g"}],
                    "steps": ["Steam the fish."],
                },
                "km": {
                    "mealName": "អាម៉ុកត្រី",
                    "ingredients": [{"name": "ត្រី", "quantity": 250, "unit": "g"}],  # altered
                    "steps": ["ចំហុយត្រី។"],
                },
            }
        }
        res_fail = comprehensive_validate_translation(mismatched_recipe)
        self.assertEqual(res_fail.status, "FAILED")
        self.assertTrue(any("quantity modified" in issue for issue in res_fail.issues))
        self.assertTrue(res_fail.can_retry)

    def test_recipe_content_hash_consistency(self):
        """Test hash generation incorporates content, glossary version, and translation version."""
        recipe_a = {"mealName": "Fish Amok", "ingredients": [], "steps": []}
        recipe_b = {"mealName": "Fish Amok", "ingredients": [], "steps": []}
        recipe_c = {"mealName": "Bai Sach Chrouk", "ingredients": [], "steps": []}

        hash_a = compute_recipe_hash(recipe_a, glossary_version="2.0", translation_version="2.0")
        hash_b = compute_recipe_hash(recipe_b, glossary_version="2.0", translation_version="2.0")
        hash_c = compute_recipe_hash(recipe_c, glossary_version="2.0", translation_version="2.0")

        self.assertEqual(hash_a, hash_b)
        self.assertNotEqual(hash_a, hash_c)


if __name__ == "__main__":
    unittest.main()
