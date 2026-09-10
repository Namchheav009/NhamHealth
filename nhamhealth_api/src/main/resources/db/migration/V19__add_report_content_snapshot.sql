alter table public.reports
    add column if not exists content_snapshot varchar(1000);
