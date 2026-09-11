import unittest
from scraper.nutrition_estimator import (
    estimate_ingredient_weight_grams,
    estimate_recipe_nutrition,
    find_closest_nutrient_profile,
    is_non_edible,
)


class TestNutritionEstimator(unittest.TestCase):

    def test_non_edible_filtering(self):
        self.assertTrue(is_non_edible("bamboo skewers"))
        self.assertTrue(is_non_edible("sections green bamboo tube"))
        self.assertTrue(is_non_edible("banana leaf to wrap"))
        self.assertFalse(is_non_edible("chicken thigh"))
        self.assertFalse(is_non_edible("pork shoulder"))

    def test_unit_conversions(self):
        # 600 grams
        self.assertEqual(600.0, estimate_ingredient_weight_grams("chicken", 600, "g"))
        # 1 kg -> 1000g
        self.assertEqual(1000.0, estimate_ingredient_weight_grams("pork", 1, "kg"))
        # 2 tbsp -> 30g
        self.assertEqual(30.0, estimate_ingredient_weight_grams("fish sauce", 2, "tbsp"))
        # 1 tsp -> 5g
        self.assertEqual(5.0, estimate_ingredient_weight_grams("sugar", 1, "tsp"))
        # 4 garlic cloves -> 14g
        self.assertEqual(14.0, estimate_ingredient_weight_grams("garlic", 4, "clove"))
        # Bamboo skewer -> 0g
        self.assertEqual(0.0, estimate_ingredient_weight_grams("bamboo skewer", 2, "piece"))

    def test_estimate_recipe_nutrition_macro_accuracy(self):
        recipe = {
            "mealName": "Chicken Cooked in Bamboo Tubes",
            "servings": 4,
            "ingredients": [
                {"ingredientName": "chicken thigh", "quantity": 600.0, "unit": "g"},
                {"ingredientName": "lemongrass", "quantity": 3.0, "unit": "stalk"},
                {"ingredientName": "garlic", "quantity": 6.0, "unit": "clove"},
                {"ingredientName": "fish sauce", "quantity": 2.0, "unit": "tbsp"},
                {"ingredientName": "palm sugar", "quantity": 1.0, "unit": "tsp"},
                {"ingredientName": "bamboo tube", "quantity": 2.0, "unit": "piece"},
            ],
        }

        result = estimate_recipe_nutrition(recipe)

        self.assertGreater(result["calories"], 200)
        self.assertLess(result["calories"], 600)
        self.assertGreater(result["proteinGrams"], 25)
        self.assertEqual("PER_SERVING", recipe["nutritionBasis"])
        self.assertEqual(result["calories"], recipe["calories"])
        self.assertEqual(result["proteinGrams"], recipe["proteinGrams"])

    def test_empty_ingredients_fallback(self):
        recipe = {
            "mealName": "Mystery Meal",
            "servings": 2,
            "ingredients": [],
        }
        result = estimate_recipe_nutrition(recipe)
        self.assertIsNotNone(result["calories"])
        self.assertIsNotNone(result["proteinGrams"])


if __name__ == "__main__":
    unittest.main()

