alter table public.users
    add column login_otp_required boolean not null default false;
