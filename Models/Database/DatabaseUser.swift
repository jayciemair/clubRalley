//
//  DatabaseUser.swift
//  Club Ralley
//
//  User-related database models for lean 6-table schema
//

import Foundation

// MARK: - User Database Models

/// Database user representation (subset of users table for joins)
struct DatabaseUser: Codable {
    let first_name: String
    let last_name: String
    let username: String
    let profile_photo_url: String?
}

/// Database representation of user profile (matches Supabase users table)
struct DatabaseUserProfile: Codable {
    let id: UUID
    let email: String
    let first_name: String
    let last_name: String
    let username: String
    let profile_photo_url: String?
    let bio: String?
    let city: String?
    let state: String?
    let instagram_handle: String?
    let sports: [[String: Any]]?
    let availability: [[String: Any]]?
    let preferences: [String: Any]?
    let athlete_info: [String: Any]?
    let friends_count: Int
    let ralleys_count: Int
    let created_at: Date

    var is_verified_athlete: Bool {
        // Check athlete_info for verified status
        if let athleteInfo = athlete_info,
           let verified = athleteInfo["verified"] as? Bool {
            return verified
        }
        return false
    }

    enum CodingKeys: String, CodingKey {
        case id, email, first_name, last_name, username
        case profile_photo_url, bio, city, state, instagram_handle
        case sports, availability, preferences, athlete_info
        case friends_count, ralleys_count, created_at
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        first_name = try container.decodeIfPresent(String.self, forKey: .first_name) ?? ""
        last_name = try container.decodeIfPresent(String.self, forKey: .last_name) ?? ""
        username = try container.decode(String.self, forKey: .username)
        profile_photo_url = try container.decodeIfPresent(String.self, forKey: .profile_photo_url)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        state = try container.decodeIfPresent(String.self, forKey: .state)
        instagram_handle = try container.decodeIfPresent(String.self, forKey: .instagram_handle)
        friends_count = try container.decodeIfPresent(Int.self, forKey: .friends_count) ?? 0
        ralleys_count = try container.decodeIfPresent(Int.self, forKey: .ralleys_count) ?? 0
        created_at = try container.decodeIfPresent(Date.self, forKey: .created_at) ?? Date()

        // JSONB fields are decoded as nil (parsed separately if needed)
        sports = nil
        availability = nil
        preferences = nil
        athlete_info = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(first_name, forKey: .first_name)
        try container.encode(last_name, forKey: .last_name)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(profile_photo_url, forKey: .profile_photo_url)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(city, forKey: .city)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encodeIfPresent(instagram_handle, forKey: .instagram_handle)
        try container.encode(friends_count, forKey: .friends_count)
        try container.encode(ralleys_count, forKey: .ralleys_count)
        try container.encode(created_at, forKey: .created_at)
    }
}

/// Database model for updating user profile fields
/// Note: Uses city/state to match actual Supabase schema
struct DatabaseUserProfileUpdate: Codable {
    let first_name: String?
    let last_name: String?
    let username: String?
    let bio: String?
    let city: String?
    let state: String?
    let instagram_handle: String?
    let profile_photo_url: String?

    // Convenience init that accepts city/state and maps to city/state
    init(
        first_name: String?,
        last_name: String?,
        username: String?,
        bio: String?,
        city: String?,
        state: String?,
        instagram_handle: String?,
        profile_photo_url: String?
    ) {
        self.first_name = first_name
        self.last_name = last_name
        self.username = username
        self.bio = bio
        self.city = city
        self.state = state
        self.instagram_handle = instagram_handle
        self.profile_photo_url = profile_photo_url
    }
}
