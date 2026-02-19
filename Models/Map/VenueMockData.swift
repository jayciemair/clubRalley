//
//  VenueMockData.swift
//  Club Ralley
//
//  Mock venue data for Lewisburg, PA (beta testing area)
//  DEPRECATED: Use VenueService to load from Supabase venues table.
//  Kept as offline fallback only.
//

import Foundation

// MARK: - Mock Venue Data

extension Venue {

    // MARK: - All Venues

    static var allVenues: [Venue] {
        lewisburgVenues
    }

    static func venues(for city: String) -> [Venue] {
        switch city.lowercased() {
        case "lewisburg": return lewisburgVenues
        default: return []
        }
    }

    // MARK: - Lewisburg, PA

    // Coordinates spread slightly for better map pin visibility
    static let lewisburgVenues: [Venue] = [
        Venue(
            id: UUID(), name: "Sojka Pavilion",
            address: "1 Dent Dr", city: "Lewisburg", state: "PA",
            type: .gym, latitude: 40.9545, longitude: -76.8845,
            sports: ["Basketball", "Volleyball"], isOpen: true
        ),
        Venue(
            id: UUID(), name: "Gerhard Fieldhouse",
            address: "1 Dent Dr", city: "Lewisburg", state: "PA",
            type: .gym, latitude: 40.9572, longitude: -76.8870,
            sports: ["Basketball", "Tennis", "Volleyball", "Running"], isOpen: true
        ),
        Venue(
            id: UUID(), name: "Davis Gym",
            address: "701 Moore Ave", city: "Lewisburg", state: "PA",
            type: .gym, latitude: 40.9525, longitude: -76.8815,
            sports: ["Volleyball", "Wrestling"], isOpen: true
        ),
        Venue(
            id: UUID(), name: "Bucknell Turf Fields",
            address: "Smoketown Rd", city: "Lewisburg", state: "PA",
            type: .field, latitude: 40.9595, longitude: -76.8920,
            sports: ["Soccer", "Lacrosse", "Football"], isOpen: true
        ),
        Venue(
            id: UUID(), name: "Christy Mathewson Stadium",
            address: "Moore Ave", city: "Lewisburg", state: "PA",
            type: .field, latitude: 40.9508, longitude: -76.8790,
            sports: ["Football", "Lacrosse", "Soccer"], isOpen: true
        ),
        Venue(
            id: UUID(), name: "Hufnagle Park",
            address: "S Front St", city: "Lewisburg", state: "PA",
            type: .park, latitude: 40.9650, longitude: -76.8865,
            sports: ["Basketball", "Tennis", "Running"], isOpen: true
        ),
        Venue(
            id: UUID(), name: "Buffalo Valley Rail Trail",
            address: "St Mary St Trailhead", city: "Lewisburg", state: "PA",
            type: .park, latitude: 40.9700, longitude: -76.8780,
            sports: ["Running", "Cycling", "Hiking"], isOpen: true
        ),
        Venue(
            id: UUID(), name: "Kinney Natatorium",
            address: "1 Dent Dr", city: "Lewisburg", state: "PA",
            type: .gym, latitude: 40.9558, longitude: -76.8825,
            sports: ["Swimming"], isOpen: true
        ),
    ]
}
