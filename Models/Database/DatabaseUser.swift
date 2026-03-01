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
    let sports: [String]?
    let availability: [[String: Any]]?
    let settings: [String: Any]?
    let athlete_info: ClubUserAthleteInfoJSON?
    let is_verified_athlete: Bool
    let friends_count: Int
    let ralleys_count: Int
    let created_at: Date

    enum CodingKeys: String, CodingKey {
        case id, email, first_name, last_name, username
        case profile_photo_url, bio, city, state, instagram_handle
        case sports, availability, settings, athlete_info
        case is_verified_athlete, friends_count, ralleys_count, created_at
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
        is_verified_athlete = try container.decodeIfPresent(Bool.self, forKey: .is_verified_athlete) ?? false
        friends_count = try container.decodeIfPresent(Int.self, forKey: .friends_count) ?? 0
        ralleys_count = try container.decodeIfPresent(Int.self, forKey: .ralleys_count) ?? 0
        created_at = try container.decodeIfPresent(Date.self, forKey: .created_at) ?? Date()

        // Decode athlete_info JSONB properly
        athlete_info = try container.decodeIfPresent(ClubUserAthleteInfoJSON.self, forKey: .athlete_info)

        // Decode sports as simple string array (matches Supabase column type)
        sports = try container.decodeIfPresent([String].self, forKey: .sports)

        availability = nil
        settings = nil
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
        try container.encodeIfPresent(athlete_info, forKey: .athlete_info)
        try container.encodeIfPresent(sports, forKey: .sports)
        try container.encode(is_verified_athlete, forKey: .is_verified_athlete)
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
    let athlete_info: AthleteInfoUpdate?

    init(
        first_name: String?,
        last_name: String?,
        username: String?,
        bio: String?,
        city: String?,
        state: String?,
        instagram_handle: String?,
        profile_photo_url: String?,
        athlete_info: AthleteInfoUpdate? = nil
    ) {
        self.first_name = first_name
        self.last_name = last_name
        self.username = username
        self.bio = bio
        self.city = city
        self.state = state
        self.instagram_handle = instagram_handle
        self.profile_photo_url = profile_photo_url
        self.athlete_info = athlete_info
    }
}

// MARK: - Athlete Info Update (Encodable for writing to Supabase)

struct AthleteInfoUpdate: Codable {
    let played_college: Bool
    let sport: String?
    let school: String?
    let division: String?
    let years_played: String?
    let position: String?
}

