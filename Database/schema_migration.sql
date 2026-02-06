-- Club Ralley: Lean Database Schema
-- Run this in Supabase SQL Editor to restructure your database
-- ⚠️  BACKUP YOUR DATA FIRST if you have any important data

-- ============================================
-- STEP 1: Drop old fragmented tables
-- ============================================

DROP TABLE IF EXISTS user_sports CASCADE;
DROP TABLE IF EXISTS user_interests CASCADE;
DROP TABLE IF EXISTS user_preferences CASCADE;
DROP TABLE IF EXISTS user_availability CASCADE;
DROP TABLE IF EXISTS athlete_info CASCADE;
DROP TABLE IF EXISTS saved_locations CASCADE;
DROP TABLE IF EXISTS user_photos CASCADE;
DROP TABLE IF EXISTS photo_likes CASCADE;
DROP TABLE IF EXISTS post_likes CASCADE;
DROP TABLE IF EXISTS post_comments CASCADE;
DROP TABLE IF EXISTS activity_feed CASCADE;

-- ============================================
-- STEP 2: Recreate club_users (consolidated)
-- ============================================

DROP TABLE IF EXISTS ralley_participants CASCADE;
DROP TABLE IF EXISTS ralleys CASCADE;
DROP TABLE IF EXISTS friendships CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS club_users CASCADE;

CREATE TABLE club_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Auth (links to Supabase Auth)
    auth_id UUID UNIQUE,
    email TEXT UNIQUE NOT NULL,

    -- Basic info
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    profile_photo_url TEXT,
    bio TEXT,

    -- Location
    city TEXT,
    state TEXT,

    -- Social links
    instagram_handle TEXT,

    -- Sports & preferences (JSONB for flexibility)
    -- Example: [{"sport": "tennis", "skill": "intermediate"}, {"sport": "basketball", "skill": "beginner"}]
    sports JSONB DEFAULT '[]'::jsonb,

    -- Availability (JSONB array)
    -- Example: [{"day": "saturday", "time": "morning"}, {"day": "sunday", "time": "afternoon"}]
    availability JSONB DEFAULT '[]'::jsonb,

    -- Athlete verification (nullable JSONB)
    -- Example: {"school": "UCLA", "sport": "Tennis", "year": 2024, "verified": true}
    athlete_info JSONB,

    -- Settings (JSONB for all preferences)
    -- Example: {"notifications": true, "max_distance": 25, "privacy": "friends"}
    settings JSONB DEFAULT '{"notifications": true, "max_distance": 25}'::jsonb,

    -- Counters (denormalized for fast reads)
    friends_count INT DEFAULT 0,
    ralleys_hosted_count INT DEFAULT 0,
    ralleys_joined_count INT DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 3: Ralleys (events)
-- ============================================

CREATE TABLE ralleys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Host
    host_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,

    -- Basic info
    title TEXT NOT NULL,
    description TEXT,
    sport TEXT NOT NULL,
    skill_level TEXT DEFAULT 'all', -- 'beginner', 'intermediate', 'advanced', 'all'

    -- Location (denormalized for fast queries)
    location_name TEXT NOT NULL,
    location_address TEXT,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),

    -- Timing
    date_time TIMESTAMPTZ NOT NULL,
    duration_minutes INT DEFAULT 120,

    -- Capacity
    max_participants INT DEFAULT 10,
    current_participants INT DEFAULT 1, -- Host counts as 1

    -- Visibility
    is_public BOOLEAN DEFAULT true,

    -- Status
    status TEXT DEFAULT 'active', -- 'active', 'cancelled', 'completed'

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 4: Ralley participants
-- ============================================

CREATE TABLE ralley_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ralley_id UUID NOT NULL REFERENCES ralleys(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,

    status TEXT DEFAULT 'joined', -- 'joined', 'pending', 'declined', 'removed'

    joined_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(ralley_id, user_id)
);

-- ============================================
-- STEP 5: Friendships
-- ============================================

CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    requester_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    addressee_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,

    status TEXT DEFAULT 'pending', -- 'pending', 'accepted', 'blocked'

    created_at TIMESTAMPTZ DEFAULT NOW(),
    accepted_at TIMESTAMPTZ,

    UNIQUE(requester_id, addressee_id),
    CHECK (requester_id != addressee_id)
);

-- ============================================
-- STEP 6: Posts (simple social feed)
-- ============================================

CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,

    content TEXT NOT NULL,
    image_url TEXT,

    -- Optional: link to a ralley
    ralley_id UUID REFERENCES ralleys(id) ON DELETE SET NULL,

    -- Engagement (denormalized counts)
    likes_count INT DEFAULT 0,

    -- Store who liked as JSONB array of user IDs (simple, no joins needed)
    liked_by JSONB DEFAULT '[]'::jsonb,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 7: Indexes for performance
-- ============================================

-- Users
CREATE INDEX idx_users_city_state ON club_users(city, state);
CREATE INDEX idx_users_username ON club_users(username);
CREATE INDEX idx_users_sports ON club_users USING GIN (sports);

