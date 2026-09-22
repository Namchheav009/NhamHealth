import json
import unittest
from unittest.mock import Mock, patch

from scraper.ai_web_ingester import AiWebRecipeIngester
from scraper.normalizer import normalize_recipe


class AiWebIngesterTests(unittest.TestCase):
    def setUp(self):
        self.ingester = AiWebRecipeIngester(api_key="test-key", model="test-model")
        self.recipe = {
            "mealName": "Banana smoothie", "categoryName": "Beverages", "servings": 2,
            "ingredients": [{"ingredientName": "Banana", "quantity": 1, "unit": "piece", "displayOrder": 1}],
            "steps": [{"stepNumber": 1, "instruction": "Blend banana with water."}],
            "nutritionBasis": "UNKNOWN", "calories": None, "proteinGrams": None,
        }
        ai_response = {"candidates": [{"content": {"parts": [{"text": json.dumps(self.recipe)}]}}]}
        self.ingester.session.post = Mock(return_value=Mock(json=Mock(return_value=ai_response)))

    @patch("scraper.ai_web_ingester.socket.getaddrinfo",
           return_value=[(2, 1, 6, "", ("93.184.216.34", 0))])
    def test_web_recipe_keeps_real_source_and_normalizes_for_import(self, _dns):
        html = ("<html><head><meta property='og:image' content='/smoothie.webp'></head><body>"
                "<h1>Banana smoothie</h1><p>Blend one banana with water and ice. "
                "Serve this cold drink after breakfast with a small snack.</p></body></html>")
        response = Mock(content=html.encode(), text=html, headers={"Content-Type": "text/html"},
                        is_redirect=False, status_code=200)
        self.ingester.session.get = Mock(return_value=response)

        recipe = normalize_recipe(self.ingester.extract_from_url("https://recipes.example/smoothie"))

        self.assertEqual(recipe["sourceUrl"], "https://recipes.example/smoothie")
        self.assertEqual(recipe["sourceImageUrl"], "https://recipes.example/smoothie.webp")
        self.assertIsNotNone(recipe["scrapedAt"])
        self.assertFalse(recipe["published"])

    def test_rejects_private_url_before_fetch(self):
        self.ingester.session.get = Mock()
        with self.assertRaises(ValueError):
            self.ingester.extract_from_url("http://127.0.0.1/admin")
        self.ingester.session.get.assert_not_called()

    def test_rejects_documentation_placeholder_with_actionable_message(self):
        self.ingester.session.get = Mock()
        with self.assertRaisesRegex(ValueError, "documentation placeholder"):
            self.ingester.extract_from_url("https://example.com/recipe")
        self.ingester.session.get.assert_not_called()

    @patch("scraper.ai_web_ingester.socket.getaddrinfo",
           return_value=[(2, 1, 6, "", ("93.184.216.34", 0))])
    def test_http_404_explains_that_a_direct_recipe_url_is_required(self, _dns):
        response = Mock(headers={"Content-Type": "text/html"}, is_redirect=False, status_code=404)
        self.ingester.session.get = Mock(return_value=response)
        with self.assertRaisesRegex(ValueError, "direct URL to a real recipe page"):
            self.ingester.extract_from_url("https://recipes.example/does-not-exist")

    def test_generated_topics_have_distinct_provenance(self):
        first = self.ingester.parse_with_ai("banana drink")
        second = self.ingester.parse_with_ai("ginger tea")
        self.assertNotEqual(first["sourceUrl"], second["sourceUrl"])
        self.assertEqual(first["sourceName"], "AI-generated recipe")

    def test_normalizer_keeps_complete_khmer_recipe(self):
        self.recipe.update(
            khmerName="ទឹកក្រឡុកចេក", categoryNameKm="ភេសជ្ជៈ",
            description="A banana drink.", descriptionKm="ភេសជ្ជៈផ្លែចេក។",
        )
        self.recipe["ingredients"][0]["ingredientNameKm"] = "ផ្លែចេក"
        self.recipe["steps"][0]["instructionKm"] = "ក្រឡុកចេកជាមួយទឹក។"

        normalized = normalize_recipe(self.recipe)

        self.assertEqual(normalized["translationStatus"], "COMPLETED")
        self.assertEqual(normalized["translations"]["km"]["ingredients"][0]["name"], "ផ្លែចេក")


if __name__ == "__main__":
    unittest.main()
