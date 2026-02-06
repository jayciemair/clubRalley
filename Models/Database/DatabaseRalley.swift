//
//  DatabaseRalley.swift
//  Club Ralley
//
//  Ralley-related database models for lean 6-table schema
//

import Foundation

// MARK: - Ralley Database Models

/// Database representation of ralley (matches Supabase ralleys table - lean schema)
struct DatabaseRalley: Codable {
    let host_user_id: UUID
    let title: String
    let description: String?
    let sport: String?
    let skill_level: String?
    let location_name: String?
    let location_address: String?
    let city: String?
    let state: String?
    let latitude: Decimal?
    let longitude: Decimal?
    let date_time: Date
    let duration_minutes: Int?
    let max_participants: Int?
    let current_participants: Int
    let visibility: String
    let join_type: String?
    let status: String?

    // Convenience init for creating ralleys
    init(
        host_user_id: UUID,
        title: String,
        description: String?,
        location_name: String,
        location_address: String?,
        location_city: String,
        location_state: String,
        latitude: Double,
        longitude: Double,
        date_time: Date,
        sport_id: UUID?,
        category: String,
        max_participants: Int?,
        current_participants: Int,
        is_public: Bool,
        visibility: String,
        join_type: String
    ) {
        self.host_user_id = host_user_id
        self.title = title
        self.description = description
        self.sport = category
        self.skill_level = "all"
        self.location_name = location_name
        self.location_address = location_address
        self.city = location_city
        self.state = location_state
        self.latitude = Decimal(latitude)
        self.longitude = Decimal(longitude)
        self.date_time = date_time
        self.duration_minutes = 120
        self.max_participants = max_participants
        self.current_participants = current_participants
        self.visibility = visibility
        self.join_type = join_type
        self.status = "active"
    }
}

/// Database ralley with joined user information
struct DatabaseRalleyWithUser: Codable {
    let id: UUID
    let host_user_id: UUID
    let title: String
    let description: String?
    let sport: String?
    let skill_level: String?
    let location_name: String?
    let location_address: String?
    let city: String?
    let state: String?
    let latitude: Decimal?
    let longitude: Decimal?
    let date_time: Date
    let duration_minutes: Int?
    let max_participants: Int?
    let current_participants: Int
    let visibility: String?
    let join_type: String?
    let status: String?
    let created_at: Date
    let updated_at: Date?
    let organizer: DatabaseRalleyUser

    // Computed properties for backwards compatibility with services
    var location_city: String { city ?? "" }
    var location_state: String { state ?? "" }
    var category: String { sport ?? "sports" }
    var is_public: Bool { visibility == "anyone" }
    var sport_id: UUID? { nil }

    enum CodingKeys: String, CodingKey {
        case id, host_user_id, title, description, sport, skill_level
        case location_name, location_address, city, state
        case latitude, longitude, date_time, duration_minutes
        case max_participants, current_participants
        case visibility, join_type, status, created_at, updated_at
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
    let status: String // 'joined', 'pending', 'declined'
}

/// Database representation of ralley participant with ID (for queries)
struct DatabaseRalleyParticipantWithId: Codable {
    let id: UUID
    let ralley_id: UUID
    let user_id: UUID
    let status: String
    let joined_at: Date

    // Backwards compatibility
    var created_at: Date { joined_at }
}

/// Database model for updating ralley fields
struct DatabaseRalleyUpdate: Codable {
    let title: String
    let description: String
    let location_name: String
    let location_address: String
    let city: String
    let state: String
    let latitude: Double
    let longitude: Double
    let date_time: Date
    let sport: String
    let max_participants: Int
    let visibility: String
    let join_type: String

    // Convenience init for backwards compatibility
    init(
        title: String,
        description: String,
        location_name: String,
        location_address: String,
        location_city: String,
        location_state: String,
        latitude: Double,
        longitude: Double,
        date_time: Date,
        category: String,
        max_participants: Int,
        is_public: Bool,
        visibility: String,
        join_type: String
    ) {
        self.title = title
        self.description = description
        self.location_name = location_name
        self.location_address = location_address
        self.city = location_city
        self.state = location_state
        self.latitude = latitude
        self.longitude = longitude
        self.date_time = date_time
        self.sport = category
        self.max_participants = max_participants
        self.visibility = visibility
        self.join_type = join_type
    }
}

/// Database model for checking ralley host ownership
struct DatabaseRalleyHostCheck: Codable {
    let host_user_id: UUID
}
