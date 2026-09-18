-- Remove legacy tables that no longer have JPA entity mappings.
-- Child tables are dropped before their parent tables to satisfy foreign keys.
drop table if exists public.message_read_receipts;
drop table if exists public.message_reactions;
drop table if exists public.message_attachments;
drop table if exists public.chat_participants;
drop table if exists public.shares;
drop table if exists public.flags;
drop table if exists public.reviews;
drop table if exists public.messages;
drop table if exists public.chats;
