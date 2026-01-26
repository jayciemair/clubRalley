//
//  Sport.swift
//  Club Ralley
//
//  Sport and School models for athlete verification and activity categorization
//

import Foundation

struct Sport: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let category: SportCategory
    let iconName: String
    let isPopular: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case iconName = "icon_name"
        case isPopular = "is_popular"
    }
}

enum SportCategory: String, Codable, CaseIterable {
    case team = "team"
    case individual = "individual"
    case waterSports = "water_sports"
    case winterSports = "winter_sports"
    case combatSports = "combat_sports"
    case fitness = "fitness"
    case recreational = "recreational"
    
    var displayName: String {
        switch self {
        case .team: return "Team Sports"
        case .individual: return "Individual Sports"
        case .waterSports: return "Water Sports"
        case .winterSports: return "Winter Sports"
        case .combatSports: return "Combat Sports"
        case .fitness: return "Fitness"
        case .recreational: return "Recreational"
        }
    }
}

struct School: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let state: String
    let division: Division
    let conference: String?
    let logoURL: String?
    
    var displayName: String {
        name
    }
    
    var fullDisplayName: String {
        "\(name) (\(state))"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case state
        case division
        case conference
        case logoURL = "logo_url"
    }
}

enum Division: String, Codable, CaseIterable {
    case d1 = "D1"
    case d2 = "D2" 
    case d3 = "D3"
    case naia = "NAIA"
    case juco = "JUCO"
    case club = "Club"
    case intramural = "Intramural"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - User Sport Preferences

struct UserSport: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let sport: Sport
    let skillLevel: SkillLevel
    let isPreferred: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sport
        case skillLevel = "skill_level"
        case isPreferred = "is_preferred"
        case createdAt = "created_at"
    }
}

enum SkillLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
    
    var emoji: String {
        switch self {
        case .beginner: return "🌱"
        case .intermediate: return "🏃‍♂️"
        case .advanced: return "🏆"
        case .expert: return "🥇"
        }
    }
}