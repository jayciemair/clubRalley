-- Club Ralley: COMPLETE Database Schema
-- Run this in Supabase SQL Editor
-- This creates ALL tables the app needs

-- ============================================
-- STEP 1: Drop existing tables (clean slate)
-- ============================================
DROP TABLE IF EXISTS post_reports CASCADE;
DROP TABLE IF EXISTS post_comments CASCADE;
DROP TABLE IF EXISTS post_likes CASCADE;
DROP TABLE IF EXISTS reposts CASCADE;
DROP TABLE IF EXISTS ralley_post_opt_outs CASCADE;
DROP TABLE IF EXISTS ralley_participants CASCADE;
DROP TABLE IF EXISTS ralleys CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS direct_messages CASCADE;
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS chat_members CASCADE;
DROP TABLE IF EXISTS user_interests CASCADE;
DROP TABLE IF EXISTS user_preferences CASCADE;
DROP TABLE IF EXISTS user_availability CASCADE;
DROP TABLE IF EXISTS user_sports CASCADE;
DROP TABLE IF EXISTS friendships CASCADE;
DROP TABLE IF EXISTS club_users CASCADE;

-- ============================================
-- STEP 2: Core User Table
-- ============================================
CREATE TABLE club_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID UNIQUE,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL DEFAULT '',
    last_name TEXT NOT NULL DEFAULT '',
    username TEXT UNIQUE NOT NULL,
    profile_photo_url TEXT,
    bio TEXT,
    city TEXT,
    state TEXT,
    phone_number TEXT,
    instagram_handle TEXT,
    is_verified_athlete BOOLEAN DEFAULT false,
    sports JSONB DEFAULT '[]'::jsonb,
    availability JSONB DEFAULT '[]'::jsonb,
    athlete_info JSONB,
    settings JSONB DEFAULT '{"notifications": true, "max_distance": 25}'::jsonb,
    friends_count INT DEFAULT 0,
    ralleys_count INT DEFAULT 0,
    ralleys_hosted_count INT DEFAULT 0,
    ralleys_joined_count INT DEFAULT 0,
    location_city TEXT,
    location_state TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 3: Ralleys (Events)
-- ============================================
CREATE TABLE ralleys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_user_id UUID REFERENCES club_users(id) ON DELETE CASCADE,
    host_id UUID REFERENCES club_users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    sport TEXT,
    skill_level TEXT DEFAULT 'all',
    location_name TEXT,
    location_address TEXT,
    location_city TEXT,
    location_state TEXT,
    city TEXT,
    state TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    date_time TIMESTAMPTZ,
    duration_minutes INT DEFAULT 120,
    max_participants INT DEFAULT 10,
    current_participants INT DEFAULT 1,
    is_public BOOLEAN DEFAULT true,
    visibility TEXT DEFAULT 'anyone',
    join_type TEXT DEFAULT 'open',
    category TEXT,
    sport_id UUID,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 4: Ralley Participants
-- ============================================
CREATE TABLE ralley_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ralley_id UUID NOT NULL REFERENCES ralleys(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'joined',
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(ralley_id, user_id)
);

-- ============================================
-- STEP 5: Friendships
-- ============================================
CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES club_users(id) ON DELETE CASCADE,
    friend_id UUID REFERENCES club_users(id) ON DELETE CASCADE,
    requester_id UUID REFERENCES club_users(id) ON DELETE CASCADE,
    addressee_id UUID REFERENCES club_users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    accepted_at TIMESTAMPTZ
);

-- ============================================
-- STEP 6: Posts
-- ============================================
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_url TEXT,
    post_type TEXT DEFAULT 'standard',
    ralley_id UUID REFERENCES ralleys(id) ON DELETE SET NULL,
    tagged_user_ids UUID[],
    link_url TEXT,
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    shares_count INT DEFAULT 0,
    visibility TEXT DEFAULT 'everyone',
    liked_by JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 7: Post Engagement Tables
-- ============================================
CREATE TABLE post_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

CREATE TABLE post_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE reposts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(original_post_id, user_id)
);

CREATE TABLE post_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    reporter_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 8: Ralley Completion
-- ============================================
CREATE TABLE ralley_post_opt_outs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ralley_id UUID NOT NULL REFERENCES ralleys(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(ralley_id, user_id)
);

-- ============================================
-- STEP 9: User Profile Extensions
-- ============================================
CREATE TABLE user_sports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    sport_id UUID NOT NULL,
    skill_level TEXT DEFAULT 'intermediate',
    is_preferred BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, sport_id)
);

CREATE TABLE user_availability (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    day_of_week INT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE user_interests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    hobbies JSONB DEFAULT '[]'::jsonb,
    favorite_teams JSONB DEFAULT '[]'::jsonb,
    workout_brands JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE TABLE user_preferences (
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
-- STEP 10: Chat/Messaging
-- ============================================
CREATE TABLE chat_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member',
    last_read_at TIMESTAMPTZ,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(chat_id, user_id)
);

CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id UUID NOT NULL,
    sender_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE direct_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 11: Indexes
-- ============================================
CREATE INDEX idx_users_username ON club_users(username);
CREATE INDEX idx_users_city ON club_users(city, state);
CREATE INDEX idx_ralleys_host ON ralleys(host_user_id);
CREATE INDEX idx_ralleys_datetime ON ralleys(date_time);
CREATE INDEX idx_ralleys_status ON ralleys(status);
CREATE INDEX idx_posts_user ON posts(user_id);
CREATE INDEX idx_posts_created ON posts(created_at DESC);
CREATE INDEX idx_friendships_user ON friendships(user_id);
CREATE INDEX idx_friendships_friend ON friendships(friend_id);

-- ============================================
-- STEP 12: Enable RLS (Row Level Security)
-- ============================================
ALTER TABLE club_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ralleys ENABLE ROW LEVEL SECURITY;
ALTER TABLE ralley_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE reposts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE ralley_post_opt_outs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sports ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE direct_messages ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 13: RLS Policies (Allow all for now)
-- ============================================
-- These are permissive policies for development
-- Tighten these for production!

CREATE POLICY "allow_all_club_users" ON club_users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_ralleys" ON ralleys FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_ralley_participants" ON ralley_participants FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_friendships" ON friendships FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_posts" ON posts FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_post_likes" ON post_likes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_post_comments" ON post_comments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_reposts" ON reposts FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_post_reports" ON post_reports FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_ralley_post_opt_outs" ON ralley_post_opt_outs FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_user_sports" ON user_sports FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_user_availability" ON user_availability FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_user_interests" ON user_interests FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_user_preferences" ON user_preferences FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_chat_members" ON chat_members FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_chat_messages" ON chat_messages FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_direct_messages" ON direct_messages FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- STEP 14: Reload Schema Cache
-- ============================================
NOTIFY pgrst, 'reload schema';

-- ============================================
-- Done! All tables created.
-- ============================================
SELECT 'SUCCESS: All ' || count(*) || ' tables created!' as status
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE';
