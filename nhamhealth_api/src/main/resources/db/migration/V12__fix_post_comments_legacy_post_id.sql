-- Some upgraded databases kept the legacy post_id column after comments were
-- moved to user_meal_posts. Hibernate writes user_meal_post_id, so a remaining
-- NOT NULL post_id makes every new comment fail.
do $$
begin
    if exists (
        select 1
        from information_schema.columns
        where table_schema = 'public'
          and table_name = 'post_comments'
          and column_name = 'post_id'
    ) then
        if exists (
            select 1
            from information_schema.columns
            where table_schema = 'public'
              and table_name = 'post_comments'
              and column_name = 'user_meal_post_id'
        ) then
            update public.post_comments
            set user_meal_post_id = post_id
            where user_meal_post_id is null
              and post_id is not null;

            if exists (
                select 1
                from public.post_comments
                where user_meal_post_id is null
            ) then
                raise exception
                    'Cannot remove post_comments.post_id: comments without a post still exist';
            end if;

            alter table public.post_comments
                alter column user_meal_post_id set not null;
            alter table public.post_comments
                drop column post_id cascade;
        else
            alter table public.post_comments
                rename column post_id to user_meal_post_id;
        end if;
    end if;
end $$;

create index if not exists idx_post_comments_post_id_created_at
    on public.post_comments (user_meal_post_id, created_at);
