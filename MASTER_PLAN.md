# Club Ralley - Master Implementation Plan

## Overview
Transform Club Ralley into a fully functional social sports app with real Supabase backend integration, supporting multiple user profiles, real-time messaging, ralley creation, and all social features.

---

## Phase 1: Database Schema (Must Run First)
**Time Estimate: 15 minutes**

### 1.1 Create Complete Database Schema
Run the complete schema SQL in Supabase SQL Editor to create all required tables.

**Tables to Create (17 total):**
1. `club_users` - User profiles with JSONB for sports, availability, settings
2. `ralleys` - Events/activities with location, timing, capacity
3. `ralley_participants` - Join table for ralley membership
4. `posts` - Social feed posts
5. `friendships` - Follow/friend relationships (supports both column naming conventions)
6. `comments` - Post comments (renamed from post_comments for code compatibility)
7. `direct_messages` - 1-on-1 DMs
8. `chat_messages` - Group chat messages (using ralley_id as chat_id)
9. `notifications` - User notifications
10. `post_likes` - Like tracking (alternative to JSONB)
11. `reposts` - Repost tracking
12. `post_reports` - Post reporting
13. `user_reports` - User reporting
14. `ralley_post_opt_outs` - Opt-out from completion post tagging
15. `blocked_users` - Block tracking

### 1.2 Create Database Triggers
- Auto-update `updated_at` timestamps
- Auto-update `current_participants` count on ralleys
- Auto-update `likes_count` on posts
- Auto-update `comments_count` on posts

### 1.3 Create Indexes for Performance
- User queries: username, city/state, sports (GIN)
- Ralley queries: host, datetime, location, sport, status
- Message queries: sender, recipient, conversation pairs
- Post queries: user, created_at, ralley

### 1.4 Enable Row Level Security
- Public read access for profiles, ralleys, posts
- User-specific write access for own data
- Proper policies for messaging privacy

---

## Phase 2: Fix Code-Database Mismatches
**Time Estimate: 1 hour**

### 2.1 Standardize Column Names
The code uses different column names than some schema files. Fix these:

| Code Uses | Schema Has | Resolution |
|-----------|------------|------------|
| `host_user_id` | `host_id` | Add BOTH columns to ralleys |
| `user_id`/`friend_id` | `requester_id`/`addressee_id` | Add BOTH pairs to friendships |
| `comments` | `post_comments` | Rename table to `comments` |

### 2.2 Fix Status Value Mismatches
| Feature | Code Uses | Schema Has | Resolution |
|---------|-----------|------------|------------|
| Participants | `"attending"` | `"joined"` | Update code to use `"joined"` |
| Participants | `"requested"` | `"pending"` | Update code to use `"pending"` |

### 2.3 Add Missing Columns
- `ralleys.visibility` (anyone, mutual_friends, friends)
- `ralleys.join_type` (open, approval_required)
- `posts.post_type` (standard, ralley_completion, repost)
- `posts.comments_count`
- `posts.shares_count`
- `posts.tagged_user_ids`
- `posts.original_post_id` (for reposts)
- `posts.repost_comment`

---

## Phase 3: Fix Swift Code Issues
**Time Estimate: 2 hours**

### 3.1 Fix Participant Status Constants
Update RalleyParticipationService.swift and related files:
```swift
// Change from:
status: "attending" → status: "joined"
status: "requested" → status: "pending"
```

### 3.2 Fix Friendship Column References
Update FriendshipService.swift to use consistent column names:
- Support both `user_id`/`friend_id` AND `requester_id`/`addressee_id`

### 3.3 Fix Comments Table Name
Update PostEngagementService.swift:
```swift
// Ensure queries use "comments" (not "post_comments")
```

### 3.4 Add Missing DatabaseNotification Struct
The NotificationsService references `DatabaseNotificationWithUser` but the type may be incomplete.

---

## Phase 4: Implement Real-Time Features
**Time Estimate: 3 hours**

### 4.1 Add Supabase Realtime Subscriptions
Create new file: `Core/Supabase/SupabaseRealtime.swift`

```swift
extension SupabaseManager {
    // Subscribe to direct messages
    func subscribeToDirectMessages(userId: UUID, onMessage: @escaping (DirectMessage) -> Void)

    // Subscribe to group chat messages
    func subscribeToChatMessages(ralleyId: UUID, onMessage: @escaping (GroupChatMessage) -> Void)

    // Subscribe to notifications
    func subscribeToNotifications(userId: UUID, onNotification: @escaping (AppNotification) -> Void)

    // Subscribe to ralley participant changes
    func subscribeToRalleyParticipants(ralleyId: UUID, onChange: @escaping () -> Void)
}
```

