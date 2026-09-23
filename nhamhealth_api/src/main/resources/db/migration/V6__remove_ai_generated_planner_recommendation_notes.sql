-- Planner recommendations are curated by admins. Remove legacy AI labels.
UPDATE weekly_meal_recommendations
SET note = NULL
WHERE note ~* '(granite|verified healthy nutrition)';
