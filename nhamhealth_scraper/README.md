# NhamHealth recipe scraper and importer

The scraper creates reviewable JSON and prepares meal photographs. The Spring Boot
endpoint is implemented in `nhamhealth_api`; no direct database access is used by Python.

## Get the ADMIN import token

Restart Spring Boot after updating the backend. In Postman send:

- POST `http://localhost:8080/api/admin/auth/login`
- Authorization: **No Auth** (remove any stale Authorization header)
- Body: raw JSON with `email` and `password` for your existing ADMIN account.

A successful login returns `accessToken`. Store its value alone (without `Bearer `)
in `SPRING_IMPORT_TOKEN` in the scraper `.env`.
If the response is 202 with `otpRequired: true`, submit the received code to
POST `/api/v1/auth/verify-login` using JSON `{"email":"your-admin-email","code":"received-code"}`.
That response contains the token. No new admin account is created, and credentials
are checked using the existing authentication provider. The mobile login endpoint
`/api/v1/auth/login` continues to reject ADMIN accounts.

## Update: photo-free draft imports

`python main.py --input output/reviewed_recipes.json --import-api` now allows
`localImagePath: null`. The backend stores `main_image_url = NULL`, skips storage
upload and always saves `published=false`. Upload a photo in Admin before publishing.
A supplied image must still be valid. Ingredient review flags, catalog matching and
ADMIN token requirements remain enforced. Missing photos alone no longer block import.

## 1. Scrape one recipe (no database import)

From `nhamhealth_scraper`:

```powershell
.\run_first_recipe.ps1
```

Or, after installing `requirements.txt` into the virtual environment:

```powershell
.\venv\Scripts\python.exe main.py --url "https://cambodiancookbook.com/recipes/bai-sach-chrouk/"
```

Use `--skip` to continue past recipes already processed, for example
`--all --skip 10 --limit 10`, or `--input output/normalized_recipes.json --skip 5`.

Review `output/raw_recipes.json` and `output/normalized_recipes.json`.
The current source produces Bai Sach Chrouk, its Khmer title, Breakfast, 4 servings,
20 minutes cooking time, EASY difficulty, 16 parsed ingredient entries and 5 steps.
Cooking time excludes the source's preparation and overnight marinating time.

**The source image is an SVG illustration, not a meal photograph.** It is rejected
with `imageDownloadError`. During scraping this is a warning: JSON is saved and
the run succeeds if the recipe data is valid. Import accepts missing photos for drafts but rejects invalid supplied photos. CairoSVG and Windows Cairo DLLs are no longer needed.

## 2. Review and optionally provide a real meal photo

Review meal name, category, servings, cooking time, difficulty, ingredients,
quantities, units, preparation notes and steps. Keep nutrition unknown if absent.

Three current entries need review:

- `To serve cucumber, tomato and a fried egg`: split into individual ingredients.
- `1 carrot and 100 g daikon, julienned`: verify the inferred piece unit and preparation notes.
- `To finish spring onion and a pinch of white pepper`: split into individual ingredients.

Do not invent quantities for unspecified amounts. Keep `originalIngredientText`.
Renumber `displayOrder` consecutively after edits. Set each flagged `needsReview`
to `false` only after checking/correcting that entry. An unresolved flag blocks import.
Select one alternative for entries such as pork or chicken stock and match the exact
name in the ingredient catalog. Duplicate ingredient IDs must be combined during review.

To validate the edited JSON and prepare your photo without scraping again:

```powershell
.\venv\Scripts\python.exe main.py --input output/normalized_recipes.json --image-file "C:\path\to\real-bai-sach-chrouk.jpg"
```

Replace the example photo path with your real file. This writes:

- `images/bai-sach-chrouk.webp`
- `output/reviewed_recipes.json`

Open the WebP and verify the dish visually. File validation checks format, size and
readability; it cannot determine whether a photograph depicts the correct meal.
The original input JSON is preserved when writing the separate reviewed file.
When the input is `output/reviewed_recipes.json`, validation is written to
`output/validated_recipes.json` so an interrupted import cannot truncate your reviewed input.
Relative paths are resolved from `nhamhealth_scraper`, even when launched from VS Code.

