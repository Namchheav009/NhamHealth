# Implemented Spring Boot import contract

See [the scraper README](../README.md) for setup, review and import commands.

- Endpoint: `POST /api/admin/meals/import-scraped`
- Authentication: ADMIN bearer access token
- Multipart parts: `recipe` JSON string and optional `image` file, at most 5 MB
- DTO: `ScrapedMealImportRequest` and its nested ingredient/step records
- Response: 201 with mealId, mealName, mainImageUrl, published=false,
  reviewStatus=PENDING_REVIEW and warnings
- Validation or unresolved catalog names: 400 with message
- Duplicate source URL or meal name: 409
- Missing authentication: 401; insufficient role: 403

Category and ingredient names are matched case-insensitively against existing
catalog entries. Unknown entries are rejected before image upload or meal creation.
Ingredient displayOrder and stepNumber must be consecutive starting at 1.
Each ingredient ID can occur once per meal under the existing Admin meal rules.

V16 creates `scraped_meal_sources` to preserve the original JSON for provenance,
nutrition review and future Khmer translation. It does not create translations.

Images use the existing ProfileImageStorageService. Configure its Supabase settings
for Supabase upload; unconfigured storage falls back to local files.

Omitting image creates an unpublished draft with mainImageUrl=null. Normal Admin
creation/publication still requires a stored meal image.
