//
//  DatabaseModels.swift
//  Club Ralley
//
//  Database models that map to Supabase table schemas.
//  These are used for API operations and differ from UI models.
//

import Foundation

// MARK: - Post Database Models

/**
 * Database representation of post (matches Supabase posts table schema)
 * Used for API operations - separate from UI models for clean architecture
 */
struct DatabasePost: Codable {
    let user_id: UUID
    let content: String
    let post_type: String
    let likes_count: Int
    let comments_count: Int
    let visibility: String
    let ralley_id: UUID?
    let tagged_user_ids: [UUID]?
    let link_url: String?
    let shares_count: Int

    init(
        user_id: UUID,
        content: String,
        post_type: String,
        likes_count: Int = 0,
        comments_count: Int = 0,
        visibility: String = "everyone",
        ralley_id: UUID? = nil,
        tagged_user_ids: [UUID]? = nil,
        link_url: String? = nil,
        shares_count: Int = 0
    ) {
        self.user_id = user_id
        self.content = content
        self.post_type = post_type
        self.likes_count = likes_count
        self.comments_count = comments_count
        self.visibility = visibility
        self.ralley_id = ralley_id
        self.tagged_user_ids = tagged_user_ids
        self.link_url = link_url
        self.shares_count = shares_count
    }
}

/**
 * Database post with joined user information
 * Result of posts JOIN club_users query
 */
struct DatabasePostWithUser: Codable {
    let id: UUID
    let user_id: UUID
    let content: String
    let post_type: String
    let likes_count: Int
    let comments_count: Int
    let shares_count: Int?
    let visibility: String?
    let ralley_id: UUID?
    let tagged_user_ids: [UUID]?
    let link_url: String?
    let original_post_id: UUID?
    let repost_comment: String?
    let created_at: Date
    let updated_at: Date
    let user: DatabaseUser

    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case content
        case post_type
        case likes_count
        case comments_count
        case shares_count
        case visibility
        case ralley_id
        case tagged_user_ids
        case link_url
        case original_post_id
        case repost_comment
        case created_at
        case updated_at
        case user = "club_users"  // Supabase uses table name for joins
    }
}

/**
 * Database representation of a repost
 */
struct DatabaseRepost: Codable {
    let original_post_id: UUID
    let user_id: UUID
    let comment: String?

    init(original_post_id: UUID, user_id: UUID, comment: String? = nil) {
        self.original_post_id = original_post_id
        self.user_id = user_id
        self.comment = comment
    }
}

/**
 * Database repost with joined information
 */
struct DatabaseRepostWithUser: Codable {
    let id: UUID
    let original_post_id: UUID
    let user_id: UUID
    let comment: String?
    let created_at: Date
    let user: DatabaseUser

    enum CodingKeys: String, CodingKey {
        case id
        case original_post_id
        case user_id
        case comment
        case created_at
        case user = "club_users"
    }
}

/**
 * Database representation of ralley post opt-out
 */
struct DatabaseRalleyPostOptOut: Codable {
    let ralley_id: UUID
    let user_id: UUID
}

/**
 * Database user representation (subset of club_users table)
 * Used in JOIN queries for post author information
 */
struct DatabaseUser: Codable {
    let first_name: String
    let last_name: String
    let username: String
    let profile_photo_url: String?
}

// MARK: - Ralley Database Models

/**
 * Database representation of ralley (matches Supabase ralleys table schema)
 */
struct DatabaseRalley: Codable {
    let host_user_id: UUID
    let title: String
    let description: String?
    let location_name: String
    let location_address: String?
    let location_city: String
    let location_state: String
    let latitude: Double
    let longitude: Double
    let date_time: Date
    let sport_id: UUID?
    let category: String
    let max_participants: Int?
    let current_participants: Int
    let is_public: Bool
    let visibility: String
    let join_type: String
}

/**
 * Database ralley with joined user information
 * Result of ralleys JOIN club_users query
 */
struct DatabaseRalleyWithUser: Codable {
    let id: UUID
    let host_user_id: UUID
    let title: String
    let description: String?
    let location_name: String
    let location_address: String?
    let location_city: String
    let location_state: String
    let latitude: Double
    let longitude: Double
    let date_time: Date
    let sport_id: UUID?
    let category: String
    let max_participants: Int?
    let current_participants: Int
    let is_public: Bool
    let visibility: String?
    let join_type: String?
    let created_at: Date
    let updated_at: Date
    let organizer: DatabaseRalleyUser

