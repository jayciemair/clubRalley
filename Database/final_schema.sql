-- ============================================
-- CLUB RALLEY: FINAL PRODUCTION SCHEMA
-- ============================================
-- Run this entire script in Supabase SQL Editor
-- This creates all 11 tables needed for full app functionality
-- ============================================

-- ============================================
-- STEP 1: Clean slate - drop all existing tables
-- ============================================
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS user_reports CASCADE;
DROP TABLE IF EXISTS blocked_users CASCADE;
DROP TABLE IF EXISTS post_reports CASCADE;
DROP TABLE IF EXISTS reposts CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS post_likes CASCADE;
DROP TABLE IF EXISTS ralley_post_opt_outs CASCADE;
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS direct_messages CASCADE;
DROP TABLE IF EXISTS ralley_participants CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS friendships CASCADE;
DROP TABLE IF EXISTS ralleys CASCADE;
DROP TABLE IF EXISTS club_users CASCADE;

-- Drop old tables that may exist from previous schemas
DROP TABLE IF EXISTS post_comments CASCADE;
DROP TABLE IF EXISTS user_sports CASCADE;
DROP TABLE IF EXISTS user_interests CASCADE;
DROP TABLE IF EXISTS user_preferences CASCADE;
DROP TABLE IF EXISTS user_availability CASCADE;
DROP TABLE IF EXISTS athlete_info CASCADE;
DROP TABLE IF EXISTS saved_locations CASCADE;
DROP TABLE IF EXISTS user_photos CASCADE;
DROP TABLE IF EXISTS photo_likes CASCADE;
DROP TABLE IF EXISTS activity_feed CASCADE;
DROP TABLE IF EXISTS chat_members CASCADE;

-- ============================================
-- STEP 2: Create club_users table
-- ============================================
CREATE TABLE club_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Auth (links to Supabase Auth)
    auth_id UUID UNIQUE,
    email TEXT UNIQUE NOT NULL,

    -- Basic info
    first_name TEXT NOT NULL DEFAULT '',
    last_name TEXT NOT NULL DEFAULT '',
    username TEXT UNIQUE NOT NULL,
    profile_photo_url TEXT,
    bio TEXT,

    -- Location
    city TEXT,
    state TEXT,

    -- Social links
    instagram_handle TEXT,

    -- Verification
    is_verified_athlete BOOLEAN DEFAULT false,

    -- JSONB columns for flexible nested data
    sports JSONB DEFAULT '[]'::jsonb,
    -- Example: [{"sport": "tennis", "skill": "intermediate"}, {"sport": "basketball", "skill": "beginner"}]

    availability JSONB DEFAULT '[]'::jsonb,
    -- Example: [{"day": "saturday", "time": "morning"}, {"day": "sunday", "time": "afternoon"}]

    athlete_info JSONB,
    -- Example: {"school": "UCLA", "sport": "Tennis", "year": 2024, "verified": true}

    preferences JSONB DEFAULT '{}'::jsonb,
    -- Example: {"notifications": true, "max_distance": 25, "privacy": "friends"}

    -- Denormalized counts for fast reads
    friends_count INT DEFAULT 0,
    ralleys_count INT DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 3: Create ralleys table
-- ============================================
CREATE TABLE ralleys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Host (primary column name used by code)
    host_user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,

    -- Basic info
    title TEXT NOT NULL,
    description TEXT,
    sport TEXT NOT NULL,
    skill_level TEXT DEFAULT 'all',  -- 'beginner', 'intermediate', 'advanced', 'all'

    -- Location
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
    min_participants INT DEFAULT 2,
    current_participants INT DEFAULT 1,  -- Host counts as 1

    -- Visibility & access
    is_public BOOLEAN DEFAULT true,
    visibility TEXT DEFAULT 'anyone',  -- 'anyone', 'mutual_friends', 'friends'
    join_type TEXT DEFAULT 'open',      -- 'open', 'approval_required'

    -- Status
    status TEXT DEFAULT 'active',  -- 'active', 'cancelled', 'completed'

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add computed column for backward compatibility with code using host_id
ALTER TABLE ralleys ADD COLUMN host_id UUID GENERATED ALWAYS AS (host_user_id) STORED;

