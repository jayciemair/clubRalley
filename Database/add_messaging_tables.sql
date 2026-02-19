-- Club Ralley: Add Messaging Tables
-- Run this in Supabase SQL Editor
-- Adds direct messages and chat messages (2 new tables)

-- ============================================
-- TABLE 7: DIRECT MESSAGES (1-on-1 DMs)
-- ============================================
CREATE TABLE IF NOT EXISTS direct_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,

    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 8: CHAT MESSAGES (Ralley Group Chats)
-- Uses ralley_id as chat_id (no separate chat table needed)
-- ============================================
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ralley_id UUID NOT NULL REFERENCES ralleys(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text',  -- 'text' or 'system'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================
-- Direct messages: Find conversations between two users
CREATE INDEX IF NOT EXISTS idx_dm_sender ON direct_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_dm_recipient ON direct_messages(recipient_id);
CREATE INDEX IF NOT EXISTS idx_dm_created ON direct_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_dm_conversation ON direct_messages(
    LEAST(sender_id, recipient_id),
    GREATEST(sender_id, recipient_id),
    created_at DESC
);

-- Chat messages: Find messages for a ralley
CREATE INDEX IF NOT EXISTS idx_chat_ralley ON chat_messages(ralley_id);
CREATE INDEX IF NOT EXISTS idx_chat_created ON chat_messages(ralley_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_sender ON chat_messages(sender_id);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================
ALTER TABLE direct_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Permissive policies for development (tighten for production)
CREATE POLICY "allow_all" ON direct_messages FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON chat_messages FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- REFRESH SCHEMA CACHE
-- ============================================
NOTIFY pgrst, 'reload schema';

-- ============================================
-- VERIFY
-- ============================================
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;
