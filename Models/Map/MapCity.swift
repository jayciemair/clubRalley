//
//  MapCity.swift
//  Club Ralley
//
//  City model for map feature — defines available cities with map regions
//

import Foundation
import MapKit

// MARK: - Map City Model

struct MapCity: Identifiable, Hashable {
    let id: String
    let name: String
    let state: String
    let latitude: Double
    let longitude: Double
    let spanLatitude: Double
    let spanLongitude: Double

    var region: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: spanLatitude, longitudeDelta: spanLongitude)
        )
    }

    var displayName: String {
        "\(name), \(state)"
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MapCity, rhs: MapCity) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Available Cities

extension MapCity {
    static let available: [MapCity] = [
        MapCity(
            id: "lewisburg", name: "Lewisburg", state: "PA",
            latitude: 40.9600, longitude: -76.8850,
            spanLatitude: 0.035, spanLongitude: 0.035
        ),
    ]

    static var defaultCity: MapCity {
        available[0] // Lewisburg
    }
}
