//
//  RalleySport.swift
//  Club Ralley
//
//  Predefined sports for ralley creation with icons matching Club Ralley's visual theme.
//

import Foundation
import SwiftUI

// MARK: - Ralley Sport Model

/**
 * RalleySport: Predefined sport options for ralley creation
 *
 * Purpose: Provides a curated list of sports with consistent icons
 * and display names for the ralley creation flow.
 */
struct RalleySport: Identifiable, Hashable {
    let id: String
    let name: String
    let iconName: String
    let category: RalleySportCategory

    /// SF Symbol icon with Club Ralley styling
    var icon: Image {
        Image(systemName: iconName)
    }

    /// Color for sport category
    var categoryColor: Color {
        category.color
    }
}

// MARK: - Sport Category

enum RalleySportCategory: String, CaseIterable {
    case racquet = "racquet"
    case team = "team"
    case individual = "individual"

    var displayName: String {
        switch self {
        case .racquet: return "Racquet Sports"
        case .team: return "Team Sports"
        case .individual: return "Individual Sports"
        }
    }

    var color: Color {
        switch self {
        case .racquet: return Color(hex: "#2C4F40")
        case .team: return Color(hex: "#3D6B52")
        case .individual: return Color(hex: "#4E8765")
        }
    }
}

// MARK: - Predefined Sports

extension RalleySport {

    /// All supported sports for Club Ralley (matches onboarding sports list)
    static let supportedSports: [RalleySport] = [
        RalleySport(
            id: "tennis",
            name: "Tennis",
            iconName: "tennisball.fill",
            category: .racquet
        ),
        RalleySport(
            id: "pickleball",
            name: "Pickleball",
            iconName: "figure.pickleball",
            category: .racquet
        ),
        RalleySport(
            id: "basketball",
            name: "Basketball",
            iconName: "basketball.fill",
            category: .team
        ),
        RalleySport(
            id: "soccer",
            name: "Soccer",
            iconName: "soccerball",
            category: .team
        ),
        RalleySport(
            id: "volleyball",
            name: "Volleyball",
            iconName: "volleyball.fill",
            category: .team
        ),
        RalleySport(
            id: "golf",
            name: "Golf",
            iconName: "figure.golf",
            category: .individual
        ),
        RalleySport(
            id: "running",
            name: "Running",
            iconName: "figure.run",
            category: .individual
        ),
        RalleySport(
            id: "cycling",
            name: "Cycling",
            iconName: "bicycle",
            category: .individual
        ),
        RalleySport(
            id: "swimming",
            name: "Swimming",
            iconName: "figure.pool.swim",
            category: .individual
        ),
        RalleySport(
            id: "hiking",
            name: "Hiking",
            iconName: "figure.hiking",
            category: .individual
        ),
        RalleySport(
            id: "yoga",
            name: "Yoga",
            iconName: "figure.yoga",
            category: .individual
        ),
        RalleySport(
            id: "crossfit",
            name: "CrossFit",
            iconName: "dumbbell.fill",
            category: .individual
        )
    ]

    /// Get sport by ID
    static func sport(byId id: String) -> RalleySport? {
        supportedSports.first { $0.id == id }
    }

    /// Get sport by name
    static func sport(byName name: String) -> RalleySport? {
        supportedSports.first { $0.name.lowercased() == name.lowercased() }
    }
}

// MARK: - Duration Options

/**
 * RalleyDuration: Predefined duration options for ralley creation
 */
enum RalleyDuration: Int, CaseIterable, Identifiable {
    case thirtyMinutes = 30
    case oneHour = 60
    case ninetyMinutes = 90
    case twoHours = 120
    case threeHours = 180
    case fourHours = 240

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .thirtyMinutes: return "30 minutes"
        case .oneHour: return "1 hour"
        case .ninetyMinutes: return "1.5 hours"
        case .twoHours: return "2 hours"
        case .threeHours: return "3 hours"
        case .fourHours: return "4 hours"
        }
    }

    var shortName: String {
        switch self {
        case .thirtyMinutes: return "30 min"
        case .oneHour: return "1 hr"
        case .ninetyMinutes: return "1.5 hr"
        case .twoHours: return "2 hr"
        case .threeHours: return "3 hr"
        case .fourHours: return "4 hr"
        }
    }

    /// Get end time from start time
    func endTime(from startTime: Date) -> Date {
        startTime.addingTimeInterval(Double(rawValue) * 60)
    }
}