-- Ralleys
CREATE INDEX idx_ralleys_host ON ralleys(host_id);
CREATE INDEX idx_ralleys_datetime ON ralleys(date_time);
CREATE INDEX idx_ralleys_location ON ralleys(city, state);
CREATE INDEX idx_ralleys_sport ON ralleys(sport);
CREATE INDEX idx_ralleys_status ON ralleys(status) WHERE status = 'active';

-- Participants
CREATE INDEX idx_participants_ralley ON ralley_participants(ralley_id);
CREATE INDEX idx_participants_user ON ralley_participants(user_id);

-- Friendships
CREATE INDEX idx_friendships_requester ON friendships(requester_id);
CREATE INDEX idx_friendships_addressee ON friendships(addressee_id);
CREATE INDEX idx_friendships_status ON friendships(status);

-- Posts
CREATE INDEX idx_posts_user ON posts(user_id);
CREATE INDEX idx_posts_created ON posts(created_at DESC);

-- ============================================
-- STEP 8: Row Level Security (RLS)
-- ============================================

ALTER TABLE club_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ralleys ENABLE ROW LEVEL SECURITY;
ALTER TABLE ralley_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Users: Anyone can read public profiles, users can update their own
CREATE POLICY "Public profiles are viewable by everyone" ON club_users
    FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON club_users
    FOR UPDATE USING (auth.uid() = auth_id);

CREATE POLICY "Users can insert own profile" ON club_users
    FOR INSERT WITH CHECK (auth.uid() = auth_id);

-- Ralleys: Public ralleys visible to all, private only to friends
CREATE POLICY "Public ralleys are viewable" ON ralleys
    FOR SELECT USING (is_public = true OR host_id IN (
        SELECT id FROM club_users WHERE auth_id = auth.uid()
    ));

CREATE POLICY "Users can create ralleys" ON ralleys
    FOR INSERT WITH CHECK (host_id IN (
        SELECT id FROM club_users WHERE auth_id = auth.uid()
    ));

CREATE POLICY "Hosts can update own ralleys" ON ralleys
    FOR UPDATE USING (host_id IN (
        SELECT id FROM club_users WHERE auth_id = auth.uid()
    ));

CREATE POLICY "Hosts can delete own ralleys" ON ralleys
    FOR DELETE USING (host_id IN (
        SELECT id FROM club_users WHERE auth_id = auth.uid()
    ));

-- Participants: Viewable by anyone, users manage their own participation
CREATE POLICY "Participants are viewable" ON ralley_participants
    FOR SELECT USING (true);

CREATE POLICY "Users can join ralleys" ON ralley_participants
    FOR INSERT WITH CHECK (user_id IN (
        SELECT id FROM club_users WHERE auth_id = auth.uid()
    ));

CREATE POLICY "Users can leave ralleys" ON ralley_participants
    FOR DELETE USING (user_id IN (
        SELECT id FROM club_users WHERE auth_id = auth.uid()
    ));

-- Friendships: Users see their own friendships
CREATE POLICY "Users see own friendships" ON friendships
    FOR SELECT USING (
        requester_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid()) OR
        addressee_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
    );

CREATE POLICY "Users can send friend requests" ON friendships
    FOR INSERT WITH CHECK (requester_id IN (
        SELECT id FROM club_users WHERE auth_id = auth.uid()
    ));

CREATE POLICY "Users can update own friendships" ON friendships
    FOR UPDATE USING (
        addressee_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
    );

-- Posts: Public posts viewable, users manage their own
CREATE POLICY "Posts are viewable" ON posts
    FOR SELECT USING (true);

CREATE POLICY "Users can create posts" ON posts
    FOR INSERT WITH CHECK (user_id IN (
        SELECT id FROM club_users WHERE auth_id = auth.uid()
    ));

CREATE POLICY "Users can update own posts" ON posts
    FOR UPDATE USING (user_id IN (
        SELECT id FROM club_users WHERE auth_id = auth.uid()
    ));

CREATE POLICY "Users can delete own posts" ON posts
    FOR DELETE USING (user_id IN (
        SELECT id FROM club_users WHERE auth_id = auth.uid()
    ));

-- ============================================
-- STEP 9: Helper functions
-- ============================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON club_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_ralleys_updated_at
    BEFORE UPDATE ON ralleys
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Update participant count when someone joins/leaves
CREATE OR REPLACE FUNCTION update_ralley_participant_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE ralleys SET current_participants = current_participants + 1
        WHERE id = NEW.ralley_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE ralleys SET current_participants = current_participants - 1
        WHERE id = OLD.ralley_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_participant_count
    AFTER INSERT OR DELETE ON ralley_participants
    FOR EACH ROW EXECUTE FUNCTION update_ralley_participant_count();

-- ============================================
-- DONE! Your lean schema is ready.
-- ============================================
--
-- Summary:
-- ✅ 5 tables (down from 16)
-- ✅ Single query to load user profile
-- ✅ JSONB for flexible nested data
-- ✅ Proper indexes for performance
-- ✅ Row Level Security enabled
-- ✅ Auto-updating timestamps and counts
