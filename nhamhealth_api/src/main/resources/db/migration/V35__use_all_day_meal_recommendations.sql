alter table public.weekly_meal_recommendations
    drop constraint if exists ck_weekly_meal_recommendation_day;

delete from public.weekly_meal_recommendations row_to_remove
 where exists (
    select 1 from public.weekly_meal_recommendations row_to_keep
     where row_to_keep.planner_meal_id = row_to_remove.planner_meal_id
       and row_to_keep.meal_slot = row_to_remove.meal_slot
       and row_to_keep.recommendation_id < row_to_remove.recommendation_id
 );

update public.weekly_meal_recommendations
   set day_of_week = 'ALL', updated_at = current_timestamp;

alter table public.weekly_meal_recommendations
    add constraint ck_weekly_meal_recommendation_day check (
        day_of_week in ('ALL','MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY'));
