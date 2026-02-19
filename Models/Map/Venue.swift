//
//  Venue.swift
//  Club Ralley
//
//  Venue model for map feature — represents courts, parks, and gyms
//

import Foundation
import CoreLocation

// MARK: - Venue Model

struct Venue: Identifiable, Hashable {
    let id: UUID
    let name: String
    let address: String
    let city: String
    let state: String
    let type: LocationSuggestion.LocationType
    let latitude: Double
    let longitude: Double
    let sports: [String]
    let isOpen: Bool

    // MARK: - Computed Properties

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var primarySport: String {
        sports.first ?? "Other"
    }

    var iconName: String {
        SportIconMapper.iconName(for: primarySport)
    }

    var typeBadge: String {
        switch type {
        case .park: return "Park"
        case .court: return "Court"
        case .field: return "Field"
        case .gym: return "Gym"
        case .other: return "Venue"
        }
    }

    var typeIconName: String {
        type.iconName
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Venue, rhs: Venue) -> Bool {
        lhs.id == rhs.id
    }
}
