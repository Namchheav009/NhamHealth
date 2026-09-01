-- V6 may already have been recorded before an older application instance
-- recreated these Hibernate-managed tables. Re-run the cleanup as a new
-- migration; Flyway intentionally never executes an applied version twice.
drop table if exists public.meal_log_nutrients;
drop table if exists public.meal_logs;
drop table if exists public.meal_log_types;
drop table if exists public.user_nutrient_goals;
