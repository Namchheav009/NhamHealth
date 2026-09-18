alter table public.users
    add column auth_version integer not null default 0;

alter table public.users
    add constraint ck_users_auth_version_non_negative check (auth_version >= 0);