-- ============================================
-- STEP 4: Create ralley_participants table
-- ============================================
CREATE TABLE ralley_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ralley_id UUID NOT NULL REFERENCES ralleys(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,

    -- Status: 'joined', 'pending', 'declined', 'removed'
    status TEXT DEFAULT 'joined',

    joined_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(ralley_id, user_id)
);

-- ============================================
-- STEP 5: Create friendships table
-- ============================================
CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Primary column names used by most code
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,

    -- Status: 'pending', 'accepted', 'blocked'
    status TEXT DEFAULT 'accepted',

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, friend_id),
    CHECK (user_id != friend_id)
);

-- Add computed columns for backward compatibility
ALTER TABLE friendships ADD COLUMN requester_id UUID GENERATED ALWAYS AS (user_id) STORED;
ALTER TABLE friendships ADD COLUMN addressee_id UUID GENERATED ALWAYS AS (friend_id) STORED;

-- ============================================
-- STEP 6: Create posts table
-- ============================================
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,

    -- Content
    content TEXT NOT NULL,
    image_url TEXT,
    images JSONB DEFAULT '[]'::jsonb,  -- Array of image URLs

    -- Type: 'standard', 'ralley_completion', 'repost'
    post_type TEXT DEFAULT 'standard',

    -- Optional link to a ralley
    ralley_id UUID REFERENCES ralleys(id) ON DELETE SET NULL,

    -- Tagged users
    tagged_user_ids UUID[],

    -- External link
    link_url TEXT,

    -- Repost support
    original_post_id UUID REFERENCES posts(id) ON DELETE SET NULL,
    repost_comment TEXT,

    -- Engagement (denormalized counts for fast reads)
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    shares_count INT DEFAULT 0,

    -- Visibility: 'everyone', 'friends', 'private'
    visibility TEXT DEFAULT 'everyone',

    -- Likes stored as JSONB array of user IDs (no separate table needed)
    likes JSONB DEFAULT '[]'::jsonb,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 7: Create comments table
-- ============================================
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 8: Create direct_messages table
-- ============================================
CREATE TABLE direct_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 9: Create chat_messages table (ralley group chats)
-- Uses ralley_id as chat_id (no separate chats table needed)
-- ============================================
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ralley_id UUID NOT NULL REFERENCES ralleys(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text',  -- 'text' or 'system'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 10: Create notifications table
-- ============================================
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,

    -- Type: 'new_follower', 'like', 'comment', 'ralley_join', 'ralley_reminder', 'mention', 'message'
    type TEXT NOT NULL,

    -- Who triggered the notification (optional)
    actor_id UUID REFERENCES club_users(id) ON DELETE SET NULL,

    -- Related entities (optional)
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    ralley_id UUID REFERENCES ralleys(id) ON DELETE CASCADE,

    -- Human-readable message
    message TEXT NOT NULL,

    -- Read status
    is_read BOOLEAN DEFAULT false,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 11: Create ralley_post_opt_outs table
-- For users who don't want to be tagged in ralley completion posts
-- ============================================
CREATE TABLE ralley_post_opt_outs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ralley_id UUID NOT NULL REFERENCES ralleys(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(ralley_id, user_id)
);

-- ============================================
-- STEP 12: Create indexes for performance
-- ============================================

-- Users
CREATE INDEX idx_users_username ON club_users(username);
CREATE INDEX idx_users_city_state ON club_users(city, state);
CREATE INDEX idx_users_sports ON club_users USING GIN (sports);
CREATE INDEX idx_users_email ON club_users(email);

-- Ralleys
CREATE INDEX idx_ralleys_host ON ralleys(host_user_id);
CREATE INDEX idx_ralleys_datetime ON ralleys(date_time);
CREATE INDEX idx_ralleys_location ON ralleys(city, state);
CREATE INDEX idx_ralleys_sport ON ralleys(sport);
CREATE INDEX idx_ralleys_status ON ralleys(status) WHERE status = 'active';
CREATE INDEX idx_ralleys_upcoming ON ralleys(date_time) WHERE status = 'active' AND date_time > NOW();

-- Participants
CREATE INDEX idx_participants_ralley ON ralley_participants(ralley_id);
CREATE INDEX idx_participants_user ON ralley_participants(user_id);
CREATE INDEX idx_participants_status ON ralley_participants(status);

-- Friendships
CREATE INDEX idx_friendships_user ON friendships(user_id);
CREATE INDEX idx_friendships_friend ON friendships(friend_id);
CREATE INDEX idx_friendships_status ON friendships(status);

-- Posts
CREATE INDEX idx_posts_user ON posts(user_id);
CREATE INDEX idx_posts_created ON posts(created_at DESC);
CREATE INDEX idx_posts_ralley ON posts(ralley_id) WHERE ralley_id IS NOT NULL;
CREATE INDEX idx_posts_type ON posts(post_type);

-- Comments
CREATE INDEX idx_comments_post ON comments(post_id);
CREATE INDEX idx_comments_user ON comments(user_id);
CREATE INDEX idx_comments_created ON comments(created_at DESC);

-- Direct messages
CREATE INDEX idx_dm_sender ON direct_messages(sender_id);
CREATE INDEX idx_dm_recipient ON direct_messages(recipient_id);
CREATE INDEX idx_dm_created ON direct_messages(created_at DESC);
CREATE INDEX idx_dm_unread ON direct_messages(recipient_id) WHERE is_read = false;
-- Conversation index for efficient conversation queries
CREATE INDEX idx_dm_conversation ON direct_messages(
    LEAST(sender_id, recipient_id),
    GREATEST(sender_id, recipient_id),
    created_at DESC
);

-- Chat messages
CREATE INDEX idx_chat_ralley ON chat_messages(ralley_id);
CREATE INDEX idx_chat_created ON chat_messages(ralley_id, created_at DESC);
CREATE INDEX idx_chat_sender ON chat_messages(sender_id);

-- Notifications
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id) WHERE is_read = false;

