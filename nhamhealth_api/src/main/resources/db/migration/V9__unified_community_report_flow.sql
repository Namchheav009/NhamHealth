-- Keep existing post reports intact while allowing one moderation queue for
-- both posts and comments. Comment reports retain post_id as useful context.
ALTER TABLE post_reports
    ADD COLUMN IF NOT EXISTS comment_id INTEGER;

ALTER TABLE post_reports
    ADD COLUMN IF NOT EXISTS target_type VARCHAR(20) NOT NULL DEFAULT 'POST';

ALTER TABLE post_reports
    ADD COLUMN IF NOT EXISTS moderation_action VARCHAR(20);

ALTER TABLE post_reports
    ADD COLUMN IF NOT EXISTS admin_note VARCHAR(1000);

ALTER TABLE post_reports
    DROP CONSTRAINT IF EXISTS fk_post_reports_comment;

ALTER TABLE post_reports
    ADD CONSTRAINT fk_post_reports_comment
    FOREIGN KEY (comment_id) REFERENCES post_comments(comment_id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_post_reports_target_status_created_at
    ON post_reports(target_type, status, created_at DESC);
