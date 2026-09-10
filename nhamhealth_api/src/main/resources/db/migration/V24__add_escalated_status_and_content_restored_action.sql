alter table public.reports drop constraint if exists ck_reports_status;
alter table public.reports add constraint ck_reports_status
    check (status in ('PENDING','UNDER_REVIEW','ESCALATED','RESOLVED','NO_VIOLATION','REJECTED','DISMISSED'));

alter table public.moderation_actions drop constraint if exists ck_moderation_action_type;
alter table public.moderation_actions add constraint ck_moderation_action_type
    check (action_type in ('WARNING','CONTENT_HIDDEN','CONTENT_REMOVED','CONTENT_RESTORED','POST_RESTRICTED','COMMENT_RESTRICTED','ACCOUNT_RESTRICTED','SUSPENDED','BANNED'));

drop index if exists public.uq_reports_active_reporter_target;
create unique index uq_reports_active_reporter_target
    on public.reports(reporter_user_id, report_type, target_id)
    where status in ('PENDING','UNDER_REVIEW','ESCALATED');
