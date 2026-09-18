-- Friend requests are managed by the Spring API. Do not expose them through
-- Supabase's Data API to anon or authenticated clients.
alter table public.friend_requests enable row level security;
