//
//  Ralley.swift
//  Club Ralley
//
//  Core event model for Club Ralley activities and meetups
//

import Foundation
import CoreLocation

struct Ralley: Codable, Identifiable {
    let id: UUID
    let hostUserId: UUID
    let title: String
    let description: String?
    let location: RalleyLocation
    let dateTime: Date
    let sport: Sport?
    let category: RalleyCategory
    let maxParticipants: Int?
    let currentParticipants: Int
    let isPublic: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // Host information (populated via join)
    let host: User?
    
    // User's participation status
    let userParticipationStatus: ParticipationStatus?
    
    var isUpcoming: Bool {
        dateTime > Date()
    }
    
    var isPast: Bool {
        dateTime <= Date()
    }
    
    var isFull: Bool {
        if let max = maxParticipants {
            return currentParticipants >= max
        }
        return false
    }
    
    var availableSpots: Int? {
        if let max = maxParticipants {
            return max - currentParticipants
        }
        return nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case hostUserId = "host_user_id"
        case title
        case description
        case location
        case dateTime = "date_time"
        case sport
        case category
        case maxParticipants = "max_participants"
        case currentParticipants = "current_participants"
        case isPublic = "is_public"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case host
        case userParticipationStatus = "user_participation_status"
    }
}

struct RalleyLocation: Codable {
    let name: String
    let address: String?
    let city: String
    let state: String
    let latitude: Double
    let longitude: Double
    
    var displayAddress: String {
        if let address = address {
            return "\(address), \(city), \(state)"
        }
        return "\(city), \(state)"
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum RalleyCategory: String, Codable, CaseIterable {
    case sports = "sports"
    case fitness = "fitness"
    case social = "social"
    case outdoor = "outdoor"
    case competitive = "competitive"
    case casual = "casual"
    case training = "training"
    
    var displayName: String {
        switch self {
        case .sports: return "Sports"
        case .fitness: return "Fitness"
        case .social: return "Social"
        case .outdoor: return "Outdoor"
        case .competitive: return "Competitive"
        case .casual: return "Casual"
        case .training: return "Training"
        }
    }
    
    var icon: String {
        switch self {
        case .sports: return "sportscourt"
        case .fitness: return "figure.strengthtraining.traditional"
        case .social: return "person.2"
        case .outdoor: return "mountain.2"
        case .competitive: return "trophy"
        case .casual: return "hand.wave"
        case .training: return "dumbbell"
        }
    }
}

// MARK: - Participation Management

struct RalleyParticipant: Codable, Identifiable {
    let id: UUID
    let ralleyId: UUID
    let userId: UUID
    let status: ParticipationStatus
    let joinedAt: Date
    let user: User?
    
    enum CodingKeys: String, CodingKey {
        case id
        case ralleyId = "ralley_id"
        case userId = "user_id"
        case status
        case joinedAt = "joined_at"
        case user
    }
}

enum ParticipationStatus: String, Codable, CaseIterable {
    case attending = "attending"
    case maybe = "maybe"
    case notAttending = "not_attending"
    case requested = "requested"  // For private ralleys
    
    var displayName: String {
        switch self {
        case .attending: return "Attending"
        case .maybe: return "Maybe"
        case .notAttending: return "Not Attending"
        case .requested: return "Requested"
        }
    }
    
    var icon: String {
        switch self {
        case .attending: return "checkmark.circle.fill"
        case .maybe: return "questionmark.circle.fill"
        case .notAttending: return "xmark.circle.fill"
        case .requested: return "clock.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .attending: return "green"
        case .maybe: return "orange"
        case .notAttending: return "red"
        case .requested: return "blue"
        }
    }
}

// MARK: - Ralley Creation/Update Models

struct CreateRalleyRequest: Codable {
    let title: String
    let description: String?
    let location: RalleyLocation
    let dateTime: Date
    let sportId: UUID?
    let category: RalleyCategory
    let maxParticipants: Int?
    let isPublic: Bool
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case location
        case dateTime = "date_time"
        case sportId = "sport_id"
        case category
        case maxParticipants = "max_participants"
        case isPublic = "is_public"
    }
}

struct UpdateParticipationRequest: Codable {
    let status: ParticipationStatus
}

// MARK: - Saved Locations

struct SavedLocation: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let address: String?
    let city: String
    let state: String
    let latitude: Double
    let longitude: Double
    let usageCount: Int
    let createdAt: Date
    
    var ralleyLocation: RalleyLocation {
        RalleyLocation(
            name: name,
            address: address,
            city: city,
            state: state,
            latitude: latitude,
            longitude: longitude
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case address
        case city
        case state
        case latitude
        case longitude
        case usageCount = "usage_count"
        case createdAt = "created_at"
    }
}