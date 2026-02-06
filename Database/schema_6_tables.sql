-- Club Ralley: Optimal 6-Table Schema
-- Run this in Supabase SQL Editor

-- ============================================
-- CLEAN SLATE - Drop all existing tables
-- ============================================
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS ralley_participants CASCADE;
DROP TABLE IF EXISTS ralleys CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS friendships CASCADE;
DROP TABLE IF EXISTS club_users CASCADE;

-- Also drop any legacy tables that might exist
DROP TABLE IF EXISTS user_sports CASCADE;
DROP TABLE IF EXISTS user_availability CASCADE;
DROP TABLE IF EXISTS user_interests CASCADE;
DROP TABLE IF EXISTS user_preferences CASCADE;
DROP TABLE IF EXISTS post_likes CASCADE;
DROP TABLE IF EXISTS post_comments CASCADE;
DROP TABLE IF EXISTS chat_members CASCADE;
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS direct_messages CASCADE;
DROP TABLE IF EXISTS reposts CASCADE;
DROP TABLE IF EXISTS post_reports CASCADE;
DROP TABLE IF EXISTS ralley_post_opt_outs CASCADE;

-- ============================================
-- TABLE 1: USERS
-- ============================================
CREATE TABLE club_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    first_name TEXT DEFAULT '',
    last_name TEXT DEFAULT '',
    username TEXT UNIQUE NOT NULL,
    profile_photo_url TEXT,
    bio TEXT,
    city TEXT,
    state TEXT,
    instagram_handle TEXT,

    -- JSONB columns (no separate tables needed)
    sports JSONB DEFAULT '[]'::jsonb,
    -- Example: [{"name": "Tennis", "skill": "intermediate"}, {"name": "Golf", "skill": "beginner"}]

    availability JSONB DEFAULT '[]'::jsonb,
    -- Example: [{"day": "saturday", "time": "morning"}, {"day": "sunday", "time": "afternoon"}]

    preferences JSONB DEFAULT '{"max_distance": 25, "notifications": true}'::jsonb,
    -- Example: {"max_distance": 25, "notifications": true, "privacy": "friends"}

    athlete_info JSONB,
    -- Example: {"school": "UCLA", "sport": "Tennis", "verified": true}

    -- Counters
    friends_count INT DEFAULT 0,
    ralleys_count INT DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 2: RALLEYS (Events)
-- ============================================
CREATE TABLE ralleys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,

    title TEXT NOT NULL,
    description TEXT,
    sport TEXT,
    skill_level TEXT DEFAULT 'all',

    -- Location
    location_name TEXT,
    location_address TEXT,
    city TEXT,
    state TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),

    -- Timing
    date_time TIMESTAMPTZ NOT NULL,
    duration_minutes INT DEFAULT 120,

    -- Capacity
    max_participants INT DEFAULT 10,
    current_participants INT DEFAULT 1,

    -- Settings
    visibility TEXT DEFAULT 'anyone',
    join_type TEXT DEFAULT 'open',
    status TEXT DEFAULT 'active',

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 3: RALLEY PARTICIPANTS (Join Table)
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
-- TABLE 4: POSTS
-- ============================================
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,

    content TEXT NOT NULL,
    image_url TEXT,
    post_type TEXT DEFAULT 'standard',

    -- Optional link to ralley
    ralley_id UUID REFERENCES ralleys(id) ON DELETE SET NULL,

    -- Likes stored as JSONB array of user IDs (no separate table)
    likes JSONB DEFAULT '[]'::jsonb,
    -- Example: ["uuid-1", "uuid-2", "uuid-3"]

    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    visibility TEXT DEFAULT 'everyone',

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE 5: FRIENDSHIPS
-- ============================================
CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'accepted',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, friend_id),
    CHECK (user_id != friend_id)
);

-- ============================================
-- TABLE 6: COMMENTS
-- ============================================
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES (for fast queries)
-- ============================================
CREATE INDEX idx_users_username ON club_users(username);
CREATE INDEX idx_users_location ON club_users(city, state);
CREATE INDEX idx_ralleys_host ON ralleys(host_user_id);
CREATE INDEX idx_ralleys_datetime ON ralleys(date_time);
CREATE INDEX idx_ralleys_location ON ralleys(city, state);
CREATE INDEX idx_ralleys_status ON ralleys(status) WHERE status = 'active';
CREATE INDEX idx_participants_ralley ON ralley_participants(ralley_id);
CREATE INDEX idx_participants_user ON ralley_participants(user_id);
CREATE INDEX idx_posts_user ON posts(user_id);
CREATE INDEX idx_posts_created ON posts(created_at DESC);
CREATE INDEX idx_posts_ralley ON posts(ralley_id) WHERE ralley_id IS NOT NULL;
CREATE INDEX idx_friendships_user ON friendships(user_id);
CREATE INDEX idx_friendships_friend ON friendships(friend_id);
CREATE INDEX idx_comments_post ON comments(post_id);
CREATE INDEX idx_comments_user ON comments(user_id);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================
ALTER TABLE club_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ralleys ENABLE ROW LEVEL SECURITY;
ALTER TABLE ralley_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Permissive policies for development (tighten for production)
CREATE POLICY "allow_all" ON club_users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON ralleys FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON ralley_participants FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON posts FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON friendships FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON comments FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- AUTO-UPDATE TIMESTAMP TRIGGER
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_timestamp
    BEFORE UPDATE ON club_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_ralleys_timestamp
    BEFORE UPDATE ON ralleys
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

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
