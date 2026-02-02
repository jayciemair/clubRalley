//
//  LocationSettingsView.swift
//  Club Ralley
//
//  Location settings and city picker
//

import SwiftUI

struct LocationSettingsView: View {
    @AppStorage("locationServicesEnabled") private var locationServicesEnabled: Bool = true
    @State private var selectedCity: OnboardingCity?
    @State private var currentCity: String = ""
    @State private var currentState: String = ""

    var body: some View {
        List {
            Section {
                Toggle("Enable Location Services", isOn: $locationServicesEnabled)
            } header: {
                Text("Location Services")
            } footer: {
                Text("Allow Club Ralley to use your location to find nearby ralleys and athletes.")
            }

            Section {
                if let city = selectedCity {
                    HStack {
                        Text("Current City")
                        Spacer()
                        Text(city.displayName)
                            .foregroundColor(.gray)
                    }
                } else if !currentCity.isEmpty {
                    HStack {
                        Text("Current City")
                        Spacer()
                        Text("\(currentCity), \(currentState)")
                            .foregroundColor(.gray)
                    }
                }

                NavigationLink(destination: CityPickerView(selectedCity: $selectedCity, onSave: saveCity)) {
                    HStack {
                        Text("Change City")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            } header: {
                Text("Default City")
            } footer: {
                Text("This is the city shown on your profile and used for finding local ralleys.")
            }
        }
        .navigationTitle("Location")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentCity()
        }
    }

    private func loadCurrentCity() {
        if let profile = SavedUserProfile.loadFromStorage() {
            currentCity = profile.locationCity
            currentState = profile.locationState
        }
    }

    private func saveCity() {
        guard let city = selectedCity else { return }

        // Update saved profile
        if let profile = SavedUserProfile.loadFromStorage() {
            let updatedProfile = SavedUserProfile(
                id: profile.id,
                email: profile.email,
                firstName: profile.firstName,
                lastName: profile.lastName,
                username: profile.username,
                phoneNumber: profile.phoneNumber,
                locationCity: city.name,
                locationState: city.stateAbbreviation,
                profilePhotoURL: profile.profilePhotoURL,
                selectedSports: profile.selectedSports,
                createdAt: profile.createdAt
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(updatedProfile) {
                UserDefaults.standard.set(data, forKey: "currentUserProfile")
            }
        }

        currentCity = city.name
        currentState = city.stateAbbreviation
    }
}

// MARK: - City Picker View

struct CityPickerView: View {
    @Binding var selectedCity: OnboardingCity?
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredCities: [OnboardingCity] {
        if searchText.isEmpty {
            return OnboardingCity.availableCities
        }
        return OnboardingCity.availableCities.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.state.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            ForEach(filteredCities, id: \.id) { city in
                Button(action: {
                    selectedCity = city
                    onSave()
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(city.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                            Text(city.state)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        if selectedCity?.id == city.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(ClubRalleyTheme.Colors.accent)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search cities")
        .navigationTitle("Select City")
        .navigationBarTitleDisplayMode(.inline)
    }
}
