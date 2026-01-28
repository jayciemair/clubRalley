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
    let created_at: Date
    let updated_at: Date
    let user: DatabaseUser
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
    let created_at: Date
    let updated_at: Date
    let user: DatabaseRalleyUser
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
