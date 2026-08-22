# Performance Test Plan

Measure the Meals page after each optimization stage. Record the date, dataset
size, request URL, response time, response size, SQL query count, and rows
returned.

## API Checks

Run the API with production-like settings and measure the paged endpoint:

```text
GET /admin/meals/data?page=0
GET /admin/meals/data?page=0&search=chicken
GET /admin/meals/data?page=0&category=breakfast
GET /admin/meals/data?page=0&status=published
```

The expected result is a page of 10 rows, not the full catalog. Confirm the
meal listing uses one aggregate query plus its pagination count query rather
than one review/favorite query per meal.

For PostgreSQL, inspect the actual plan in the Supabase SQL editor:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    m.meal_id,
    m.meal_name,
    COUNT(DISTINCT mf.meal_favorite_id) AS favorites,
    COUNT(DISTINCT r.review_id) AS reviews,
    COALESCE(AVG(r.rating), 0) AS rating
FROM meals m
LEFT JOIN meal_favorites mf ON mf.meal_id = m.meal_id
LEFT JOIN reviews r ON r.meal_id = m.meal_id
GROUP BY m.meal_id, m.meal_name
ORDER BY m.updated_at DESC
LIMIT 10;
```

Use `EXPLAIN (ANALYZE, BUFFERS)` for the real application query as well. A
healthy plan may use the foreign-key indexes, the `updated_at` index, or a
sequential scan when the table is small. Judge the plan by actual time and
rows, not by the scan label alone.

## Browser Checks

In Chrome DevTools, open Network, enable Disable cache for the test run, then
reload `/admin/meals`. Record the Document, CSS, JS, API, and image requests.
Confirm that:

- the first meal response is paged;
- table images use the Supabase render thumbnail URL and `loading=lazy`;
- image responses are WebP thumbnails rather than multi-megabyte originals;
- there are no chart or unused UI library requests;
- the request count and transferred bytes are compared with the previous run.

Repeat each scenario three times after a cold start and three times with a warm
application cache. Keep the raw Network export and the SQL plan with the
result so later module changes can be compared fairly.
