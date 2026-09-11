import argparse
import json
import sys
import time
from pathlib import Path

# Keep paths stable when launched from the workspace or VS Code.
ROOT = Path(__file__).resolve().parent
import os
os.chdir(ROOT)

from scraper.config import settings
from scraper.exporter import save_json
from scraper.image_downloader import download_and_prepare_image, prepare_local_image
from scraper.importer import import_recipe
from scraper.normalizer import normalize_recipe
from scraper.recipe_detail import scrape_recipe
from scraper.recipe_list import get_recipe_links
from scraper.validator import validate_recipe
from translators import khmer_translator, validate_translation


def review_output_path(input_path: Path | None) -> Path:
    if input_path is None:
        return Path("output/normalized_recipes.json")
    output = Path("output/reviewed_recipes.json")
    if input_path.resolve() == output.resolve():
        output = Path("output/validated_recipes.json")
    return output


def scrape_one(url: str, download_image: bool = True):
    raw = scrape_recipe(url)
    if download_image and raw.get("sourceImageUrl"):
        try:
            raw["localImagePath"] = download_and_prepare_image(raw["sourceImageUrl"], raw["mealName"])
        except Exception as exc:
            raw["localImagePath"] = None
            raw["imageDownloadError"] = str(exc)
    return raw, normalize_recipe(raw)


def approve_flagged_ingredients(recipe: dict) -> int:
    """Explicitly acknowledge all parser review flags in one recipe."""
    approved = 0
    for ingredient in recipe.get("ingredients") or []:
        if ingredient.get("needsReview"):
            ingredient["needsReview"] = False
            approved += 1
    return approved


def print_import_result(result: dict) -> None:
    """Show whether the API inserted a recipe or safely skipped a duplicate."""
    meal_name = result.get("mealName") or "Recipe"
    if result.get("skipped"):
        print(f"  SKIPPED (already exists): {meal_name}")
        return
    meal_id = result.get("mealId") or result.get("id")
    suffix = f" (meal ID {meal_id})" if meal_id is not None else ""
    print(f"  ADDED: {meal_name}{suffix}")


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Scrape, review and import NhamHealth recipes.")
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--url", help="Scrape one recipe URL.")
    source.add_argument("--all", action="store_true", help="Scrape the recipe index.")
    source.add_argument("--input", type=Path, help="Validate/import saved JSON without scraping again.")
    parser.add_argument("--limit", type=int, default=settings.max_recipes)
    parser.add_argument("--skip", type=int, default=0,
                        help="Skip recipes already processed at the start of an --all or --input batch.")
    parser.add_argument(
        "--no-image",
        action="store_true",
        help="Skip image download; drafts may be imported without a photo.",
    )
    parser.add_argument("--image-file", help="Real JPG/PNG/WebP photo for a single recipe.")
    parser.add_argument("--import-api", action="store_true", help="Send reviewed data to the admin import endpoint.")
    parser.add_argument(
        "--approve-flagged",
        action="store_true",
        help="Acknowledge all flagged ingredient parses in the selected batch before importing.",
    )
    parser.add_argument(
        "--retranslate",
        action="store_true",
        help="Force retranslation to Khmer even if already translated.",
    )
    args = parser.parse_args()
    if args.limit < 1:
        parser.error("--limit must be positive")
    if args.skip < 0:
        parser.error("--skip cannot be negative")
    if args.url and args.skip:
        parser.error("--skip is only supported with --all or --input")
    if args.image_file and args.all:
        parser.error("--image-file is only supported for a single recipe")

    raw_recipes, normalized_recipes, results = [], [], []
    failed = False
    try:
        if args.input:
            saved = json.loads(args.input.read_text(encoding="utf-8-sig"))
            recipes = saved if isinstance(saved, list) else [saved]
            if not recipes or not all(isinstance(r, dict) for r in recipes):
                raise ValueError("Input must contain recipe objects.")
            if args.image_file and len(recipes) != 1:
                parser.error("--image-file requires exactly one saved recipe")
            work = recipes[args.skip:]
        else:
            work = [args.url] if args.url else get_recipe_links()[args.skip:args.skip + args.limit]
            if not work:
                raise ValueError("No recipe URLs found.")
    except (ValueError, OSError) as exc:
        print("FAILED:", exc)
        return 1

    for index, item in enumerate(work, 1):
        print(f"[{index}/{len(work)}] {'Reviewing saved recipe' if args.input else 'Scraping: ' + item}")
        try:
            if args.input:
                recipe = item
            else:
                raw, recipe = scrape_one(item, download_image=not args.no_image and not args.image_file)
                raw_recipes.append(raw)
                save_json(raw_recipes, "output/raw_recipes.json")
            if args.image_file:
                recipe["localImagePath"] = prepare_local_image(args.image_file, recipe["mealName"])
                recipe["imageDownloadError"] = None
            if args.approve_flagged:
                approved = approve_flagged_ingredients(recipe)
                if approved:
                    print(f"  APPROVED: {approved} flagged ingredient parse(s).")
            recipe["published"] = False
            recipe["reviewStatus"] = "PENDING_REVIEW"
            errors, warnings = validate_recipe(recipe, require_image=False)
            recipe["validationErrors"], recipe["validationWarnings"] = errors, warnings

            # Translate normalized text EN -> KM
            khmer_translator.translate(recipe, force=args.retranslate)
            is_valid_trans, trans_err = validate_translation(recipe)
            if not is_valid_trans and recipe.get("translationStatus") != "FAILED":
                recipe["translationStatus"] = "FAILED"
                recipe["translationError"] = trans_err

            normalized_recipes.append(recipe)
            # Preserve hand-edited input files; emit validation into a separate artifact.
            destination = review_output_path(args.input)
            save_json(normalized_recipes, destination)
            for warning in warnings:
                print("  WARNING:", warning)
            if errors:
                failed = True
                for error in errors:
                    print("  ERROR:", error)
                continue

            image_status = "OK" if recipe.get("localImagePath") else "Missing"
            trans_status = (
                "OK"
                if recipe.get("translationStatus") == "COMPLETED"
                else f"FAILED ({recipe.get('translationError')})"
            )
            cal = recipe.get("calories")
            pro = recipe.get("proteinGrams")
            carb = recipe.get("carbohydrateGrams")
            fat = recipe.get("fatGrams")
            nutr_str = f"{cal} kcal · {pro}g protein · {carb}g carbs · {fat}g fat (per serving)"
            print(f"\n{recipe.get('mealName')}")
            print("- Scrape: OK")
            print(f"- Ingredients: {len(recipe.get('ingredients') or [])}")
            print(f"- Steps: {len(recipe.get('steps') or [])}")
            print(f"- Nutrition: {nutr_str}")
            print("- English: OK")
            print(f"- Khmer translation: {trans_status}")
            print(f"- Image: {image_status}")
            print(f"- Saved: {destination}")

            if args.import_api:
                result = import_recipe(recipe)
                results.append(result)
                save_json(results, "output/import_results.json")
                print_import_result(result)
            else:
                print("  JSON saved for review. Resolve flagged ingredients before import; photos can be added to drafts later.")
        except Exception as exc:
            failed = True
            print("  FAILED:", exc)
        if not args.input and index < len(work):
            time.sleep(settings.request_delay_seconds)
    if failed:
        print("Finished with errors. See the messages above.")
    elif args.import_api:
        added = sum(not result.get("skipped") for result in results)
        skipped = sum(bool(result.get("skipped")) for result in results)
        print(f"Import finished: {added} added, {skipped} already existed and were skipped.")
    else:
        print("Finished. JSON saved for review; no database import was requested.")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
