-- These legacy features are intentionally not part of the recipe/community
-- flow. Remove their data and schema after the corresponding JPA entities and
-- endpoints have been removed from the application.

DROP TABLE IF EXISTS shares;

DROP TABLE IF EXISTS message_read_receipts;
DROP TABLE IF EXISTS message_reactions;
DROP TABLE IF EXISTS message_attachments;
DROP TABLE IF EXISTS chat_participants; -- must come first
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS chats;

DROP TABLE IF EXISTS reviews;

ALTER TABLE posts DROP CONSTRAINT IF EXISTS fk_posts_shared_post;
DROP INDEX IF EXISTS idx_posts_shared_post_id;
ALTER TABLE posts DROP COLUMN IF EXISTS shared_post_id;
