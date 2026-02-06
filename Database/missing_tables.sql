-- Missing tables for Club Ralley
-- Run this in Supabase SQL Editor

-- ============================================
-- User Sports (what sports each user plays)
-- ============================================
CREATE TABLE IF NOT EXISTS user_sports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    sport_id UUID NOT NULL,
    skill_level TEXT DEFAULT 'intermediate',
    is_preferred BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, sport_id)
);

CREATE INDEX IF NOT EXISTS idx_user_sports_user ON user_sports(user_id);

-- ============================================
-- User Availability (when users are free)
-- ============================================
CREATE TABLE IF NOT EXISTS user_availability (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    day_of_week INT NOT NULL, -- 0=Sunday, 1=Monday, etc.
    start_time TEXT NOT NULL, -- "06:00"
    end_time TEXT NOT NULL,   -- "12:00"
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_availability_user ON user_availability(user_id);

-- ============================================
-- User Interests (hobbies, preferences)
-- ============================================
CREATE TABLE IF NOT EXISTS user_interests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    hobbies JSONB DEFAULT '[]'::jsonb,
    favorite_teams JSONB DEFAULT '[]'::jsonb,
    workout_brands JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_interests_user ON user_interests(user_id);

-- ============================================
-- User Preferences (settings)
-- ============================================
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    max_distance INT DEFAULT 25,
    notifications_enabled BOOLEAN DEFAULT true,
    privacy_level TEXT DEFAULT 'friends',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- ============================================
-- Chat Members (for group chats)
-- ============================================
CREATE TABLE IF NOT EXISTS chat_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member', -- 'admin', 'member'
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(chat_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_chat_members_chat ON chat_members(chat_id);
CREATE INDEX IF NOT EXISTS idx_chat_members_user ON chat_members(user_id);

-- ============================================
-- Chat Messages
-- ============================================
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL,
    sender_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text', -- 'text', 'image', 'system'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_chat ON chat_messages(chat_id);

-- ============================================
-- Direct Messages
-- ============================================
CREATE TABLE IF NOT EXISTS direct_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dm_sender ON direct_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_dm_recipient ON direct_messages(recipient_id);

-- ============================================
-- Enable RLS on new tables
-- ============================================
ALTER TABLE user_sports ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE direct_messages ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS Policies (permissive for now)
-- ============================================

-- User sports
CREATE POLICY "Users can view all sports" ON user_sports FOR SELECT USING (true);
CREATE POLICY "Users can manage own sports" ON user_sports FOR ALL USING (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

-- User availability
CREATE POLICY "Users can view all availability" ON user_availability FOR SELECT USING (true);
CREATE POLICY "Users can manage own availability" ON user_availability FOR ALL USING (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

-- User interests
CREATE POLICY "Users can view all interests" ON user_interests FOR SELECT USING (true);
CREATE POLICY "Users can manage own interests" ON user_interests FOR ALL USING (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

-- User preferences
CREATE POLICY "Users can view own preferences" ON user_preferences FOR SELECT USING (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);
CREATE POLICY "Users can manage own preferences" ON user_preferences FOR ALL USING (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

-- Chat members
CREATE POLICY "Users can view chats they're in" ON chat_members FOR SELECT USING (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);
CREATE POLICY "Users can join chats" ON chat_members FOR INSERT WITH CHECK (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

-- Chat messages
CREATE POLICY "Users can view messages in their chats" ON chat_messages FOR SELECT USING (
    chat_id IN (SELECT chat_id FROM chat_members WHERE user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid()))
);
CREATE POLICY "Users can send messages" ON chat_messages FOR INSERT WITH CHECK (
    sender_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

-- Direct messages
CREATE POLICY "Users can view own DMs" ON direct_messages FOR SELECT USING (
    sender_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid()) OR
    recipient_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);
CREATE POLICY "Users can send DMs" ON direct_messages FOR INSERT WITH CHECK (
    sender_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);
CREATE POLICY "Users can update own DMs" ON direct_messages FOR UPDATE USING (
    recipient_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

-- ============================================
-- Reload schema cache
-- ============================================
NOTIFY pgrst, 'reload schema';

-- Done!
SELECT 'Missing tables created successfully!' as status;
