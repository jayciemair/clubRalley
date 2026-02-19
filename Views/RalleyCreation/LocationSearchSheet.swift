//
//  LocationSearchSheet.swift
//  Club Ralley
//
//  Location search sheet for ralley creation
//

import SwiftUI
import MapKit

// MARK: - Location Search Sheet

struct LocationSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var locationName: String
    @Binding var locationAddress: String
    @Binding var locationCity: String
    @Binding var locationState: String
    @Binding var locationLatitude: Double
    @Binding var locationLongitude: Double

    @State private var searchText = ""
    @State private var searchResults: [LocationSuggestion] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var defaultSuggestions: [LocationSuggestion] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)

                    TextField("Search parks, courts, fields...", text: $searchText)
                        .font(.system(size: 16))
                        .autocorrectionDisabled()
                        .onChange(of: searchText) { _, newValue in
                            searchLocations(query: newValue)
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = defaultSuggestions
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding()

                Divider()

                // Results List
                if isSearching {
                    ProgressView()
                        .padding(.top, 40)
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No locations found")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 60)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Manual Entry Option
                            Button(action: {
                                locationName = searchText.isEmpty ? "Custom Location" : searchText
                                locationAddress = ""
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(hex: "#2C4F40"))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Enter custom location")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.black)
                                        Text("Type any address or place name")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()
                                }
                                .padding(16)
                            }

                            Divider().padding(.leading, 48)

                            // Search Results
                            ForEach(searchResults) { location in
                                Button(action: {
                                    selectLocation(location)
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: location.iconName)
                                            .font(.system(size: 18))
                                            .foregroundColor(Color(hex: "#2C4F40"))
                                            .frame(width: 36, height: 36)
                                            .background(Color(hex: "#2C4F40").opacity(0.1))
                                            .cornerRadius(8)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(location.name)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.black)
                                            Text(location.address)
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray)
                                        }

                                        Spacer()
                                    }
                                    .padding(16)
                                }

                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Find Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
        .onAppear {
            loadNearbyLocations()
        }
    }

    // MARK: - Search

    private func searchLocations(query: String) {
        searchTask?.cancel()

        guard !query.isEmpty else {
            searchResults = defaultSuggestions
            isSearching = false
            return
        }

        isSearching = true

        searchTask = Task {
            // Debounce: wait 300ms before searching
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            // Bias results toward Lewisburg, PA area
            request.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.9568, longitude: -76.8844),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )

            do {
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                guard !Task.isCancelled else { return }

                let suggestions = response.mapItems.compactMap { item -> LocationSuggestion? in
                    guard let name = item.name else { return nil }
                    let placemark = item.placemark
                    return LocationSuggestion(
                        name: name,
                        address: placemark.formattedAddress,
                        city: placemark.locality ?? "Lewisburg",
                        state: placemark.administrativeArea ?? "PA",
                        type: inferLocationType(from: item),
                        latitude: placemark.coordinate.latitude,
                        longitude: placemark.coordinate.longitude
                    )
                }

                await MainActor.run {
                    searchResults = suggestions
                    isSearching = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }

    private func loadNearbyLocations() {
        // Show mock data immediately, then replace with Supabase venues
        let mockSuggestions = Venue.allVenues.map { venue in
            LocationSuggestion(
                name: venue.name,
                address: venue.address,
                city: venue.city,
                state: venue.state,
                type: venue.type,
                latitude: venue.latitude,
                longitude: venue.longitude
            )
        }
        defaultSuggestions = mockSuggestions
        searchResults = mockSuggestions

        // Load venues from Supabase + Overpass discovery
        Task {
            let venueService = VenueService()
            do {
                let city = MapCity.defaultCity
                let venues = try await venueService.discoverVenues(
                    latitude: city.latitude,
                    longitude: city.longitude,
                    city: city.name,
                    state: city.state
                )
                let suggestions = venues.map { venue in
                    LocationSuggestion(
                        name: venue.name,
                        address: venue.address,
                        city: venue.city,
                        state: venue.state,
                        type: venue.type,
                        latitude: venue.latitude,
                        longitude: venue.longitude
                    )
                }
                if !suggestions.isEmpty {
                    defaultSuggestions = suggestions
                    // Only replace if user hasn't started typing
                    if searchText.isEmpty {
                        searchResults = suggestions
                    }
                }
            } catch {
                print("LocationSearchSheet: Failed to load Supabase venues, using mock data: \(error)")
            }
        }
    }

    private func selectLocation(_ location: LocationSuggestion) {
        locationName = location.name
        locationAddress = location.address
        locationCity = location.city
        locationState = location.state
        locationLatitude = location.latitude
        locationLongitude = location.longitude
        dismiss()
    }

    // MARK: - Helpers

    private func inferLocationType(from item: MKMapItem) -> LocationSuggestion.LocationType {
        if let category = item.pointOfInterestCategory {
            switch category {
            case .park, .nationalPark:
                return .park
            case .fitnessCenter:
                return .gym
            case .stadium:
                return .field
            default:
                break
            }
        }
        // Fallback: check the name for keywords
        let name = (item.name ?? "").lowercased()
        if name.contains("park") || name.contains("trail") {
            return .park
        } else if name.contains("gym") || name.contains("fitness") || name.contains("recreation") {
            return .gym
        } else if name.contains("field") || name.contains("stadium") {
            return .field
        } else if name.contains("court") {
            return .court
        }
        return .other
    }
}

// MARK: - MKPlacemark Address Helper

extension MKPlacemark {
    var formattedAddress: String {
        let components = [subThoroughfare, thoroughfare, locality, administrativeArea]
        return components.compactMap { $0 }.joined(separator: " ")
    }
}

// MARK: - Location Suggestion Model

struct LocationSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let city: String
    let state: String
    let type: LocationType
    let latitude: Double
    let longitude: Double

    var iconName: String {
        type.iconName
    }

    enum LocationType {
        case park
        case court
        case field
        case gym
        case other

        var iconName: String {
            switch self {
            case .park: return "leaf.fill"
            case .court: return "sportscourt.fill"
            case .field: return "figure.soccer"
            case .gym: return "dumbbell.fill"
            case .other: return "mappin.circle.fill"
            }
        }
    }
}
