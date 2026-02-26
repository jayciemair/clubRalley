-- Push Notifications Migration
-- Creates device_tokens and notification_settings tables for APNs push support
--
-- Run this in the Supabase SQL Editor after deploying code changes.

-- =============================================================================
-- 1. device_tokens — stores APNs device tokens per user
-- =============================================================================

CREATE TABLE IF NOT EXISTS device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    platform TEXT NOT NULL DEFAULT 'ios',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for looking up active tokens by user (used by Edge Function)
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_active
    ON device_tokens (user_id, is_active) WHERE is_active = true;

-- Auto-update updated_at on changes
CREATE OR REPLACE TRIGGER set_device_tokens_updated_at
    BEFORE UPDATE ON device_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Users can read their own tokens
CREATE POLICY "device_tokens_select_own" ON device_tokens
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Users can insert their own tokens
CREATE POLICY "device_tokens_insert_own" ON device_tokens
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

-- Users can update their own tokens
CREATE POLICY "device_tokens_update_own" ON device_tokens
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Users can delete their own tokens
CREATE POLICY "device_tokens_delete_own" ON device_tokens
    FOR DELETE TO authenticated
    USING (user_id = auth.uid());

-- =============================================================================
-- 2. notification_settings — per-user push notification preferences
-- =============================================================================

CREATE TABLE IF NOT EXISTS notification_settings (
    user_id UUID PRIMARY KEY REFERENCES club_users(id) ON DELETE CASCADE,
    push_enabled BOOLEAN NOT NULL DEFAULT true,
    ralley_invites BOOLEAN NOT NULL DEFAULT true,
    ralley_updates BOOLEAN NOT NULL DEFAULT true,
    new_followers BOOLEAN NOT NULL DEFAULT true,
    comments_likes BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Auto-update updated_at on changes
CREATE OR REPLACE TRIGGER set_notification_settings_updated_at
    BEFORE UPDATE ON notification_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;

-- Users can read their own settings
CREATE POLICY "notification_settings_select_own" ON notification_settings
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Users can insert their own settings
CREATE POLICY "notification_settings_insert_own" ON notification_settings
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

-- Users can update their own settings
CREATE POLICY "notification_settings_update_own" ON notification_settings
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
