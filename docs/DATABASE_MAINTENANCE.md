# Database Maintenance

The meal admin listing orders pages by `meals.updated_at`. The JPA mapping
declares `idx_meals_updated_at`; PostgreSQL can scan this btree index backward
for descending order, so a separate descending index is not needed.

Do not add indexes to every column. Add one when a column is repeatedly used
for joins, filters, or ordering and verify the query plan first. The current
meal-name search uses a contains query (`%keyword%`), so a normal btree index
would not improve it. Consider PostgreSQL `pg_trgm` only if that search becomes
a measured bottleneck.

After bulk loading or changing many rows, refresh planner statistics in the
Supabase SQL editor:

```sql
ANALYZE meals;
ANALYZE meal_favorites;
ANALYZE reviews;
```

User notification reads are intentionally capped at the 20 most recent rows;
older notifications should use a paged endpoint rather than loading the full
history into memory.

To verify that the favorite lookup uses the foreign-key index, run this in the
Supabase SQL editor with a real user id:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM meal_favorites
WHERE user_id = 4;
```

For a bulk unfavorite operation, use one statement instead of deleting rows in
a Java loop:

```sql
DELETE FROM meal_favorites
WHERE user_id = 4;
```

The API exposes the same operation as `DELETE /api/v1/favorites/meals` for the
authenticated user.