## 3. Backend setup, after data review

The endpoint is:

```http
POST /api/admin/meals/import-scraped
Authorization: Bearer <ADMIN access token>
Content-Type: multipart/form-data
```

Multipart fields: `recipe` (JSON), `image` (optional JPG/PNG/WebP, maximum 5 MB).
Anonymous requests return 401; non-admin users receive 403.

The V16 Flyway migration creates `scraped_meal_sources`. It runs at backend startup.
It keeps the original import payload, canonical source URL and initial review status.
The source table has RLS enabled with no client policies and revoked client grants.
The backend database connection must use the migration owner or an appropriately
privileged backend role; client Supabase roles cannot access these draft documents.
Ensure the meal category already exists and is active. After a recipe's ingredient
review flags have been cleared, unknown ingredient names are created automatically
with type `SCRAPED_PENDING_REVIEW` and the source recorded in their description.
Review and enrich those catalog entries in Admin before publishing the meal.

Configure the backend's existing Supabase storage settings:

- `app.storage.supabase.url`
- `app.storage.supabase.service-key`
- `app.storage.supabase.bucket`

Use the environment variable names already mapped in your backend configuration.
Keep the service key in the backend only. The shared image storage service uses
Supabase when configured; otherwise it uses local uploads. Configure Supabase for
the requested shared image URL workflow.

Start Spring Boot in a second terminal:

```powershell
cd ..\nhamhealth_api
.\mvnw.cmd spring-boot:run
```

In the scraper `.env`, set `SPRING_ADMIN_EMAIL` and `SPRING_ADMIN_PASSWORD`.
The scraper logs in once per run and uses the returned ADMIN access token for all
imports. Alternatively, set `SPRING_IMPORT_TOKEN` directly for automation. If the
account requires OTP, complete the verification flow and use the returned token.
An admin browser session cookie is not a bearer token. Never commit `.env`.

## 4. Import the reviewed file

Back in `nhamhealth_scraper`, after confirming the data and any supplied photo:

```powershell
.\venv\Scripts\python.exe main.py --input output/reviewed_recipes.json --import-api
```

This revalidates the saved data and imports exactly those edits. The URL form is
also supported, but re-scrapes the source and loses manual corrections; prefer
`--input` for reviewed imports.

For trusted batches where you intentionally accept every flagged parser result,
add `--approve-flagged`. This clears the review flags explicitly; duplicate meals
are still skipped and existing catalog ingredients are still reused.

Successful responses are saved to `output/import_results.json` and contain the
meal ID, stored image URL, warnings, `published: false`, and
`reviewStatus: PENDING_REVIEW`. Review and publish through Admin later.

The backend creates the meal, ingredient rows and ordered recipe steps in one
transaction. Duplicate source URLs or meal names return 409 and the scraper reports
them as already-imported skips, making a reviewed batch safe to retry. Concurrent
scraped imports are serialized with a PostgreSQL transaction lock. Database writes
roll back on failure; storage uploads are external to that transaction, so a database
failure after upload can leave an unused image object for later cleanup.

## Nutrition and translation

Missing nutrition stays null. PER_SERVING values populate the meal nutrition rows;
WHOLE_RECIPE values are divided by servings. UNKNOWN and PER_100G values remain in
the source payload until the per-serving amount can be determined. Existing gram
nutrient catalog entries named Protein, Carbohydrates and Fat are used; missing
entries produce warnings and the source values are retained.

Python does not translate. The original English, source Khmer title, source metadata
and ingredient text are retained in `scraped_meal_sources.source_payload` for a later
MealTranslationService. This change does not generate Khmer translations or add
translation tables. `review_status` records the initial import review state; publication
continues to use the existing meal publication flag.

## Tests

```powershell
.\venv\Scripts\python.exe -m unittest discover -s tests -v
```

Backend tests, without importing real data:

```powershell
cd ..\nhamhealth_api
.\mvnw.cmd "-Dtest=ScrapedMealImportControllerTests,ScrapedMealImportServiceTests,MealApiControllerTests" test
```
