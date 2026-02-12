-- Club Ralley: Complete Database Setup
-- Copy this entire file and paste into Supabase SQL Editor, then click Run

-- ============================================
-- Drop existing tables (clean slate)
-- ============================================
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS direct_messages CASCADE;
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS ralley_post_opt_outs CASCADE;
DROP TABLE IF EXISTS ralley_participants CASCADE;
DROP TABLE IF EXISTS posts CASCADE;
DROP TABLE IF EXISTS ralleys CASCADE;
DROP TABLE IF EXISTS friendships CASCADE;
DROP TABLE IF EXISTS club_users CASCADE;

-- ============================================
-- 1. Users Table
-- ============================================
CREATE TABLE club_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_id UUID UNIQUE,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    username TEXT UNIQUE NOT NULL,
    profile_photo_url TEXT,
    bio TEXT,
    city TEXT,
    state TEXT,
    instagram_handle TEXT,
    sports JSONB DEFAULT '[]'::jsonb,
    availability JSONB DEFAULT '[]'::jsonb,
    athlete_info JSONB,
    settings JSONB DEFAULT '{"notifications": true, "max_distance": 25}'::jsonb,
    friends_count INT DEFAULT 0,
    ralleys_hosted_count INT DEFAULT 0,
    ralleys_joined_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. Ralleys Table
-- ============================================
CREATE TABLE ralleys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    sport TEXT NOT NULL,
    skill_level TEXT DEFAULT 'all',
    location_name TEXT NOT NULL,
    location_address TEXT,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    date_time TIMESTAMPTZ NOT NULL,
    duration_minutes INT DEFAULT 120,
    max_participants INT DEFAULT 10,
    current_participants INT DEFAULT 1,
    is_public BOOLEAN DEFAULT true,
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. Ralley Participants Table
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
-- 4. Friendships Table
-- ============================================
CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    addressee_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    accepted_at TIMESTAMPTZ,
    UNIQUE(requester_id, addressee_id),
    CHECK (requester_id != addressee_id)
);

-- ============================================
-- 5. Posts Table
-- ============================================
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_url TEXT,
    post_type TEXT DEFAULT 'text',
    visibility TEXT DEFAULT 'everyone',
    ralley_id UUID REFERENCES ralleys(id) ON DELETE SET NULL,
    tagged_user_ids UUID[] DEFAULT '{}',
    link_url TEXT,
    original_post_id UUID REFERENCES posts(id) ON DELETE SET NULL,
    repost_comment TEXT,
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    shares_count INT DEFAULT 0,
    liked_by JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 6. Comments Table (for post comments)
