-- Upgrade databases created from the earlier consolidated baseline. Fresh
-- databases already use user_meal_posts and therefore skip the rename block.
do $$
begin
    if to_regclass('public.recipes') is not null then
        drop view if exists public.community_meal_posts;

        alter table public.recipes rename to user_meal_posts;
        alter table public.user_meal_posts rename column recipe_id to user_meal_post_id;

        alter table public.ai_recipe_reviews rename column recipe_id to user_meal_post_id;
        alter table public.post_comments rename column recipe_id to user_meal_post_id;
        alter table public.post_favorites rename column recipe_id to user_meal_post_id;
        alter table public.post_likes rename column recipe_id to user_meal_post_id;
        alter table public.post_media rename column recipe_id to user_meal_post_id;
        alter table public.post_reports rename column recipe_id to user_meal_post_id;
        alter table public.post_tags rename column recipe_id to user_meal_post_id;
        alter table public.recipe_ingredients rename column recipe_id to user_meal_post_id;
        alter table public.recipe_steps rename column recipe_id to user_meal_post_id;
        alter table public.recipe_tags rename column recipe_id to user_meal_post_id;
        alter table public.saved_recipes rename column recipe_id to user_meal_post_id;
        alter table public.user_recipe_ai_checks rename column recipe_id to user_meal_post_id;
        alter table public.meals rename column source_recipe_id to source_user_meal_post_id;
    end if;
end $$;

create or replace view public.community_meal_posts as
select p.user_meal_post_id as post_id,
       p.author_user_id as user_id,
       p.meal_id as tagged_meal_id,
       p.user_meal_post_id,
       p.description as caption,
       'PUBLIC'::varchar(20) as visibility,
       true as allow_comments,
       true as allow_replies,
       case when p.status = 'PUBLISHED' then 'ACTIVE' else 'ARCHIVED' end::varchar(20) as status,
       p.created_at,
       p.updated_at
from public.user_meal_posts p;