### 4.2 Integrate Realtime into MessagingService
- Add channel subscriptions when loading conversations
- Auto-update UI when new messages arrive
- Implement proper unsubscribe on view disappear

### 4.3 Integrate Realtime into ChatService
- Subscribe to chat_messages for active chat
- Update message list in real-time
- Show typing indicators (optional)

### 4.4 Integrate Realtime into NotificationsService
- Subscribe to notifications table
- Update badge count in real-time
- Show in-app notification banners

---

## Phase 5: Multiple Profile Support
**Time Estimate: 2 hours**

### 5.1 Create Profile Switching Architecture
New file: `Core/Services/MultiProfileManager.swift`

```swift
@MainActor
class MultiProfileManager: ObservableObject {
    @Published var savedProfiles: [SavedUserProfile] = []
    @Published var activeProfile: SavedUserProfile?

    func loadSavedProfiles() -> [SavedUserProfile]
    func switchToProfile(_ profile: SavedUserProfile) async throws
    func addProfile(_ profile: SavedUserProfile)
    func removeProfile(_ profileId: UUID)
    func saveAllProfiles()
}
```

### 5.2 Update SavedUserProfile Model
Enhance to store multiple profiles in UserDefaults:
```swift
struct SavedUserProfile: Codable {
    // Existing fields...
    var isActive: Bool  // Which profile is currently active
    var lastUsed: Date  // For sorting
}

// Storage key changes from "currentUserProfile" to "savedUserProfiles" (array)
```

### 5.3 Create Profile Switcher UI
New file: `Views/Settings/ProfileSwitcherView.swift`
- List of saved profiles with avatars
- "Add Account" button
- Swipe to remove profile
- Tap to switch

### 5.4 Update Auth Flow for Multi-Profile
- On sign in: Add to profiles array, set as active
- On sign out: Mark as inactive, don't remove from array
- On switch: Update auth state, reload all data

### 5.5 Update SupabaseManager for Profile Switching
```swift
func switchProfile(to profile: SavedUserProfile) async throws {
    // 1. Save current profile state
    // 2. Update currentUser
    // 3. Update isAuthenticated
    // 4. Reload all cached data
    // 5. Notify observers
}
```

---

## Phase 6: Complete Messaging System
**Time Estimate: 2 hours**

### 6.1 Fix Server-Side Mark as Read
Update MessagingService.swift:
```swift
func markAsRead(conversationWith recipientId: UUID) async {
    // Update database, not just local cache
    try await supabase.update(
        ["is_read": true],
        in: "direct_messages",
        where: "recipient_id = '\(currentUserId)' AND sender_id = '\(recipientId)'"
    )
}
```

### 6.2 Add Unread Tracking for Group Chats
- Add `chat_read_status` table or track in `ralley_participants`
- Track last_read_message_id or last_read_at per user/chat
- Calculate unread count on load

### 6.3 Implement Message Delivery Status
- Add `status` column to direct_messages: sent, delivered, read
- Update UI to show status indicators
- Update status when recipient views message

### 6.4 Add Conversation Search
- Search messages by content
- Search conversations by user name

---

## Phase 7: Complete Ralley Features
**Time Estimate: 1.5 hours**

### 7.1 Fix Location Search
Replace hardcoded coordinates with real geocoding:
- Integrate Apple MapKit for location search
- Store real coordinates when creating ralleys
- Implement distance-based filtering

### 7.2 Implement Ralley Cancellation
```swift
func cancelRalley(_ ralleyId: UUID) async throws {
    // 1. Update status to "cancelled"
    // 2. Notify all participants
    // 3. Create system message in group chat
}
```

### 7.3 Add Minimum Player Enforcement
- Track min_participants in ralleys table
- Auto-check before start time
- Notify captain if minimum not met
- Option to proceed or cancel

### 7.4 Implement Privacy Filters
- Filter nearby ralleys by visibility setting
- Check friendship status for "friends" visibility
- Check mutual friends for "mutual_friends" visibility

---

## Phase 8: Notifications System
**Time Estimate: 1 hour**

