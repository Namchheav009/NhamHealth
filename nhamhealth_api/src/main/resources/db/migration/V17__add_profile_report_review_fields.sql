alter table public.user_profile_reports
    add column if not exists moderation_action varchar(20),
    add column if not exists admin_note varchar(1000),
    add column if not exists reviewed_by_user_id integer,
    add column if not exists reviewed_at timestamp(6);

alter table public.user_profile_reports
    drop constraint if exists fk_profile_reports_reviewer;

alter table public.user_profile_reports
    add constraint fk_profile_reports_reviewer
        foreign key (reviewed_by_user_id) references public.users(user_id);
