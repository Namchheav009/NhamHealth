-- These tables backed the removed admin-only Meal Logs and Nutrient Goals modules.
-- Dropping them permanently removes any data they contain.
drop table if exists public.meal_log_nutrients;
drop table if exists public.meal_logs;
drop table if exists public.meal_log_types;
drop table if exists public.user_nutrient_goals;