### 8.1 Create Notifications Table
```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,  -- 'like', 'comment', 'follow', 'ralley_join', 'message', etc.
    actor_id UUID REFERENCES club_users(id) ON DELETE SET NULL,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    ralley_id UUID REFERENCES ralleys(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 8.2 Create Notification Triggers
Auto-create notifications for:
- New follower
- Post like
- Post comment
- Ralley join request
- Ralley join approval
- New message (for push notifications)

### 8.3 Implement Push Notifications (Optional)
- Set up APNs integration
- Create Supabase Edge Function for push delivery
- Handle notification permissions in app

---

## Phase 9: Testing & Polish
**Time Estimate: 2 hours**

### 9.1 Test All Features End-to-End
- [ ] User registration and login
- [ ] Profile creation and editing
- [ ] Multi-profile switching
- [ ] Create ralley
- [ ] Join/leave ralley
- [ ] Ralley approval workflow
- [ ] Group chat messaging
- [ ] Direct messaging
- [ ] Follow/unfollow users
- [ ] Create/view/like/comment on posts
- [ ] Notifications
- [ ] Ralley completion flow

### 9.2 Fix Edge Cases
- Handle offline state gracefully
- Handle expired sessions
- Handle deleted users/ralleys
- Handle concurrent modifications

### 9.3 Remove Mock Data Fallbacks
Once all features work with real data, remove or gate mock data:
```swift
#if DEBUG
// Keep mock data for previews
#else
// Production uses real data only
#endif
```

### 9.4 Performance Optimization
- Implement pagination for feeds
- Cache frequently accessed data
- Lazy load images
- Optimize database queries

---

## SQL Script to Run in Supabase

```sql
-- COMPLETE CLUB RALLEY SCHEMA
-- Run this entire script in Supabase SQL Editor

-- 1. Drop existing tables for clean slate
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

-- 2. Create club_users
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
    instagram_handle TEXT,
    is_verified_athlete BOOLEAN DEFAULT false,
    sports JSONB DEFAULT '[]'::jsonb,
    availability JSONB DEFAULT '[]'::jsonb,
    athlete_info JSONB,
    preferences JSONB DEFAULT '{}'::jsonb,
    friends_count INT DEFAULT 0,
    ralleys_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create ralleys (with both host_id and host_user_id for compatibility)
CREATE TABLE ralleys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
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
    min_participants INT DEFAULT 2,
    current_participants INT DEFAULT 1,
    is_public BOOLEAN DEFAULT true,
    visibility TEXT DEFAULT 'anyone',
    join_type TEXT DEFAULT 'open',
    status TEXT DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add alias column for backward compatibility
ALTER TABLE ralleys ADD COLUMN host_id UUID GENERATED ALWAYS AS (host_user_id) STORED;

-- 4. Create ralley_participants
CREATE TABLE ralley_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ralley_id UUID NOT NULL REFERENCES ralleys(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'joined',
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(ralley_id, user_id)
);

-- 5. Create friendships (with both column naming conventions)
CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'accepted',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, friend_id),
    CHECK (user_id != friend_id)
);

-- Add alias columns for backward compatibility
ALTER TABLE friendships ADD COLUMN requester_id UUID GENERATED ALWAYS AS (user_id) STORED;
ALTER TABLE friendships ADD COLUMN addressee_id UUID GENERATED ALWAYS AS (friend_id) STORED;

