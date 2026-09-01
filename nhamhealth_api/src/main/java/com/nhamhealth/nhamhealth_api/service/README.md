# Service package guide

Application services are grouped by business feature. Related orchestration,
validation, provider interfaces, and package-private helpers stay together so a
developer can understand a feature without searching through one large folder.

## Folder map

| Package | Put these services here |
| --- | --- |
| `admin/` | Cross-feature administration dashboards and user administration |
| `ai/` | AI analysis, recommendations, NVIDIA providers, parsers, and validators |
| `auth/` | Authentication, registration verification, Google login, and password reset |
| `catalog/` | Food reference data, matching, normalization, ingredients, and meal categories |
| `community/` | Community posts, reports, and community notification orchestration |
| `meal/` | Meal aggregate administration and nutrition calculation |
| `notification/` | Push-notification delivery |
| `recipe/` | Recipe creation, review, and publishing workflows |
| `user/` | User profiles, dashboard data, and profile-image storage |
| `wellness/` | Wellness profiles, daily nutrition, and user nutrition context |

## Adding a service

1. Find the feature that owns the use case.
2. Create the service in that feature folder. For example,
   `HydrationReminderService` belongs in `service/wellness/`.
3. Use the matching package declaration:

   ```java
   package com.nhamhealth.nhamhealth_api.service.wellness;
   ```

4. Keep small package-private helpers beside the service that owns them. Move a
   helper to another package only when it becomes a shared public abstraction.
5. Mirror the package under `src/test/java` when adding a service test.
6. Import services from their full feature package in controllers and other
   services, then run `mvn test` before committing.

Spring component scanning includes all of these subpackages automatically
because they are below the main application package.
