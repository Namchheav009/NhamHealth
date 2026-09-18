alter table public.user_meal_posts
    add column if not exists category_id integer;

create index if not exists idx_user_meal_posts_category_id
    on public.user_meal_posts (category_id);

do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conname = 'fk_user_meal_posts_category'
    ) then
        alter table public.user_meal_posts
            add constraint fk_user_meal_posts_category
            foreign key (category_id) references public.meal_categories;
    end if;
end $$;
