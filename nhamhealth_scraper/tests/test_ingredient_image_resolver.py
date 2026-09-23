import unittest
from pathlib import Path
from unittest.mock import patch
from types import SimpleNamespace

from scraper.ingredient_image_resolver import canonical_ingredient_name, enrich_recipe_with_ingredient_images, resolve_ingredient_image


class IngredientImageResolverTests(unittest.TestCase):
    def test_canonical_examples(self):
        self.assertEqual(canonical_ingredient_name("2 limes".replace("2 ", "")), "Lime")
        self.assertEqual(canonical_ingredient_name("fresh ginger"), "Ginger")
        self.assertEqual(canonical_ingredient_name("red chillies"), "Red Chilli")
        self.assertEqual(canonical_ingredient_name("whole chicken leg quarter"), "Chicken")
        self.assertEqual(canonical_ingredient_name("thick coconut cream"), "Thick Coconut Cream")

    def test_cambodian_specific_ingredient_is_missing_without_substitution(self):
        result = resolve_ingredient_image("Prahok")
        self.assertEqual(result["status"], "MISSING")
        self.assertIsNone(result["imageUrl"])

    def test_cache_reuses_local_copy(self):
        directory = Path("output") / "_resolver_test"
        directory.mkdir(parents=True, exist_ok=True)
        cache_path = directory / "cache.json"
        if cache_path.exists():
            cache_path.unlink()
        with patch("scraper.ingredient_image_resolver.settings", SimpleNamespace(
                 ingredient_image_cache_file=str(directory / "cache.json"), ingredient_images_dir=str(directory)
             )), \
             patch("scraper.ingredient_image_resolver.download_and_prepare_image") as download:
            image = directory / "lime.webp"; image.write_bytes(b"ok")
            download.return_value = image.as_posix()
            first = resolve_ingredient_image("Lime")
            second = resolve_ingredient_image("Lime")
            self.assertEqual(first["status"], "DOWNLOADED")
            self.assertEqual(second["status"], "REUSED")
            self.assertEqual(download.call_count, 1)

    def test_recipe_does_not_mark_ambiguous_measurements_approved(self):
        recipe = {"ingredients": [{"ingredientName": "Prahok", "needsReview": True}]}
        enrich_recipe_with_ingredient_images(recipe)
        self.assertTrue(recipe["ingredients"][0]["needsReview"])


if __name__ == "__main__":
    unittest.main()
