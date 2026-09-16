-- V27-V29 may already be applied. Rename the migrated event values in a
-- forward-only migration instead of changing their checksums.
drop index if exists public.uq_follows_friend_pending_pair;

update public.follows
set status = case status
    when 'FRIEND_PENDING' then 'FOLLOW_PENDING'
    when 'FRIEND_ACCEPTED' then 'FOLLOW_ACCEPTED'
    when 'FRIEND_DECLINED' then 'FOLLOW_DECLINED'
end
where status in ('FRIEND_PENDING', 'FRIEND_ACCEPTED', 'FRIEND_DECLINED');

create unique index uq_follows_pending_connection_pair
    on public.follows (
        least(follower_user_id, following_user_id),
        greatest(follower_user_id, following_user_id)
    )
    where status = 'FOLLOW_PENDING';

drop index if exists public.uq_notifications_friend_request;

update public.notifications
set reference_type = case reference_type
    when 'FRIEND_REQUEST' then 'FOLLOW_CONNECTION'
    when 'FRIEND_REQUEST_ACCEPTED' then 'FOLLOW_CONNECTION_ACCEPTED'
end
where reference_type in ('FRIEND_REQUEST', 'FRIEND_REQUEST_ACCEPTED');

create unique index uq_notifications_follow_connection
    on public.notifications (user_id, reference_id)
    where notification_type = 'COMMUNITY' and reference_type = 'FOLLOW_CONNECTION';
