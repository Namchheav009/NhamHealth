"""
Utility script to clean meals and ingredients from the Supabase PostgreSQL database
and reset scraper output files so that recipes can be scraped and imported freshly.
"""
import os
import sys
from pathlib import Path
import psycopg2

# Database connection credentials from nhamhealth_api
DB_HOST = os.getenv("SPRING_DATASOURCE_HOST", "aws-0-ap-southeast-1.pooler.supabase.com")
DB_PORT = int(os.getenv("SPRING_DATASOURCE_PORT", "5432"))
DB_USER = os.getenv("SPRING_DATASOURCE_USER", "postgres.ycblccnufpweredialmc")
DB_PASSWORD = os.getenv("SPRING_DATASOURCE_PASSWORD", "Nhamhealth009")
DB_NAME = os.getenv("SPRING_DATASOURCE_DB", "postgres")


def clean_database():
    print("Connecting to Supabase PostgreSQL database...")
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        dbname=DB_NAME,
        sslmode="require"
    )
    conn.autocommit = False
    cur = conn.cursor()

    try:
        # 1. Record baseline counts for meals, ingredients, and USER POSTS
        cur.execute("SELECT COUNT(*) FROM meals;")
        initial_meals = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM ingredients;")
        initial_ingredients = cur.fetchone()[0]

        cur.execute("SELECT COUNT(*) FROM user_meal_posts;")
        initial_posts = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM recipe_steps WHERE user_meal_post_id IS NOT NULL;")
        initial_post_steps = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM recipe_ingredients WHERE user_meal_post_id IS NOT NULL;")
        initial_post_ingredients = cur.fetchone()[0]

        print(f"Initial counts:")
        print(f"  - Meals: {initial_meals}")
        print(f"  - Ingredients: {initial_ingredients}")
        print(f"  - User Posts (MUST PRESERVE): {initial_posts}")
        print(f"  - User Post Steps (MUST PRESERVE): {initial_post_steps}")
        print(f"  - User Post Ingredients (MUST PRESERVE): {initial_post_ingredients}")

        # 2. Unlink any references from user posts to meals or ingredients (without deleting posts)
        print("\nUnlinking user posts and post ingredients from meals/ingredients...")
        cur.execute("UPDATE user_meal_posts SET meal_id = NULL WHERE meal_id IS NOT NULL;")
        cur.execute("UPDATE posts SET tagged_meal_id = NULL WHERE tagged_meal_id IS NOT NULL;")
        cur.execute("UPDATE recipe_ingredients SET ingredient_id = NULL WHERE ingredient_id IS NOT NULL;")

        # 3. Delete dependent rows strictly belonging to meals and catalog ingredients
        print("Cleaning meal-dependent child tables...")
        cur.execute("DELETE FROM meal_ingredient_translations;")
        cur.execute("DELETE FROM meal_ingredients;")
        cur.execute("DELETE FROM ingredient_translations;")
        cur.execute("DELETE FROM meal_translations;")
        cur.execute("DELETE FROM meal_nutrition;")
        cur.execute("DELETE FROM meal_tags;")
        cur.execute("DELETE FROM meal_moods;")
        cur.execute("DELETE FROM meal_favorites;")
        cur.execute("DELETE FROM meal_log_nutrients;")
        cur.execute("DELETE FROM meal_logs;")
        cur.execute("DELETE FROM ai_recommendation_items WHERE meal_id IS NOT NULL;")
        cur.execute("DELETE FROM recipe_steps WHERE meal_id IS NOT NULL;")
        cur.execute("DELETE FROM scraped_meal_sources;")

        # 4. Delete meals and catalog ingredients
        print("Deleting meals and ingredients...")
        cur.execute("DELETE FROM meals;")
        cur.execute("DELETE FROM ingredients;")

        # 5. Reset primary key identity sequences
        print("Resetting primary key sequences...")
        cur.execute("ALTER SEQUENCE public.meals_meal_id_seq RESTART WITH 1;")
        cur.execute("ALTER SEQUENCE public.ingredients_ingredient_id_seq RESTART WITH 1;")

        conn.commit()

        # 6. Verify final counts
        cur.execute("SELECT COUNT(*) FROM meals;")
        final_meals = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM ingredients;")
        final_ingredients = cur.fetchone()[0]

        cur.execute("SELECT COUNT(*) FROM user_meal_posts;")
        final_posts = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM recipe_steps WHERE user_meal_post_id IS NOT NULL;")
        final_post_steps = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM recipe_ingredients WHERE user_meal_post_id IS NOT NULL;")
        final_post_ingredients = cur.fetchone()[0]

        print("\nFinal verification:")
        print(f"  - Meals: {final_meals} (successfully cleared)")
        print(f"  - Ingredients: {final_ingredients} (successfully cleared)")
        print(f"  - User Posts: {final_posts} (intact: {final_posts == initial_posts})")
        print(f"  - User Post Steps: {final_post_steps} (intact: {final_post_steps == initial_post_steps})")
        print(f"  - User Post Ingredients: {final_post_ingredients} (intact: {final_post_ingredients == initial_post_ingredients})")

        assert final_meals == 0, "Meals count is not 0"
        assert final_ingredients == 0, "Ingredients count is not 0"
        assert final_posts == initial_posts, "User posts were modified!"
        assert final_post_steps == initial_post_steps, "User post steps were modified!"
        assert final_post_ingredients == initial_post_ingredients, "User post ingredients were modified!"

    except Exception as exc:
        conn.rollback()
        print(f"\nERROR during cleaning: {exc}")
        raise
    finally:
        cur.close()
        conn.close()



def clean_output_files():
    output_dir = Path(__file__).resolve().parent / "output"
    if not output_dir.exists():
        return
    files_to_remove = [
        "raw_recipes.json",
        "normalized_recipes.json",
        "reviewed_recipes.json",
        "validated_recipes.json",
        "import_results.json"
    ]
    for filename in files_to_remove:
        file_path = output_dir / filename
        if file_path.exists():
            file_path.unlink()
            print(f"Removed output file: {filename}")


if __name__ == "__main__":
    clean_database()
    clean_output_files()
    print("All meals, ingredients, and scraper output files have been cleaned!")

