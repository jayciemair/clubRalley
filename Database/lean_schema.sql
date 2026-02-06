-- Club Ralley: LEAN Schema (5 tables only)
-- Uses JSONB for flexibility instead of many tables

-- ============================================
-- Drop everything first
-- ============================================
DROP TABLE IF EXISTS ralley_participants CASCADE;
DROP TABLE IF EXISTS ralleys CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS friendships CASCADE;
DROP TABLE IF EXISTS club_users CASCADE;

-- ============================================
-- 1. USERS (single table with JSONB)
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

    -- JSONB for flexible nested data
    sports JSONB DEFAULT '[]'::jsonb,           -- [{sport: "tennis", skill: "intermediate"}]
    availability JSONB DEFAULT '[]'::jsonb,     -- [{day: "saturday", time: "morning"}]
    preferences JSONB DEFAULT '{}'::jsonb,      -- {max_distance: 25, notifications: true}
    athlete_info JSONB,                         -- {school: "UCLA", verified: true}

    friends_count INT DEFAULT 0,
    ralleys_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. RALLEYS (events)
-- ============================================
CREATE TABLE ralleys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    sport TEXT,

    -- Location
    location_name TEXT,
    city TEXT,
    state TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),

    -- Timing
    date_time TIMESTAMPTZ,

    -- Capacity
    max_participants INT DEFAULT 10,
    current_participants INT DEFAULT 1,

    -- Settings
    visibility TEXT DEFAULT 'anyone',
    status TEXT DEFAULT 'active',

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. RALLEY PARTICIPANTS (join table)
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
-- 4. POSTS (with JSONB for likes/comments)
-- ============================================
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_url TEXT,
    ralley_id UUID REFERENCES ralleys(id) ON DELETE SET NULL,

    -- Use JSONB for engagement (no separate tables needed)
    likes JSONB DEFAULT '[]'::jsonb,            -- [user_id1, user_id2, ...]
    comments JSONB DEFAULT '[]'::jsonb,         -- [{user_id, content, created_at}, ...]

    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    visibility TEXT DEFAULT 'everyone',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 5. FRIENDSHIPS
-- ============================================
CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'accepted',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, friend_id)
);

-- ============================================
-- Indexes
-- ============================================
CREATE INDEX idx_users_username ON club_users(username);
CREATE INDEX idx_ralleys_host ON ralleys(host_user_id);
CREATE INDEX idx_ralleys_datetime ON ralleys(date_time);
CREATE INDEX idx_posts_user ON posts(user_id);
CREATE INDEX idx_posts_created ON posts(created_at DESC);

-- ============================================
-- Enable RLS + Allow All (for dev)
-- ============================================
ALTER TABLE club_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ralleys ENABLE ROW LEVEL SECURITY;
ALTER TABLE ralley_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "allow_all" ON club_users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON ralleys FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON ralley_participants FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON posts FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON friendships FOR ALL USING (true) WITH CHECK (true);

-- Reload schema cache
NOTIFY pgrst, 'reload schema';

SELECT 'SUCCESS: 5 lean tables created!' as status;
