alter table public.users
add column if not exists phone_number varchar(30);
create unique index if not exists uk_users_phone_number on public.users (phone_number)
where phone_number is not null;
update public.users u
set phone_number = up.phone_number
from public.user_profiles up
where u.user_id = up.user_id
    and u.phone_number is null
    and up.phone_number is not null
    and not exists (
        select 1
        from public.users existing
        where existing.phone_number = up.phone_number
    );