-- ============================================
-- STEP 13: Enable Row Level Security
-- ============================================
ALTER TABLE club_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ralleys ENABLE ROW LEVEL SECURITY;
ALTER TABLE ralley_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE direct_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE ralley_post_opt_outs ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 14: Create RLS policies
-- Using permissive policies for development
-- TODO: Tighten these for production
-- ============================================
CREATE POLICY "allow_all" ON club_users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON ralleys FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON ralley_participants FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON friendships FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON posts FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON comments FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON direct_messages FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON chat_messages FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON notifications FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all" ON ralley_post_opt_outs FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- STEP 15: Create helper functions and triggers
-- ============================================

-- Function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables with updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON club_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_ralleys_updated_at
    BEFORE UPDATE ON ralleys
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_posts_updated_at
    BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Function to auto-update participant count
CREATE OR REPLACE FUNCTION update_ralley_participant_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.status = 'joined' THEN
        UPDATE ralleys SET current_participants = current_participants + 1 WHERE id = NEW.ralley_id;
    ELSIF TG_OP = 'DELETE' AND OLD.status = 'joined' THEN
        UPDATE ralleys SET current_participants = current_participants - 1 WHERE id = OLD.ralley_id;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Handle status changes
        IF OLD.status != 'joined' AND NEW.status = 'joined' THEN
            UPDATE ralleys SET current_participants = current_participants + 1 WHERE id = NEW.ralley_id;
        ELSIF OLD.status = 'joined' AND NEW.status != 'joined' THEN
            UPDATE ralleys SET current_participants = current_participants - 1 WHERE id = NEW.ralley_id;
        END IF;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_participant_count
    AFTER INSERT OR UPDATE OR DELETE ON ralley_participants
    FOR EACH ROW EXECUTE FUNCTION update_ralley_participant_count();

-- Function to auto-update comments count on posts
CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET comments_count = comments_count - 1 WHERE id = OLD.post_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_comments_count
    AFTER INSERT OR DELETE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();

-- Function to create notification when someone joins a ralley
CREATE OR REPLACE FUNCTION notify_ralley_join()
RETURNS TRIGGER AS $$
DECLARE
    ralley_record RECORD;
    joiner_name TEXT;
