//
//  MapViewModel.swift
//  Club Ralley
//
//  ViewModel for the Map tab — manages city selection, venue filtering, and state
//

import Foundation
import MapKit

// MARK: - Map View Model

@MainActor
class MapViewModel: ObservableObject {
    // MARK: - Published State

    @Published var selectedCity: MapCity
    @Published var venues: [Venue] = []
    @Published var selectedVenue: Venue?
    @Published var selectedSportFilter: String?
    @Published var isLoading = false
    @Published var showingVenueDetail = false
    @Published var showingCityPicker = false
    @Published var showingFindRalleys = false

    // MARK: - Computed Properties

    var filteredVenues: [Venue] {
        guard let sport = selectedSportFilter else { return venues }
        return venues.filter { venue in
            venue.sports.contains { $0.lowercased() == sport.lowercased() }
        }
    }

    var availableSports: [String] {
        let allSports = venues.flatMap { $0.sports }
        return Array(Set(allSports)).sorted()
    }

    // MARK: - Dependencies

    private let venueService = VenueService()

    // MARK: - Init

    init() {
        self.selectedCity = MapCity.defaultCity
        Task { await loadVenues(for: MapCity.defaultCity) }
    }

    // MARK: - Actions

    func selectCity(_ city: MapCity) {
        selectedCity = city
        selectedVenue = nil
        selectedSportFilter = nil
        showingCityPicker = false
        Task { await loadVenues(for: city) }
    }

    func loadVenues(for city: MapCity) async {
        isLoading = true

        do {
            venues = try await venueService.discoverVenues(
                latitude: city.latitude,
                longitude: city.longitude,
                city: city.name,
                state: city.state
            )
        } catch {
            // Fallback: Supabase-only → mock data
            do {
                venues = try await venueService.loadVenues(city: city.name, state: city.state)
            } catch {
                print("MapViewModel: Failed to load venues, using fallback: \(error)")
                venues = Venue.venues(for: city.name)
            }
        }

        isLoading = false
    }

    func selectVenue(_ venue: Venue) {
        selectedVenue = venue
        showingVenueDetail = true
    }

    func filterBySport(_ sport: String?) {
        selectedSportFilter = sport
    }
}
