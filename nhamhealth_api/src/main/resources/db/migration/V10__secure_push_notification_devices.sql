CREATE TABLE IF NOT EXISTS push_notification_devices (
    device_id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    token VARCHAR(512) NOT NULL UNIQUE,
    platform VARCHAR(20) NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_push_notification_devices_user_id
    ON push_notification_devices(user_id);

ALTER TABLE push_notification_devices
    ADD CONSTRAINT chk_push_notification_devices_platform
    CHECK (platform IN ('ANDROID', 'IOS'));

-- This table is server-internal. The Spring API uses a direct PostgreSQL
-- connection; mobile clients must never read or mutate device tokens through
-- Supabase's Data API.
ALTER TABLE push_notification_devices ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE push_notification_devices FROM anon, authenticated;
REVOKE ALL ON SEQUENCE push_notification_devices_device_id_seq FROM anon, authenticated;