    enum CodingKeys: String, CodingKey {
        case id
        case host_user_id
        case title
        case description
        case location_name
        case location_address
        case location_city
        case location_state
        case latitude
        case longitude
        case date_time
        case sport_id
        case category
        case max_participants
        case current_participants
        case is_public
        case visibility
        case join_type
        case created_at
        case updated_at
        case organizer = "club_users"  // Supabase uses table name for joins
    }
}

/**
 * Database user representation for ralley queries
 */
struct DatabaseRalleyUser: Codable {
    let id: UUID?
    let first_name: String
    let last_name: String
    let username: String
    let profile_photo_url: String?
}

/**
 * Database representation of ralley participant
 */
struct DatabaseRalleyParticipant: Codable {
    let ralley_id: UUID
    let user_id: UUID
    let status: String // 'attending', 'maybe', 'not_attending', 'requested'
}

/**
 * Database representation of ralley participant with ID (for queries)
 */
struct DatabaseRalleyParticipantWithId: Codable {
    let id: UUID
    let ralley_id: UUID
    let user_id: UUID
    let status: String
    let created_at: Date
}

// MARK: - Profile Database Models

/**
 * Database representation of user profile (matches Supabase club_users table schema)
 */
struct DatabaseUserProfile: Codable {
    /// Unique user identifier
    let id: UUID

    /// User's email address
    let email: String

    /// User's first name
    let first_name: String

    /// User's last name
    let last_name: String

    /// Unique username
    let username: String

    /// Birth month (1-12)
    let date_of_birth_month: Int

    /// Birth year (e.g., 1995)
    let date_of_birth_year: Int

    /// Gender string (male, female, non_binary, prefer_not_to_say)
    let gender: String

    /// City of residence
    let location_city: String

    /// State of residence
    let location_state: String

    /// Optional bio/about text
    let bio: String?

    /// Instagram handle (without @)
    let instagram_handle: String?

    /// Profile photo URL
    let profile_photo_url: String?

    /// Whether user is a verified athlete
    let is_verified_athlete: Bool

    /// Number of friends/followers
    let friends_count: Int

    /// Number of ralleys hosted
    let ralleys_count: Int

    /// Account creation timestamp
    let created_at: Date

    /// Last update timestamp
    let updated_at: Date
}

/**
 * Database model for updating user profile fields
 */
struct DatabaseUserProfileUpdate: Codable {
    /// Updated bio text
    let bio: String?

    /// Updated Instagram handle
    let instagram_handle: String?

    /// Updated profile photo URL
    let profile_photo_url: String?
}

/**
 * Database representation of friendship/following relationship
 */
struct DatabaseFriendship: Codable {
    /// ID of user who initiated the follow
    let user_id: UUID

    /// ID of user being followed
    let friend_id: UUID

    /// Relationship status (pending, accepted, blocked)
    let status: String
}

// MARK: - Comment Database Models

/**
 * Database representation of a comment (for INSERT operations)
 */
struct DatabaseComment: Codable {
    let post_id: UUID
    let user_id: UUID
    let content: String
}

/**
 * Database comment with joined user information
 */
struct DatabaseCommentWithUser: Codable {
    let id: UUID
    let post_id: UUID
    let user_id: UUID
    let content: String
    let created_at: Date
    let user: DatabaseUser

    enum CodingKeys: String, CodingKey {
        case id
        case post_id
        case user_id
        case content
        case created_at
        case user = "club_users"
    }
}

// MARK: - Report Database Models

/**
 * Database representation of a post report
 */
struct DatabasePostReport: Codable {
    let post_id: UUID
    let reporter_id: UUID
    let reason: String
}

// MARK: - Notification Database Models

/**
 * Database representation of a notification
 */
struct DatabaseNotification: Codable {
    let id: UUID
    let user_id: UUID
    let type: String
    let actor_id: UUID?
    let post_id: UUID?
    let ralley_id: UUID?
    let message: String
    let is_read: Bool
    let created_at: Date

    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case type
        case actor_id
        case post_id
        case ralley_id
        case message
        case is_read
        case created_at
    }
}

/**
 * Database notification with actor user information
 */
struct DatabaseNotificationWithUser: Codable {
    let id: UUID
    let user_id: UUID
    let type: String
    let actor_id: UUID?
    let post_id: UUID?
    let ralley_id: UUID?
    let message: String
    let is_read: Bool
    let created_at: Date
    let actor: DatabaseUser?

    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case type
        case actor_id
        case post_id
        case ralley_id
        case message
        case is_read
        case created_at
        case actor = "club_users"
    }
}

// Note: Chat-related database models are in DatabaseChatModels.swift
