alter table public.user_meal_posts
    add column if not exists share_count bigint not null default 0;
