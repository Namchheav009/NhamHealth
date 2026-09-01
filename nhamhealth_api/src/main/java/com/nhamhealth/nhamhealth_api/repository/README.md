# Repository package guide

Spring Data repository interfaces are grouped by business feature. This keeps
the persistence layer easy to scan and prevents the root `repository` package
from becoming a long, unrelated list of files.

## Folder map

| Package | Put these repositories here |
| --- | --- |
| `ai/` | Food analysis, AI suggestions, and recommendations |
| `auth/` | Login providers, roles, verification codes, and password reset tokens |
| `catalog/` | Shared food and reference data such as ingredients, nutrients, serving sizes, categories, and tags |
| `community/` | Posts, comments, likes, follows, favorites, media, and reports |
| `meal/` | The meal aggregate and its ingredients, nutrition, tags, and favorites |
| `notification/` | In-app notifications and registered push devices |
| `recipe/` | Recipes, recipe steps, ingredients, tags, saves, and AI recipe checks |
| `user/` | User accounts, profiles, and settings |
| `wellness/` | Wellness profiles, moods, and daily wellness or nutrient totals |

## Adding a repository

1. Find the feature that owns the entity or aggregate.
2. Create the interface inside that feature folder. For example,
   `HydrationLogRepository` belongs in `repository/wellness/`.
3. Use the matching package declaration, such as:

   ```java
   package com.nhamhealth.nhamhealth_api.repository.wellness;
   ```

4. Extend `JpaRepository<EntityType, IdType>` and import the repository from
   its full feature package in services, controllers, and tests.
5. Run `mvn test` from `nhamhealth_api/` before committing.

Spring Boot scans all of these subpackages automatically because they are below
the main application package. No extra repository-scan configuration is needed.
