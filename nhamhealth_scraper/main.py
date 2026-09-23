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


RECIPES_OUTPUT = Path("output/recipes.json")


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
    """Show whether the API inserted a recipe, safely skipped a duplicate, or failed."""
    meal_name = result.get("mealName") or "Recipe"
    if result.get("failed"):
        print(f"  FAILED: {result.get('error') or 'Import failed.'}")
    elif result.get("skipped"):
        reason = result.get("reason")
        reason_str = f" ({reason})" if reason else ""
        print(f"  SKIPPED (already exists): {meal_name}{reason_str}")
    else:
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

    processed_recipes, results = [], []
    seen_urls = set()
    has_failures = False
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
                if (
                    not args.no_image
                    and not args.image_file
                    and (not recipe.get("localImagePath") or not Path(recipe["localImagePath"]).is_file())
                    and recipe.get("sourceImageUrl")
                ):
                    try:
                        recipe["localImagePath"] = download_and_prepare_image(
                            recipe["sourceImageUrl"], recipe.get("mealName") or "meal"
                        )
                        recipe["imageUrl"] = recipe.get("sourceImageUrl") or recipe.get("localImagePath")
                        recipe["imageDownloadError"] = None
                    except Exception as exc:
                        recipe["imageDownloadError"] = str(exc)
            else:
                _, recipe = scrape_one(item, download_image=not args.no_image and not args.image_file)
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

            processed_recipes.append(recipe)
            for warning in warnings:
                print("  WARNING:", warning)
            if errors:
                has_failures = True
                for error in errors:
                    print("  ERROR:", error)
                continue

            image_status = "OK" if recipe.get("localImagePath") else "Missing"
            has_image = bool(recipe.get("localImagePath") and Path(recipe["localImagePath"]).is_file())
            image_status = f"OK ({recipe.get('localImagePath')})" if has_image else "Missing"
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
            print(f"- Final output: {RECIPES_OUTPUT}")

            if not args.import_api:
                photo_note = f"Photo prepared at {recipe.get('localImagePath')}" if has_image else "No photo available"
                print(f"  JSON and photo saved for review ({photo_note}). Run with --import-api to import.")
        except Exception as exc:
            has_failures = True
            print("  FAILED:", exc)
            if args.import_api:
                results.append({
                    "mealName": item.get("mealName") if isinstance(item, dict) else str(item),
                    "sourceUrl": item.get("sourceUrl") if isinstance(item, dict) else None,
                    "failed": True,
                    "error": str(exc),
                })
                save_json(results, "output/import_results.json")
        if not args.input and index < len(work):
            time.sleep(settings.request_delay_seconds)

    # Write one canonical artifact after the whole batch. If a validation run is
    # interrupted, an existing recipes.json remains intact for a safe retry.
    if processed_recipes:
        save_json(processed_recipes, RECIPES_OUTPUT)

    if args.import_api:
        print(f"\nImporting from finalized {RECIPES_OUTPUT}...")
        for recipe in processed_recipes:
            errors = recipe.get("validationErrors") or []
            if errors:
                result = {
                    "mealName": recipe.get("mealName") or "Recipe",
                    "sourceUrl": recipe.get("sourceUrl"),
                    "failed": True,
                    "error": "Validation error: " + "; ".join(errors),
                }
                results.append(result)
                save_json(results, "output/import_results.json")
                print_import_result(result)
                continue

            source_url = recipe.get("sourceUrl")
            if source_url and source_url in seen_urls:
                result = {
                    "mealName": recipe.get("mealName"),
                    "sourceUrl": source_url,
                    "skipped": True,
                    "reason": "Duplicate source URL in batch.",
                }
            else:
                if source_url:
                    seen_urls.add(source_url)
                try:
                    result = import_recipe(recipe)
                except Exception as exc:
                    has_failures = True
                    result = {
                        "mealName": recipe.get("mealName"),
                        "sourceUrl": source_url,
                        "failed": True,
                        "error": str(exc),
                    }
            results.append(result)
            save_json(results, "output/import_results.json")
            print_import_result(result)

        added = sum(1 for r in results if not r.get("skipped") and not r.get("failed"))
        skipped = sum(1 for r in results if r.get("skipped"))
        failed_count = sum(1 for r in results if r.get("failed"))
        print(f"\nImport finished: {added} added, {skipped} already existed (skipped), {failed_count} failed/blocked.")
    elif has_failures:
        print("Finished with errors. See the messages above.")
    else:
        print("Finished. JSON and meal images saved; no database import was requested.")
    return 1 if has_failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
