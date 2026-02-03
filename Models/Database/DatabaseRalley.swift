//
//  DatabaseRalley.swift
//  Club Ralley
//
//  Ralley-related database models
//

import Foundation

// MARK: - Ralley Database Models

/// Database representation of ralley (matches Supabase ralleys table schema)
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

/// Database ralley with joined user information
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
        case id, host_user_id, title, description
        case location_name, location_address, location_city, location_state
        case latitude, longitude, date_time, sport_id, category
        case max_participants, current_participants, is_public
        case visibility, join_type, created_at, updated_at
        case organizer = "club_users"
    }
}

/// Database user representation for ralley queries
struct DatabaseRalleyUser: Codable {
    let id: UUID?
    let first_name: String
    let last_name: String
    let username: String
    let profile_photo_url: String?
}

/// Database representation of ralley participant
struct DatabaseRalleyParticipant: Codable {
    let ralley_id: UUID
    let user_id: UUID
    let status: String // 'attending', 'maybe', 'not_attending', 'requested'
}

/// Database representation of ralley participant with ID (for queries)
struct DatabaseRalleyParticipantWithId: Codable {
    let id: UUID
    let ralley_id: UUID
    let user_id: UUID
    let status: String
    let created_at: Date
}

/// Database model for updating ralley fields
struct DatabaseRalleyUpdate: Codable {
    let title: String
    let description: String
    let location_name: String
    let location_address: String
    let location_city: String
    let location_state: String
    let latitude: Double
    let longitude: Double
    let date_time: Date
    let category: String
    let max_participants: Int
    let is_public: Bool
    let visibility: String
    let join_type: String
}

/// Database model for checking ralley host ownership
struct DatabaseRalleyHostCheck: Codable {
    let host_user_id: UUID
}
