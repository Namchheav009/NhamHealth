alter table public.user_profiles
    add column if not exists is_phone_verified boolean not null default false,
    add column if not exists phone_verified_at timestamp(6);
