import unittest
from unittest.mock import patch

from translators.culinary_glossary import (
    INGREDIENTS,
    PREPARATION_NOTES,
    COOKING_ACTIONS,
    DISH_NAMES,
)
from translators.khmer_translator import KhmerTranslator
from translators.translation_cache import translation_cache
from translators.validator import validate_translation, contains_khmer


class KhmerTranslatorTests(unittest.TestCase):
    def setUp(self):
        self.translator = KhmerTranslator()
        # Ensure base tests test offline glossary & fallback by default
        self.translator.gemini_api_key = ""
        translation_cache._cache = {}
        self.sample_recipe = {
            "mealName": "Fish Amok",
            "description": "Traditional Cambodian steamed fish curry",
            "categoryName": "Lunch",
            "servings": 4,
            "cookingTimeMinutes": 20,
            "calories": None,
            "proteinGrams": None,
            "carbohydrateGrams": None,
            "fatGrams": None,
            "calories": 420,
            "proteinGrams": 28,
            "carbohydrateGrams": 18,
            "fatGrams": 25,
            "ingredients": [
                {
                    "ingredientName": "chicken breast",
                    "quantity": 300,
                    "unit": "g",
                    "preparationNote": "chop finely",
                    "displayOrder": 1,
                },
                {
                    "ingredientName": "fish sauce",
                    "quantity": 2,
                    "unit": "tbsp",
                    "preparationNote": None,
                    "displayOrder": 2,
                },
            ],
            "steps": [
                {"stepNumber": 1, "instruction": "Mix the fish with the curry paste."},
                {"stepNumber": 2, "instruction": "Steam for 20 minutes."},
            ],
        }

    def test_natural_culinary_terms_in_glossary(self):
        """Verify requirement 5: Khmer food and cooking terms sound natural."""
        self.assertEqual(INGREDIENTS["chicken breast"], "សាច់ទ្រូងមាន់")
        self.assertEqual(INGREDIENTS["fish sauce"], "ទឹកត្រី")
        self.assertEqual(INGREDIENTS["garlic"], "ខ្ទឹមស")
        self.assertEqual(INGREDIENTS["carrot"], "ការ៉ុត")
        self.assertEqual(INGREDIENTS["coconut milk"], "ខ្ទិះដូង")
        self.assertEqual(PREPARATION_NOTES["chop finely"], "ហាន់ឲ្យម៉ត់")
        self.assertEqual(COOKING_ACTIONS["boil"], "ស្ងោរ")
        self.assertEqual(COOKING_ACTIONS["fry"], "ចៀន")
        self.assertEqual(COOKING_ACTIONS["steam"], "ចំហុយ")
        self.assertEqual(COOKING_ACTIONS["grill"], "អាំង")
        self.assertEqual(COOKING_ACTIONS["mix well"], "លាយឲ្យសព្វ")

    def test_translate_dish_name(self):
        """Dish names like Fish Amok or Bai Sach Chrouk translate properly."""
        self.assertEqual(self.translator.translate_meal_name("Fish Amok"), "អាម៉ុកត្រី")
        self.assertEqual(self.translator.translate_meal_name("Bai Sach Chrouk"), "បាយសាច់ជ្រូក")

    def test_translate_preserves_quantities_and_units(self):
        """Verify requirements 3 & 4: 300 g chicken breast -> 300 g សាច់ទ្រូងមាន់."""
        translated = self.translator.translate(dict(self.sample_recipe))
        km = translated["translations"]["km"]

        first_ing = km["ingredients"][0]
        self.assertEqual(first_ing["quantity"], 300)
        self.assertEqual(first_ing["unit"], "g")
        self.assertEqual(first_ing["name"], "សាច់ទ្រូងមាន់")
        self.assertEqual(first_ing["note"], PREPARATION_NOTES["chop finely"])

        second_ing = km["ingredients"][1]
        self.assertEqual(second_ing["quantity"], 2)
        self.assertEqual(second_ing["unit"], "tbsp")
        self.assertEqual(second_ing["name"], "ទឹកត្រី")

    def test_output_json_structure(self):
        """Verify requirement 2: Output contains translations.en, translations.km, nutrition."""
        translated = self.translator.translate(dict(self.sample_recipe))

        self.assertIn("translations", translated)
        self.assertIn("en", translated["translations"])
        self.assertIn("km", translated["translations"])
        self.assertIn("nutrition", translated)

        en = translated["translations"]["en"]
        km = translated["translations"]["km"]

        self.assertEqual(en["mealName"], "Fish Amok")
        self.assertEqual(km["mealName"], "អាម៉ុកត្រី")
        self.assertEqual(translated["khmerName"], "អាម៉ុកត្រី")

        self.assertEqual(len(en["ingredients"]), 2)
        self.assertEqual(len(km["ingredients"]), 2)
        self.assertEqual(len(en["steps"]), 2)
        self.assertEqual(len(km["steps"]), 2)

    def test_caching_and_skip_logic(self):
        """Verify requirement 11: If recipe has valid Khmer translation, do not re-translate."""
        recipe = dict(self.sample_recipe)
        recipe["translationStatus"] = "COMPLETED"
        recipe["translations"] = {
            "en": {"mealName": "Fish Amok", "ingredients": [], "steps": []},
            "km": {
                "mealName": "អាម៉ុកត្រី",
                "ingredients": [],
                "steps": [],
            },
        }

        with patch.object(self.translator, "_translate_to_khmer") as mock_translate:
            result = self.translator.translate(recipe, force=False)
            mock_translate.assert_not_called()
            self.assertEqual(result["translations"]["km"]["mealName"], "អាម៉ុកត្រី")

    def test_force_retranslation(self):
        """Force=True retranslates even if already COMPLETED."""
        recipe = dict(self.sample_recipe)
        recipe["translationStatus"] = "COMPLETED"
        recipe["translations"] = {
            "en": {"mealName": "Fish Amok", "ingredients": [], "steps": []},
            "km": {
                "mealName": "អាម៉ុកត្រី",
                "ingredients": [],
                "steps": [],
            },
        }

        with patch.object(self.translator, "_translate_to_khmer", return_value={"mealName": "អាម៉ុកត្រីថ្មី", "ingredients": [], "steps": []}) as mock_translate:
            result = self.translator.translate(recipe, force=True)
            mock_translate.assert_called_once()
            self.assertEqual(result["translations"]["km"]["mealName"], "អាម៉ុកត្រីថ្មី")

    def test_translation_validation(self):
        """Verify validation of translated recipe."""
        recipe = {
            "translations": {
                "en": {
                    "mealName": "Fish Amok",
                    "description": "Steamed curry",
                    "category": "Lunch",
                    "ingredients": [{"name": "fish", "quantity": 100, "unit": "g"}],
                    "steps": ["Steam the fish."],
                },
                "km": {
                    "mealName": "អាម៉ុកត្រី",
                    "description": "ការីចំហុយ",
                    "category": "អាហារពេលថ្ងៃត្រង់",
                    "ingredients": [{"name": "ត្រី", "quantity": 100, "unit": "g"}],
                    "steps": ["ចំហុយត្រី។"],
                },
            }
        }
        is_valid, err = validate_translation(recipe)
        self.assertTrue(is_valid)
        self.assertIsNone(err)

        # Quantity change causes failure
        recipe["translations"]["km"]["ingredients"][0]["quantity"] = 200
        is_valid, err = validate_translation(recipe)
        self.assertFalse(is_valid)
        self.assertIn("quantity modified", err)

        # Missing Khmer category causes failure
        recipe["translations"]["km"]["ingredients"][0]["quantity"] = 100
        recipe["translations"]["km"]["category"] = ""
        is_valid, err = validate_translation(recipe)
        self.assertFalse(is_valid)
        self.assertIn("category", err)

    def test_graceful_error_fallback(self):
        """Verify requirement 6: Failure keeps English, sets translationStatus='FAILED'."""
        recipe = dict(self.sample_recipe)
        with patch.object(self.translator, "_translate_to_khmer", side_effect=RuntimeError("Network offline")):
            result = self.translator.translate(recipe)
            self.assertEqual(result["translationStatus"], "FAILED")
            self.assertEqual(result["translationError"], "Network offline")
            self.assertIsNone(result["translations"]["km"])
            self.assertEqual(result["translations"]["en"]["mealName"], "Fish Amok")

    def test_gemini_recipe_translation_success(self):
        """Verify Gemini structured recipe translation parses and preserves quantities."""
        self.translator.gemini_api_key = "fake-gemini-key"
        gemini_mock_response = {
            "candidates": [
                {
                    "content": {
                        "parts": [
                            {
                                "text": (
                                    '{\n'
                                    '  "mealName": "អាម៉ុកត្រី",\n'
                                    '  "description": "ការីត្រីចំហុយបុរាណខ្មែរ",\n'
                                    '  "category": "អាហារថ្ងៃត្រង់",\n'
                                    '  "ingredients": [\n'
                                    '    {"name": "សាច់ទ្រូងមាន់", "note": "ហាន់ឱ្យម៉ត់"},\n'
                                    '    {"name": "ទឹកត្រី", "note": null}\n'
                                    '  ],\n'
                                    '  "steps": [\n'
                                    '    "ច្របល់ត្រីជាមួយគ្រឿងការីឱ្យសព្វ។",\n'
                                    '    "ចំហុយរយៈពេល ២០ នាទី។"\n'
                                    '  ],\n'
                                    '  "tags": ["ម្ហូបខ្មែរ"]\n'
                                    '}'
                                )
                            }
                        ]
                    }
                }
            ]
        }

        mock_resp = unittest.mock.MagicMock()
        mock_resp.ok = True
        mock_resp.status_code = 200
        mock_resp.json.return_value = gemini_mock_response

        with patch.object(self.translator.session, "post", return_value=mock_resp):
            result = self.translator.translate(dict(self.sample_recipe))

        self.assertEqual(result["translationStatus"], "COMPLETED")
        self.assertEqual(result["translations"]["km"]["mealName"], "អាម៉ុកត្រី")
        self.assertEqual(result["translations"]["km"]["category"], "អាហារថ្ងៃត្រង់")
        self.assertEqual(len(result["translations"]["km"]["ingredients"]), 2)
        # Verify strict preservation of quantities and units
        self.assertEqual(result["translations"]["km"]["ingredients"][0]["quantity"], 300)
        self.assertEqual(result["translations"]["km"]["ingredients"][0]["unit"], "g")
        self.assertEqual(result["translations"]["km"]["ingredients"][0]["name"], "សាច់ទ្រូងមាន់")
        self.assertEqual(result["translations"]["km"]["ingredients"][1]["quantity"], 2)
        self.assertEqual(result["translations"]["km"]["ingredients"][1]["unit"], "tbsp")

    def test_gemini_fallback_on_error(self):
        """Verify fallback to standard translation if Gemini returns an error."""
        self.translator.gemini_api_key = "fake-gemini-key"
        mock_resp = unittest.mock.MagicMock()
        mock_resp.ok = False
        mock_resp.status_code = 429
        mock_resp.text = "Quota exceeded"

        fallback_result = {
            "mealName": "អាម៉ុកត្រី",
            "description": "ការីត្រី",
            "category": "អាហារថ្ងៃត្រង់",
            "ingredients": [
                {"name": "សាច់ទ្រូងមាន់", "quantity": 300, "unit": "g", "note": "ហាន់ឱ្យម៉ត់"},
                {"name": "ទឹកត្រី", "quantity": 2, "unit": "tbsp", "note": None},
            ],
            "steps": ["ចំហុយត្រី។", "ទទួលទាន។"],
            "tags": [],
        }

        with patch.object(self.translator.session, "post", return_value=mock_resp):
            with patch.object(self.translator, "_translate_to_khmer", return_value=fallback_result) as mock_fallback:
                result = self.translator.translate(dict(self.sample_recipe))
                mock_fallback.assert_called_once()
                self.assertEqual(result["translationStatus"], "COMPLETED")
                self.assertEqual(result["translations"]["km"]["mealName"], "អាម៉ុកត្រី")

    def test_gemini_single_text_translation(self):
        """Verify _translate_gemini_text translates individual phrases."""
        self.translator.gemini_api_key = "fake-gemini-key"
        mock_resp = unittest.mock.MagicMock()
        mock_resp.ok = True
        mock_resp.status_code = 200
        mock_resp.json.return_value = {
            "candidates": [
                {"content": {"parts": [{"text": "បុកល្ហុង"}]}}
            ]
        }

        with patch.object(self.translator.session, "post", return_value=mock_resp):
            res = self.translator._translate_gemini_text("green papaya salad")
            self.assertEqual(res, "បុកល្ហុង")


if __name__ == "__main__":
    unittest.main()