-- ============================================
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 7. Chat Messages Table (for ralley group chats)
-- ============================================
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ralley_id UUID NOT NULL REFERENCES ralleys(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES club_users(id) ON DELETE SET NULL,
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text',
    is_system_message BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 8. Direct Messages Table (for DMs between users)
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
-- 9. Notifications Table
-- ============================================
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN DEFAULT false,
    from_user_id UUID REFERENCES club_users(id) ON DELETE SET NULL,
    ralley_id UUID REFERENCES ralleys(id) ON DELETE SET NULL,
    post_id UUID REFERENCES posts(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 10. Ralley Post Opt-Outs Table
-- ============================================
CREATE TABLE ralley_post_opt_outs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ralley_id UUID NOT NULL REFERENCES ralleys(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(ralley_id, user_id)
);

-- ============================================
-- Indexes for Performance
-- ============================================
CREATE INDEX idx_users_username ON club_users(username);
CREATE INDEX idx_users_city_state ON club_users(city, state);
CREATE INDEX idx_users_auth_id ON club_users(auth_id);

CREATE INDEX idx_ralleys_host ON ralleys(host_id);
CREATE INDEX idx_ralleys_datetime ON ralleys(date_time);
CREATE INDEX idx_ralleys_location ON ralleys(city, state);
CREATE INDEX idx_ralleys_status ON ralleys(status) WHERE status = 'active';

CREATE INDEX idx_participants_ralley ON ralley_participants(ralley_id);
CREATE INDEX idx_participants_user ON ralley_participants(user_id);

CREATE INDEX idx_friendships_requester ON friendships(requester_id);
CREATE INDEX idx_friendships_addressee ON friendships(addressee_id);

CREATE INDEX idx_posts_user ON posts(user_id);
CREATE INDEX idx_posts_created ON posts(created_at DESC);
CREATE INDEX idx_posts_ralley ON posts(ralley_id);

CREATE INDEX idx_comments_post ON comments(post_id);
CREATE INDEX idx_comments_user ON comments(user_id);

CREATE INDEX idx_chat_messages_ralley ON chat_messages(ralley_id);
CREATE INDEX idx_chat_messages_created ON chat_messages(created_at);

CREATE INDEX idx_direct_messages_sender ON direct_messages(sender_id);
CREATE INDEX idx_direct_messages_recipient ON direct_messages(recipient_id);
CREATE INDEX idx_direct_messages_created ON direct_messages(created_at DESC);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id) WHERE is_read = false;

-- ============================================
-- Row Level Security
-- ============================================
ALTER TABLE club_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE ralleys ENABLE ROW LEVEL SECURITY;
ALTER TABLE ralley_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE direct_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE ralley_post_opt_outs ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Anyone can view users" ON club_users FOR SELECT USING (true);
CREATE POLICY "Users can insert own profile" ON club_users FOR INSERT WITH CHECK (auth.uid() = auth_id);
CREATE POLICY "Users can update own profile" ON club_users FOR UPDATE USING (auth.uid() = auth_id);

-- Ralleys policies
CREATE POLICY "Anyone can view ralleys" ON ralleys FOR SELECT USING (true);
CREATE POLICY "Users can create ralleys" ON ralleys FOR INSERT WITH CHECK (
    host_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);
CREATE POLICY "Hosts can update own ralleys" ON ralleys FOR UPDATE USING (
    host_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);
CREATE POLICY "Hosts can delete own ralleys" ON ralleys FOR DELETE USING (
    host_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

-- Participants policies
CREATE POLICY "Anyone can view participants" ON ralley_participants FOR SELECT USING (true);
CREATE POLICY "Users can join ralleys" ON ralley_participants FOR INSERT WITH CHECK (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);
CREATE POLICY "Users can leave ralleys" ON ralley_participants FOR DELETE USING (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);
CREATE POLICY "Users can update participation" ON ralley_participants FOR UPDATE USING (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

-- Friendships policies
CREATE POLICY "Users see own friendships" ON friendships FOR SELECT USING (
    requester_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid()) OR
    addressee_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);
CREATE POLICY "Users can send friend requests" ON friendships FOR INSERT WITH CHECK (
    requester_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);
CREATE POLICY "Users can update friendships" ON friendships FOR UPDATE USING (
    requester_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid()) OR
    addressee_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);
CREATE POLICY "Users can delete friendships" ON friendships FOR DELETE USING (
    requester_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid()) OR
    addressee_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

-- Posts policies
CREATE POLICY "Anyone can view posts" ON posts FOR SELECT USING (true);
CREATE POLICY "Users can create posts" ON posts FOR INSERT WITH CHECK (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);
CREATE POLICY "Users can update own posts" ON posts FOR UPDATE USING (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);
CREATE POLICY "Users can delete own posts" ON posts FOR DELETE USING (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

-- Comments policies
CREATE POLICY "Anyone can view comments" ON comments FOR SELECT USING (true);
CREATE POLICY "Users can create comments" ON comments FOR INSERT WITH CHECK (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);
CREATE POLICY "Users can delete own comments" ON comments FOR DELETE USING (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

-- Chat messages policies
CREATE POLICY "Participants can view chat messages" ON chat_messages FOR SELECT USING (
    ralley_id IN (
        SELECT ralley_id FROM ralley_participants
        WHERE user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
    ) OR
    ralley_id IN (
        SELECT id FROM ralleys
        WHERE host_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
    )
);
CREATE POLICY "Participants can send chat messages" ON chat_messages FOR INSERT WITH CHECK (
    sender_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

-- Direct messages policies
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

-- Notifications policies
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);
CREATE POLICY "System can create notifications" ON notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

-- Opt-outs policies
CREATE POLICY "Anyone can view opt-outs" ON ralley_post_opt_outs FOR SELECT USING (true);
CREATE POLICY "Users can opt out" ON ralley_post_opt_outs FOR INSERT WITH CHECK (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);
CREATE POLICY "Users can remove opt out" ON ralley_post_opt_outs FOR DELETE USING (
    user_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

-- ============================================
-- Auto-update timestamps
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_timestamp BEFORE UPDATE ON club_users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_ralleys_timestamp BEFORE UPDATE ON ralleys
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- Auto-update participant count
-- ============================================
CREATE OR REPLACE FUNCTION update_participant_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.status = 'joined' THEN
        UPDATE ralleys SET current_participants = current_participants + 1 WHERE id = NEW.ralley_id;
    ELSIF TG_OP = 'DELETE' AND OLD.status = 'joined' THEN
        UPDATE ralleys SET current_participants = current_participants - 1 WHERE id = OLD.ralley_id;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status != 'joined' AND NEW.status = 'joined' THEN
            UPDATE ralleys SET current_participants = current_participants + 1 WHERE id = NEW.ralley_id;
        ELSIF OLD.status = 'joined' AND NEW.status != 'joined' THEN
            UPDATE ralleys SET current_participants = current_participants - 1 WHERE id = NEW.ralley_id;
        END IF;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_ralley_participants AFTER INSERT OR UPDATE OR DELETE ON ralley_participants
    FOR EACH ROW EXECUTE FUNCTION update_participant_count();

-- ============================================
-- 11. Reports Table
-- ============================================
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    reported_type TEXT NOT NULL CHECK (reported_type IN ('post', 'user', 'ralley', 'comment')),
    reported_id UUID NOT NULL,
    reason TEXT NOT NULL,
    additional_context TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES club_users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reports indexes
CREATE INDEX idx_reports_reporter ON reports(reporter_id);
CREATE INDEX idx_reports_status ON reports(status) WHERE status = 'pending';
CREATE INDEX idx_reports_type ON reports(reported_type, reported_id);

-- Reports RLS
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can create reports" ON reports FOR INSERT WITH CHECK (
    reporter_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

CREATE POLICY "Users can view own reports" ON reports FOR SELECT USING (
    reporter_id IN (SELECT id FROM club_users WHERE auth_id = auth.uid())
);

-- ============================================
-- Count Sync Triggers
-- ============================================

-- Function to update friends_count on club_users
CREATE OR REPLACE FUNCTION update_friends_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.status = 'accepted' THEN
        -- Increment count for both users in the friendship
        UPDATE club_users SET friends_count = friends_count + 1 WHERE id = NEW.requester_id;
        UPDATE club_users SET friends_count = friends_count + 1 WHERE id = NEW.addressee_id;
    ELSIF TG_OP = 'DELETE' AND OLD.status = 'accepted' THEN
        -- Decrement count for both users
        UPDATE club_users SET friends_count = GREATEST(0, friends_count - 1) WHERE id = OLD.requester_id;
        UPDATE club_users SET friends_count = GREATEST(0, friends_count - 1) WHERE id = OLD.addressee_id;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status != 'accepted' AND NEW.status = 'accepted' THEN
            UPDATE club_users SET friends_count = friends_count + 1 WHERE id = NEW.requester_id;
            UPDATE club_users SET friends_count = friends_count + 1 WHERE id = NEW.addressee_id;
        ELSIF OLD.status = 'accepted' AND NEW.status != 'accepted' THEN
            UPDATE club_users SET friends_count = GREATEST(0, friends_count - 1) WHERE id = NEW.requester_id;
            UPDATE club_users SET friends_count = GREATEST(0, friends_count - 1) WHERE id = NEW.addressee_id;
        END IF;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_friends_count
AFTER INSERT OR UPDATE OR DELETE ON friendships
FOR EACH ROW EXECUTE FUNCTION update_friends_count();

-- Function to update ralleys_hosted_count on club_users
CREATE OR REPLACE FUNCTION update_ralleys_hosted_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE club_users SET ralleys_hosted_count = ralleys_hosted_count + 1 WHERE id = NEW.host_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE club_users SET ralleys_hosted_count = GREATEST(0, ralleys_hosted_count - 1) WHERE id = OLD.host_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_ralleys_hosted_count
AFTER INSERT OR DELETE ON ralleys
FOR EACH ROW EXECUTE FUNCTION update_ralleys_hosted_count();

-- Function to update ralleys_joined_count on club_users
CREATE OR REPLACE FUNCTION update_ralleys_joined_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.status = 'joined' THEN
        UPDATE club_users SET ralleys_joined_count = ralleys_joined_count + 1 WHERE id = NEW.user_id;
    ELSIF TG_OP = 'DELETE' AND OLD.status = 'joined' THEN
        UPDATE club_users SET ralleys_joined_count = GREATEST(0, ralleys_joined_count - 1) WHERE id = OLD.user_id;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status != 'joined' AND NEW.status = 'joined' THEN
            UPDATE club_users SET ralleys_joined_count = ralleys_joined_count + 1 WHERE id = NEW.user_id;
        ELSIF OLD.status = 'joined' AND NEW.status != 'joined' THEN
            UPDATE club_users SET ralleys_joined_count = GREATEST(0, ralleys_joined_count - 1) WHERE id = NEW.user_id;
        END IF;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_ralleys_joined_count
AFTER INSERT OR UPDATE OR DELETE ON ralley_participants
FOR EACH ROW EXECUTE FUNCTION update_ralleys_joined_count();

-- ============================================
-- Server-side Location Filtering RPC
-- ============================================

-- Function to get nearby ralleys with optional distance calculation
CREATE OR REPLACE FUNCTION get_nearby_ralleys(
    user_lat DECIMAL DEFAULT NULL,
    user_lon DECIMAL DEFAULT NULL,
    radius_km INT DEFAULT 50,
    max_results INT DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    host_id UUID,
    title TEXT,
    description TEXT,
    sport TEXT,
    skill_level TEXT,
    location_name TEXT,
    location_address TEXT,
    city TEXT,
    state TEXT,
    latitude DECIMAL,
    longitude DECIMAL,
    date_time TIMESTAMPTZ,
    duration_minutes INT,
    max_participants INT,
    current_participants INT,
    is_public BOOLEAN,
    status TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    distance_km DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.id,
        r.host_id,
        r.title,
        r.description,
        r.sport,
        r.skill_level,
        r.location_name,
        r.location_address,
        r.city,
        r.state,
        r.latitude,
        r.longitude,
        r.date_time,
        r.duration_minutes,
        r.max_participants,
        r.current_participants,
        r.is_public,
        r.status,
        r.created_at,
        r.updated_at,
        -- Calculate distance using Haversine formula if coordinates provided
        CASE
            WHEN user_lat IS NOT NULL AND user_lon IS NOT NULL AND r.latitude IS NOT NULL AND r.longitude IS NOT NULL THEN
                ROUND(
                    6371 * ACOS(
                        COS(RADIANS(user_lat)) * COS(RADIANS(r.latitude)) *
                        COS(RADIANS(r.longitude) - RADIANS(user_lon)) +
                        SIN(RADIANS(user_lat)) * SIN(RADIANS(r.latitude))
                    )::DECIMAL
                , 2)
            ELSE NULL
        END AS distance_km
    FROM ralleys r
    WHERE r.status = 'active'
      AND r.date_time > NOW()
      AND (
          user_lat IS NULL OR user_lon IS NULL OR r.latitude IS NULL OR r.longitude IS NULL
          OR (
              6371 * ACOS(
                  COS(RADIANS(user_lat)) * COS(RADIANS(r.latitude)) *
                  COS(RADIANS(r.longitude) - RADIANS(user_lon)) +
                  SIN(RADIANS(user_lat)) * SIN(RADIANS(r.latitude))
              ) <= radius_km
          )
      )
    ORDER BY r.date_time ASC
    LIMIT max_results;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- Done! Your database is ready.
-- Tables created:
-- 1. club_users - User profiles
-- 2. ralleys - Ralley events
-- 3. ralley_participants - Who joined which ralley
-- 4. friendships - Friend/follow relationships
-- 5. posts - Social feed posts
-- 6. comments - Post comments
-- 7. chat_messages - Ralley group chat messages
-- 8. direct_messages - DMs between users
-- 9. notifications - User notifications
-- 10. ralley_post_opt_outs - Opt out of auto-posts
-- 11. reports - User/post reports for moderation
--
-- Triggers:
-- - update_participant_count: Syncs ralley participant counts
-- - update_user_friends_count: Syncs user friends_count
-- - update_user_ralleys_hosted_count: Syncs ralleys_hosted_count
-- - update_user_ralleys_joined_count: Syncs ralleys_joined_count
--
-- RPC Functions:
-- - get_nearby_ralleys: Server-side location filtering
-- ============================================
