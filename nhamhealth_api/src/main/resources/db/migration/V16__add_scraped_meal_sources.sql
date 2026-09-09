-- Preserve original English, optional source Khmer title, ingredient text and
-- nutrition basis for review and future translation without altering the source.
CREATE TABLE scraped_meal_sources (
    meal_id INTEGER PRIMARY KEY REFERENCES meals(meal_id) ON DELETE CASCADE,
    source_url VARCHAR(1000) NOT NULL UNIQUE,
    source_payload TEXT NOT NULL,
    review_status VARCHAR(30) NOT NULL DEFAULT 'PENDING_REVIEW',
    imported_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Source documents are backend-only. The migration owner retains access;
-- client roles must not read unpublished recipes through Supabase's Data API.
ALTER TABLE scraped_meal_sources ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE scraped_meal_sources FROM PUBLIC;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE ALL ON TABLE scraped_meal_sources FROM anon;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        REVOKE ALL ON TABLE scraped_meal_sources FROM authenticated;
    END IF;
END
$$;
