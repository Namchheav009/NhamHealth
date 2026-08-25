ALTER TABLE posts
    ADD COLUMN IF NOT EXISTS shared_post_id INTEGER;

ALTER TABLE posts
    DROP CONSTRAINT IF EXISTS fk_posts_shared_post;

ALTER TABLE posts
    ADD CONSTRAINT fk_posts_shared_post
    FOREIGN KEY (shared_post_id) REFERENCES posts(post_id)
    ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_posts_shared_post_id
    ON posts(shared_post_id);
