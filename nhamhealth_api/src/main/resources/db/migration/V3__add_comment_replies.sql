ALTER TABLE post_comments
    ADD COLUMN IF NOT EXISTS parent_comment_id INTEGER;

ALTER TABLE post_comments
    DROP CONSTRAINT IF EXISTS fk_post_comments_parent_comment;

ALTER TABLE post_comments
    ADD CONSTRAINT fk_post_comments_parent_comment
        FOREIGN KEY (parent_comment_id) REFERENCES post_comments(comment_id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_post_comments_parent_comment_id
    ON post_comments(parent_comment_id);
