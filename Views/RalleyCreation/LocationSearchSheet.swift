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

    @State private var searchText = ""
    @State private var searchResults: [LocationSuggestion] = []
    @State private var isSearching = false

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
                        Button(action: { searchText = "" }) {
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

    private func searchLocations(query: String) {
        guard !query.isEmpty else {
            loadNearbyLocations()
            return
        }

        isSearching = true

        // Simulate search with mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            searchResults = LocationSuggestion.mockSearchResults(for: query)
            isSearching = false
        }
    }

    private func loadNearbyLocations() {
        searchResults = LocationSuggestion.mockNearbyLocations()
    }

    private func selectLocation(_ location: LocationSuggestion) {
        locationName = location.name
        locationAddress = location.address
        locationCity = location.city
        locationState = location.state
        dismiss()
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

    static func mockNearbyLocations() -> [LocationSuggestion] {
        [
            LocationSuggestion(name: "Golden Gate Park Tennis Courts", address: "501 Stanyan St", city: "San Francisco", state: "CA", type: .court, latitude: 37.7694, longitude: -122.4533),
            LocationSuggestion(name: "Dolores Park", address: "19th & Dolores St", city: "San Francisco", state: "CA", type: .park, latitude: 37.7596, longitude: -122.4269),
            LocationSuggestion(name: "Mission Rec Center", address: "745 Treat Ave", city: "San Francisco", state: "CA", type: .gym, latitude: 37.7558, longitude: -122.4145),
            LocationSuggestion(name: "Potrero Hill Rec Center", address: "801 Arkansas St", city: "San Francisco", state: "CA", type: .court, latitude: 37.7559, longitude: -122.3961),
            LocationSuggestion(name: "Marina Green", address: "Marina Blvd", city: "San Francisco", state: "CA", type: .field, latitude: 37.8066, longitude: -122.4374)
        ]
    }

    static func mockSearchResults(for query: String) -> [LocationSuggestion] {
        let allLocations = mockNearbyLocations() + [
            LocationSuggestion(name: "Crissy Field", address: "Mason St & Halleck St", city: "San Francisco", state: "CA", type: .field, latitude: 37.8038, longitude: -122.4658),
            LocationSuggestion(name: "Kezar Pavilion", address: "755 Stanyan St", city: "San Francisco", state: "CA", type: .gym, latitude: 37.7668, longitude: -122.4537),
            LocationSuggestion(name: "Ocean Beach", address: "Great Highway", city: "San Francisco", state: "CA", type: .other, latitude: 37.7593, longitude: -122.5107)
        ]

        return allLocations.filter {
            $0.name.lowercased().contains(query.lowercased()) ||
            $0.address.lowercased().contains(query.lowercased())
        }
    }
}
