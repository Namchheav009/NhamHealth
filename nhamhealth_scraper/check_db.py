import sys
import psycopg2

sys.stdout.reconfigure(encoding='utf-8')

conn = psycopg2.connect(
    dbname='postgres',
    user='postgres.ycblccnufpweredialmc',
    password='Nhamhealth009',
    host='aws-0-ap-southeast-1.pooler.supabase.com',
    port=5432,
    sslmode='require'
)
cur = conn.cursor()

cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'ingredients'")
print("INGREDIENT COLUMNS:", [r[0] for r in cur.fetchall()])

cur.execute("SELECT ingredient_id, ingredient_name, image_url, default_unit FROM ingredients ORDER BY ingredient_id DESC LIMIT 10")
print("\n=== RECENT INGREDIENTS ===")
for row in cur.fetchall():
    print(f"ID: {row[0]} | Name: {row[1]} | Image: {row[2]} | Unit: {row[3]}")

cur.execute("SELECT meal_id, meal_name, is_published, source_type FROM meals WHERE meal_id = 1")
print("\nMEAL 1:", cur.fetchone())

cur.execute("SELECT * FROM meal_translations WHERE meal_id = 1")
for row in cur.fetchall():
    print("MEAL_TRANSLATION:", row)

cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'meal_ingredient_translations'")
print("\nINGREDIENT TRANSLATION COLS:", [r[0] for r in cur.fetchall()])

cur.execute("SELECT * FROM meal_ingredient_translations LIMIT 10")
for row in cur.fetchall():
    print("ING_TRANS:", row)

cur.execute("SELECT column_name, table_name FROM information_schema.columns WHERE table_name IN ('recipe_steps', 'recipe_step_translations')")
for row in cur.fetchall():
    print("STEP COL:", row)

cur.execute("""
    SELECT s.step_number, s.instruction, t.instruction, t.language_code
    FROM recipe_steps s
    LEFT JOIN recipe_step_translations t ON s.step_id = t.recipe_step_id
    WHERE s.meal_id = 1
    ORDER BY s.step_number
""")

for row in cur.fetchall():
    print(f"\nStep {row[0]} ({row[3]}):\n  EN: {row[1]}\n  KM: {row[2]}")





conn.close()
