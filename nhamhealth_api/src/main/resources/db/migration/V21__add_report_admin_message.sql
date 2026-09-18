alter table public.reports
    add column if not exists admin_message varchar(1000);
