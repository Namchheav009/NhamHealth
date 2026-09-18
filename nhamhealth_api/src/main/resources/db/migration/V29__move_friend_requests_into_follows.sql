-- Keep V27/V28 immutable: copy each request event into follows before removing
-- the old table. Ordinary ACTIVE/BLOCKED follows remain untouched.
alter table public.follows add column legacy_friend_request_id integer;

insert into public.follows (
    follower_user_id, following_user_id, requested_at, responded_at, status,
    legacy_friend_request_id
)
select sender_user_id, receiver_user_id, created_at, responded_at,
       case status
           when 'PENDING' then 'FRIEND_PENDING'
           when 'ACCEPTED' then 'FRIEND_ACCEPTED'
           when 'DECLINED' then 'FRIEND_DECLINED'
       end,
       friend_request_id
from public.friend_requests;

-- Notification reference IDs now point to the migrated follows rows. Drop the
-- partial unique index during remapping to avoid transient ID-swap conflicts.
drop index if exists public.uq_notifications_friend_request;

update public.notifications notification
set reference_id = follow.follow_id
from public.follows follow
where follow.legacy_friend_request_id = notification.reference_id
  and notification.reference_type in ('FRIEND_REQUEST', 'FRIEND_REQUEST_ACCEPTED');

create unique index uq_notifications_friend_request
    on public.notifications (user_id, reference_id)
    where notification_type = 'COMMUNITY' and reference_type = 'FRIEND_REQUEST';

alter table public.follows drop column legacy_friend_request_id;

-- Only one pending friend request may exist per unordered user pair, including
-- concurrent reciprocal requests. This does not restrict ordinary follows.
create unique index uq_follows_friend_pending_pair
    on public.follows (
        least(follower_user_id, following_user_id),
        greatest(follower_user_id, following_user_id)
    )
    where status = 'FRIEND_PENDING';

-- Friend-request events are accessed through the authenticated Spring API.
-- Deny direct Supabase Data API row access unless explicit policies are added.
alter table public.follows enable row level security;

drop table public.friend_requests;
