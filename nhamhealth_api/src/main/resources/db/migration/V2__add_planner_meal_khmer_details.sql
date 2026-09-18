-- Migration: V2__add_planner_meal_khmer_details.sql
-- Add Khmer language support for ingredients, cooking steps (instructions), and tags in planner_meals

ALTER TABLE public.planner_meals
    ADD COLUMN IF NOT EXISTS ingredients_text_km text,
    ADD COLUMN IF NOT EXISTS instructions_text_km text,
    ADD COLUMN IF NOT EXISTS tags_text_km varchar(500);