BEGIN
    IF NEW.status = 'joined' AND (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status != 'joined')) THEN
        -- Get ralley info
        SELECT title, host_user_id INTO ralley_record FROM ralleys WHERE id = NEW.ralley_id;

        -- Get joiner name
        SELECT first_name || ' ' || last_name INTO joiner_name FROM club_users WHERE id = NEW.user_id;

        -- Don't notify if host is joining their own ralley
        IF NEW.user_id != ralley_record.host_user_id THEN
            INSERT INTO notifications (user_id, type, actor_id, ralley_id, message)
            VALUES (
                ralley_record.host_user_id,
                'ralley_join',
                NEW.user_id,
                NEW.ralley_id,
                joiner_name || ' joined your ralley "' || ralley_record.title || '"'
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notify_on_ralley_join
    AFTER INSERT OR UPDATE ON ralley_participants
    FOR EACH ROW EXECUTE FUNCTION notify_ralley_join();

-- Function to create notification when someone follows a user
CREATE OR REPLACE FUNCTION notify_new_follower()
RETURNS TRIGGER AS $$
DECLARE
    follower_name TEXT;
BEGIN
    IF NEW.status = 'accepted' THEN
        -- Get follower name
        SELECT first_name || ' ' || last_name INTO follower_name FROM club_users WHERE id = NEW.user_id;

        INSERT INTO notifications (user_id, type, actor_id, message)
        VALUES (
            NEW.friend_id,
            'new_follower',
            NEW.user_id,
            follower_name || ' started following you'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notify_on_new_follower
    AFTER INSERT ON friendships
    FOR EACH ROW EXECUTE FUNCTION notify_new_follower();

-- Function to create notification when someone comments on a post
CREATE OR REPLACE FUNCTION notify_post_comment()
RETURNS TRIGGER AS $$
DECLARE
    post_owner_id UUID;
    commenter_name TEXT;
BEGIN
    -- Get post owner
    SELECT user_id INTO post_owner_id FROM posts WHERE id = NEW.post_id;

    -- Don't notify if commenting on own post
    IF NEW.user_id != post_owner_id THEN
        -- Get commenter name
        SELECT first_name || ' ' || last_name INTO commenter_name FROM club_users WHERE id = NEW.user_id;

        INSERT INTO notifications (user_id, type, actor_id, post_id, message)
        VALUES (
            post_owner_id,
            'comment',
            NEW.user_id,
            NEW.post_id,
            commenter_name || ' commented on your post'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notify_on_post_comment
    AFTER INSERT ON comments
    FOR EACH ROW EXECUTE FUNCTION notify_post_comment();

-- ============================================
-- STEP 16: Enable Realtime for key tables
-- ============================================
-- Note: Run these in Supabase Dashboard > Database > Replication
-- or uncomment if running as superuser

-- ALTER PUBLICATION supabase_realtime ADD TABLE direct_messages;
-- ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
-- ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
-- ALTER PUBLICATION supabase_realtime ADD TABLE ralley_participants;

-- ============================================
-- STEP 17: Reload schema cache
-- ============================================
NOTIFY pgrst, 'reload schema';

-- ============================================
-- STEP 18: Verify installation
-- ============================================
SELECT
    'SUCCESS: ' || count(*) || ' tables created!' as status,
    string_agg(table_name, ', ' ORDER BY table_name) as tables
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE';

-- ============================================
-- SCHEMA COMPLETE!
-- ============================================
--
-- Tables created (11):
-- 1. club_users - User profiles
-- 2. ralleys - Events/activities
-- 3. ralley_participants - Event attendance
-- 4. friendships - Follow relationships
-- 5. posts - Social feed
-- 6. comments - Post comments
-- 7. direct_messages - 1-on-1 DMs
-- 8. chat_messages - Group chats
-- 9. notifications - User notifications
-- 10. ralley_post_opt_outs - Tag opt-outs
--
-- Triggers created:
-- - Auto-update updated_at timestamps
-- - Auto-update participant counts
-- - Auto-update comment counts
-- - Auto-create notifications for joins, follows, comments
--
-- Next steps:
-- 1. Enable Realtime in Supabase Dashboard for messaging tables
-- 2. Run the app and test all features
-- ============================================
