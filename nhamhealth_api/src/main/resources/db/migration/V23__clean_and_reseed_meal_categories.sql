-- Clear references from user_meal_posts and meals
UPDATE public.user_meal_posts SET meal_id = NULL, category_id = NULL;
UPDATE public.meals SET source_user_meal_post_id = NULL;

-- Delete meal related child records
DELETE FROM public.scraped_meal_sources;
DELETE FROM public.meal_ingredient_translations;
DELETE FROM public.meal_ingredients;
DELETE FROM public.recipe_step_translations;
DELETE FROM public.recipe_steps;
DELETE FROM public.meal_nutrition;
DELETE FROM public.meal_tags;
DELETE FROM public.meal_moods;
DELETE FROM public.meal_favorites;
DELETE FROM public.ai_recommendation_items;
DELETE FROM public.meal_translations;
DELETE FROM public.meals;

-- Delete ingredient related records
DELETE FROM public.recipe_ingredients;
DELETE FROM public.ingredient_translations;
DELETE FROM public.ingredients;

-- Delete meal category related records
DELETE FROM public.meal_category_translations;
DELETE FROM public.meal_categories;

-- Reset sequence generators
SELECT setval(pg_get_serial_sequence('public.meals', 'meal_id'), 1, false);
SELECT setval(pg_get_serial_sequence('public.ingredients', 'ingredient_id'), 1, false);
SELECT setval(pg_get_serial_sequence('public.meal_categories', 'category_id'), 1, false);

-- Reseed standard meal categories
INSERT INTO public.meal_categories (category_id, category_name, description, sort_order, is_active, created_at, updated_at)
VALUES
    (1, 'Breakfast', 'Morning meals and breakfast dishes', 1, true, now(), now()),
    (2, 'Lunch', 'Midday meals and lunch dishes', 2, true, now(), now()),
    (3, 'Dinner', 'Evening meals and dinners', 3, true, now(), now()),
    (4, 'Snacks', 'Light snacks, finger foods, and bites', 4, true, now(), now()),
    (5, 'Desserts', 'Sweet treats and traditional desserts', 5, true, now(), now()),
    (6, 'Soups', 'Traditional soups, broths, and stews', 6, true, now(), now()),
    (7, 'Other', 'Other miscellaneous dishes', 7, true, now(), now());

SELECT setval(pg_get_serial_sequence('public.meal_categories', 'category_id'), 7, true);

-- Reseed English category translations
INSERT INTO public.meal_category_translations (category_id, language_code, name, description)
VALUES
    (1, 'en', 'Breakfast', 'Morning meals and breakfast dishes'),
    (2, 'en', 'Lunch', 'Midday meals and lunch dishes'),
    (3, 'en', 'Dinner', 'Evening meals and dinners'),
    (4, 'en', 'Snacks', 'Light snacks, finger foods, and bites'),
    (5, 'en', 'Desserts', 'Sweet treats and traditional desserts'),
    (6, 'en', 'Soups', 'Traditional soups, broths, and stews'),
    (7, 'en', 'Other', 'Other miscellaneous dishes')
ON CONFLICT (category_id, language_code) DO UPDATE
SET name = EXCLUDED.name, description = EXCLUDED.description;

-- Reseed Khmer category translations
INSERT INTO public.meal_category_translations (category_id, language_code, name, description)
VALUES
    (1, 'km', 'អាហារពេលព្រឹក', 'អាហារសម្រាប់ពេលព្រឹក'),
    (2, 'km', 'អាហារពេលថ្ងៃត្រង់', 'អាហារសម្រាប់ពេលថ្ងៃត្រង់'),
    (3, 'km', 'អាហារពេលល្ងាច', 'អាហារសម្រាប់ពេលល្ងាច'),
    (4, 'km', 'អាហារសម្រន់', 'អាហារសម្រន់ស្រាលៗ'),
    (5, 'km', 'បង្អែម', 'បង្អែម និងរបស់ផ្អែមប្រពៃណី'),
    (6, 'km', 'សម្ល', 'សម្ល និងស៊ុបប្រពៃណី'),
    (7, 'km', 'ផ្សេងៗ', 'មុខម្ហូបផ្សេងៗ')
ON CONFLICT (category_id, language_code) DO UPDATE
SET name = EXCLUDED.name, description = EXCLUDED.description;