-- 6. Create posts
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_url TEXT,
    images JSONB DEFAULT '[]'::jsonb,
    post_type TEXT DEFAULT 'standard',
    ralley_id UUID REFERENCES ralleys(id) ON DELETE SET NULL,
    tagged_user_ids UUID[],
    link_url TEXT,
    original_post_id UUID,
    repost_comment TEXT,
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    shares_count INT DEFAULT 0,
    visibility TEXT DEFAULT 'everyone',
    likes JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Create comments (for posts)
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Create direct_messages
CREATE TABLE direct_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Create chat_messages (ralley group chats)
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ralley_id UUID NOT NULL REFERENCES ralleys(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'text',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Create notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    actor_id UUID REFERENCES club_users(id) ON DELETE SET NULL,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    ralley_id UUID REFERENCES ralleys(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Create ralley_post_opt_outs
CREATE TABLE ralley_post_opt_outs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ralley_id UUID NOT NULL REFERENCES ralleys(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES club_users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(ralley_id, user_id)
);

-- 12. Create indexes
CREATE INDEX idx_users_username ON club_users(username);
CREATE INDEX idx_users_city_state ON club_users(city, state);
CREATE INDEX idx_users_sports ON club_users USING GIN (sports);

CREATE INDEX idx_ralleys_host ON ralleys(host_user_id);
CREATE INDEX idx_ralleys_datetime ON ralleys(date_time);
CREATE INDEX idx_ralleys_location ON ralleys(city, state);
CREATE INDEX idx_ralleys_sport ON ralleys(sport);
CREATE INDEX idx_ralleys_status ON ralleys(status) WHERE status = 'active';

CREATE INDEX idx_participants_ralley ON ralley_participants(ralley_id);
CREATE INDEX idx_participants_user ON ralley_participants(user_id);

CREATE INDEX idx_friendships_user ON friendships(user_id);
CREATE INDEX idx_friendships_friend ON friendships(friend_id);
CREATE INDEX idx_friendships_status ON friendships(status);

CREATE INDEX idx_posts_user ON posts(user_id);
CREATE INDEX idx_posts_created ON posts(created_at DESC);
CREATE INDEX idx_posts_ralley ON posts(ralley_id) WHERE ralley_id IS NOT NULL;

CREATE INDEX idx_comments_post ON comments(post_id);
CREATE INDEX idx_comments_user ON comments(user_id);

CREATE INDEX idx_dm_sender ON direct_messages(sender_id);
CREATE INDEX idx_dm_recipient ON direct_messages(recipient_id);
CREATE INDEX idx_dm_created ON direct_messages(created_at DESC);
CREATE INDEX idx_dm_conversation ON direct_messages(LEAST(sender_id, recipient_id), GREATEST(sender_id, recipient_id), created_at DESC);

CREATE INDEX idx_chat_ralley ON chat_messages(ralley_id);
CREATE INDEX idx_chat_created ON chat_messages(ralley_id, created_at DESC);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id) WHERE is_read = false;

-- 13. Enable RLS
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

-- 14. Create permissive RLS policies (for development - tighten for production)
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

-- 15. Create triggers
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON club_users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_ralleys_updated_at BEFORE UPDATE ON ralleys FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Auto-update participant count
CREATE OR REPLACE FUNCTION update_ralley_participant_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.status = 'joined' THEN
        UPDATE ralleys SET current_participants = current_participants + 1 WHERE id = NEW.ralley_id;
    ELSIF TG_OP = 'DELETE' AND OLD.status = 'joined' THEN
        UPDATE ralleys SET current_participants = current_participants - 1 WHERE id = OLD.ralley_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.status != 'joined' AND NEW.status = 'joined' THEN
        UPDATE ralleys SET current_participants = current_participants + 1 WHERE id = NEW.ralley_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.status = 'joined' AND NEW.status != 'joined' THEN
        UPDATE ralleys SET current_participants = current_participants - 1 WHERE id = NEW.ralley_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_participant_count
    AFTER INSERT OR UPDATE OR DELETE ON ralley_participants
    FOR EACH ROW EXECUTE FUNCTION update_ralley_participant_count();

-- Auto-update comments count
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

-- 16. Reload schema cache
NOTIFY pgrst, 'reload schema';

-- 17. Verify
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' ORDER BY table_name;
```

---

## File Changes Summary

### New Files to Create:
1. `Core/Supabase/SupabaseRealtime.swift` - Realtime subscriptions
2. `Core/Services/MultiProfileManager.swift` - Multiple profile support
3. `Views/Settings/ProfileSwitcherView.swift` - Profile switching UI
4. `Database/final_schema.sql` - Complete production schema

### Files to Modify:
1. `Services/Ralley/RalleyParticipationService.swift` - Fix status values
2. `Services/MessagingService.swift` - Add server-side mark as read
3. `Services/ChatService.swift` - Add unread tracking
4. `Services/Social/NotificationsService.swift` - Fix for real notifications table
5. `Services/FriendshipService.swift` - Ensure column name compatibility
6. `Models/Onboarding/ClubRalleyOnboarding.swift` - Multi-profile storage
7. `Core/Services/SupabaseManager.swift` - Profile switching support
8. `Views/Settings/SettingsView.swift` - Add profile switcher

---

## Execution Order

1. **Run SQL schema in Supabase** (Phase 1)
2. **Fix Swift code mismatches** (Phase 2 & 3)
3. **Test basic operations** (create user, create ralley, send message)
4. **Implement realtime** (Phase 4)
5. **Implement multi-profile** (Phase 5)
6. **Complete messaging** (Phase 6)
7. **Complete ralleys** (Phase 7)
8. **Add notifications** (Phase 8)
9. **Final testing & polish** (Phase 9)

---

## Success Criteria

- [ ] Users can register and create profiles
- [ ] Multiple profiles can be saved and switched
- [ ] Users can create, discover, and join ralleys
- [ ] Ralley approval workflow works for private ralleys
- [ ] Group chat works for ralleys
- [ ] Direct messaging works between users
- [ ] Messages update in real-time
- [ ] Users can follow/unfollow each other
- [ ] Posts can be created, liked, and commented on
- [ ] Notifications appear for relevant actions
- [ ] Profile editing saves to database
- [ ] App works after closing and reopening
- [ ] All data persists in Supabase

---

**Total Estimated Time: 12-15 hours**

Let's make Club Ralley the best social sports app ever!
