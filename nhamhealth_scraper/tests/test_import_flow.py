import json
import uuid
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch, Mock
from PIL import Image
from scraper.validator import validate_recipe
from scraper.importer import import_recipe
from scraper.image_downloader import _rasterize_svg
from scraper.normalizer import split_instruction


class ImportFlowTests(unittest.TestCase):
    def setUp(self):
        self.image = Path(__file__).resolve().parents[1] / "output" / f"test-{uuid.uuid4()}.webp"
        self.addCleanup(lambda: self.image.unlink(missing_ok=True))
        Image.new("RGB", (10, 10)).save(self.image, "WEBP")
        self.recipe = {
            "mealName": "Test meal", "categoryName": "Breakfast", "servings": 4,
            "mealName": "Test meal", "categoryName": "Breakfast", "categoryNameKm": "អាហារពេលព្រឹក",
            "calories": 400, "proteinGrams": 20, "servings": 4,
            "difficulty": "EASY", "nutritionBasis": "UNKNOWN", "localImagePath": str(self.image),
            "sourceName": "Test source", "sourceLanguage": "en", "sourceUrl": "https://example.com/recipe",
            "scrapedAt": "2026-09-08T00:00:00Z",
            "ingredients": [{"ingredientName": "Pork", "quantity": 600, "unit": "g", "displayOrder": 1}],
            "steps": [{"stepNumber": 1, "instruction": "Cook the ingredients."}],
        }

    def test_missing_image_and_steps_are_errors(self):
        self.recipe.update(localImagePath=None, steps=[])
        errors, _ = validate_recipe(self.recipe)
        self.assertTrue(any("photo" in error for error in errors))
        self.assertTrue(any("step" in error for error in errors))

    def test_draft_without_photo_sends_recipe_multipart_only(self):
        self.recipe["localImagePath"] = None
        response = Mock(ok=True, content=b"{}")
        response.json.return_value = {"mealId": 7, "published": False}
        with patch("scraper.importer.settings", SimpleNamespace(spring_import_token="test-token", spring_import_url="http://localhost/import")), \
                patch("scraper.importer.requests.post", return_value=response) as post:
            self.assertFalse(import_recipe(self.recipe)["published"])
            self.assertEqual({"recipe"}, set(post.call_args.kwargs["files"]))


    def test_missing_servings_and_invalid_quantity_are_errors(self):
        self.recipe["servings"] = None
        self.recipe["ingredients"][0]["quantity"] = -1
        errors, _ = validate_recipe(self.recipe)
        self.assertEqual(2, len(errors))

    def test_flagged_ingredients_never_reach_api(self):
        self.recipe["ingredients"][0]["needsReview"] = True
        with patch("scraper.importer.requests.post") as post:
            with self.assertRaisesRegex(ValueError, "flagged"):
                import_recipe(self.recipe)
            post.assert_not_called()

    def test_stale_validation_results_are_not_trusted(self):
        self.recipe.update(validationErrors=[], servings=0)
        with patch("scraper.importer.requests.post") as post:
            with self.assertRaises(ValueError):
                import_recipe(self.recipe)
            post.assert_not_called()

    def test_multipart_preserves_unknown_nutrition_and_forces_draft(self):
    def test_multipart_preserves_nutrition_and_forces_draft(self):
        self.recipe.update(published=True, reviewStatus="APPROVED")
        response = Mock(ok=True, content=b"{}")
        response.json.return_value = {"mealId": 7}
        with patch("scraper.importer.settings", SimpleNamespace(spring_import_token="test-token", spring_import_url="http://localhost/import")), \
                patch("scraper.importer.requests.post", return_value=response) as post:
            self.assertEqual({"mealId": 7}, import_recipe(self.recipe))
            files = post.call_args.kwargs["files"]
            payload = json.loads(files["recipe"][1])
            self.assertFalse(payload["published"])
            self.assertEqual("PENDING_REVIEW", payload["reviewStatus"])
            self.assertIsNone(payload["calories"])
            self.assertEqual(400, payload["calories"])
            self.assertEqual(20, payload["proteinGrams"])
            self.assertEqual("អាហារពេលព្រឹក", payload["categoryNameKm"])
            self.assertEqual("image/webp", files["image"][2])
            self.assertTrue(files["image"][1].closed)

    def test_missing_calories_and_protein_are_errors(self):
        self.recipe["calories"] = None
        self.recipe["proteinGrams"] = None
        errors, _ = validate_recipe(self.recipe)
        self.assertTrue(any("calories" in error for error in errors))
        self.assertTrue(any("proteinGrams" in error for error in errors))

    def test_api_validation_message_is_visible(self):
        response = Mock(ok=False, status_code=400)
        response.json.return_value = {"message": "Unknown ingredient: Pork"}
        with patch("scraper.importer.settings", SimpleNamespace(spring_import_token="test-token", spring_import_url="http://localhost/import")), \
                patch("scraper.importer.requests.post", return_value=response):
            with self.assertRaisesRegex(RuntimeError, "Unknown ingredient: Pork"):
                import_recipe(self.recipe)

    def test_duplicate_import_is_an_idempotent_skip(self):
        response = Mock(ok=False, status_code=409)
        with patch("scraper.importer.settings", SimpleNamespace(spring_import_token="test-token", spring_import_url="http://localhost/import")), \
                patch("scraper.importer.requests.post", return_value=response):
            result = import_recipe(self.recipe)
        self.assertTrue(result["skipped"])
        self.assertEqual("Test meal", result["mealName"])

    def test_missing_token_logs_in_once_and_uses_admin_access_token(self):
        login = Mock(ok=True, status_code=200)
        login.json.return_value = {
            "accessToken": "fresh-admin-token",
            "user": {"role": "ADMIN"},
        }
        imported = Mock(ok=True, status_code=201, content=b"{}")
        imported.json.return_value = {"mealId": 7, "published": False}
        configured = SimpleNamespace(
            spring_import_token="",
            spring_import_url="http://localhost/import",
            spring_admin_login_url="http://localhost/login",
            spring_admin_email="admin@example.com",
            spring_admin_password="secret",
            request_timeout_seconds=10,
        )
        with patch("scraper.importer.settings", configured), \
                patch("scraper.importer._cached_import_token", None), \
                patch("scraper.importer.requests.post", side_effect=[login, imported]) as post:
            self.assertEqual(7, import_recipe(self.recipe)["mealId"])
            self.assertEqual(
                {"email": "admin@example.com", "password": "secret"},
                post.call_args_list[0].kwargs["json"],
            )
            self.assertEqual(
                "Bearer fresh-admin-token",
                post.call_args_list[1].kwargs["headers"]["Authorization"],
            )

    def test_missing_all_auth_configuration_has_actionable_error(self):
        configured = SimpleNamespace(
            spring_import_token="",
            spring_admin_email="",
            spring_admin_password="",
        )
        with patch("scraper.importer.settings", configured), \
                patch("scraper.importer._cached_import_token", None), \
                patch("scraper.importer.requests.post") as post:
            with self.assertRaisesRegex(ValueError, "SPRING_ADMIN_EMAIL"):
                import_recipe(self.recipe)
            post.assert_not_called()

    def test_svg_cannot_silently_become_a_meal_photo(self):
        with self.assertRaisesRegex(ValueError, "photograph"):
            _rasterize_svg(b"<svg/>")

    def test_reviewed_input_is_never_overwritten_during_import(self):
        from main import review_output_path
        source = Path("output/reviewed_recipes.json")
        self.assertNotEqual(source.resolve(), review_output_path(source).resolve())
        self.assertEqual(Path("output/reviewed_recipes.json"),
                         review_output_path(Path("output/normalized_recipes.json")))

    def test_explicit_approval_clears_only_flagged_ingredients(self):
        from main import approve_flagged_ingredients
        recipe = {
            "ingredients": [
                {"ingredientName": "Mango", "needsReview": True},
                {"ingredientName": "Salt", "needsReview": False},
            ]
        }
        self.assertEqual(1, approve_flagged_ingredients(recipe))
        self.assertFalse(any(item["needsReview"] for item in recipe["ingredients"]))

    def test_long_instructions_are_split_without_losing_text(self):
        instruction = (
            "Steam the rice until every grain is glossy and tender. "
            + "Keep the water boiling steadily while the covered basket cooks. "
        ) * 4
        chunks = split_instruction(instruction)
        self.assertGreater(len(chunks), 1)
        self.assertTrue(all(0 < len(chunk) <= 255 for chunk in chunks))
        self.assertEqual(" ".join(instruction.split()), " ".join(chunks))


if __name__ == "__main__":
    unittest.main()
