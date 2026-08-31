alter table public.user_meal_posts
    add column if not exists shared_from_user_meal_post_id integer;

create index if not exists idx_user_meal_posts_shared_source
    on public.user_meal_posts (shared_from_user_meal_post_id);

do $$
begin
    if not exists (
        select 1 from pg_constraint
        where conname = 'fk_user_meal_posts_shared_source'
    ) then
        alter table public.user_meal_posts
            add constraint fk_user_meal_posts_shared_source
            foreign key (shared_from_user_meal_post_id)
            references public.user_meal_posts (user_meal_post_id);
    end if;
end $$;
