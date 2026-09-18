-- Upgraded databases can retain the old post_id column alongside
-- user_meal_post_id. New meal-post media writes user_meal_post_id, so the
-- legacy column must no longer be mandatory. Keep it for compatibility with
-- old installations and remove only its obsolete NOT NULL requirement.
do $$
begin
    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public'
          and table_name = 'post_media'
          and column_name = 'post_id'
    ) then
        if exists (
            select 1
            from information_schema.columns
            where table_schema = 'public'
              and table_name = 'post_media'
              and column_name = 'user_meal_post_id'
        ) then
            update public.post_media
            set user_meal_post_id = post_id
            where user_meal_post_id is null
              and post_id is not null;

            alter table public.post_media
                alter column post_id drop not null;
        else
            alter table public.post_media
                rename column post_id to user_meal_post_id;
        end if;
    end if;
end $$;

create index if not exists idx_post_media_meal_post_order
    on public.post_media (user_meal_post_id, display_order);
