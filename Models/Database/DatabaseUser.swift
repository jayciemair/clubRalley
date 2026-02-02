//
//  DatabaseUser.swift
//  Club Ralley
//
//  User-related database models
//

import Foundation

// MARK: - User Database Models

/// Database user representation (subset of club_users table)
struct DatabaseUser: Codable {
    let first_name: String
    let last_name: String
    let username: String
    let profile_photo_url: String?
}

/// Database representation of user profile (matches Supabase club_users table schema)
struct DatabaseUserProfile: Codable {
    let id: UUID
    let email: String
    let first_name: String
    let last_name: String
    let username: String
    let date_of_birth_month: Int
    let date_of_birth_year: Int
    let gender: String
    let location_city: String
    let location_state: String
    let bio: String?
    let instagram_handle: String?
    let profile_photo_url: String?
    let is_verified_athlete: Bool
    let friends_count: Int
    let ralleys_count: Int
    let created_at: Date
    let updated_at: Date
}

/// Database model for updating user profile fields
struct DatabaseUserProfileUpdate: Codable {
    let bio: String?
    let instagram_handle: String?
    let profile_photo_url: String?
}
