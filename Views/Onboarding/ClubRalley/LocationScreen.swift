//
//  LocationScreen.swift
//  Club Ralley
//
//  Onboarding screen for location selection (Figma design)
//

import SwiftUI

struct LocationScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController

    @State private var selectedCity: OnboardingCity?

    // Featured cities from Figma
    private let featuredCities: [OnboardingCity] = [
        OnboardingCity(name: "Chicago", state: "Illinois", stateAbbreviation: "IL"),
        OnboardingCity(name: "Dallas", state: "Texas", stateAbbreviation: "TX"),
        OnboardingCity(name: "Austin", state: "Texas", stateAbbreviation: "TX"),
        OnboardingCity(name: "Houston", state: "Texas", stateAbbreviation: "TX"),
        OnboardingCity(name: "New York", state: "New York", stateAbbreviation: "NY"),
        OnboardingCity(name: "Los Angeles", state: "California", stateAbbreviation: "CA")
    ]

    var body: some View {
        ClubRalleyScrollableLayout(
            canGoBack: controller.canGoBack,
            onBack: { controller.goToPreviousStep() },
            onContinue: { saveAndContinue() },
            continueEnabled: selectedCity != nil
        ) {
            VStack(spacing: 24) {
                ClubRalleyOnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: nil
                )

                // City list
                VStack(spacing: 0) {
                    ForEach(featuredCities) { city in
                        LocationRow(
                            city: city,
                            isSelected: selectedCity?.id == city.id,
                            onTap: { selectCity(city) }
                        )
                    }

                    // Coming soon row
                    HStack(spacing: 16) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.gray.opacity(0.4))
                            .frame(width: 32)

                        Text("Other cities coming soon")
                            .font(.system(size: 17))
                            .foregroundColor(.gray)
                            .italic()

                        Spacer()
                    }
                    .padding(.vertical, 16)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 20)
            }
            .padding(.top, 20)
        }
        .onAppear {
            if let cityName = controller.onboardingData.profile.city.isEmpty ? nil : controller.onboardingData.profile.city {
                selectedCity = featuredCities.first { $0.name == cityName } ??
                               OnboardingCity.availableCities.first { $0.name == cityName }
            }
        }
    }

    // MARK: - Actions

    private func selectCity(_ city: OnboardingCity) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedCity = city
        }
        controller.updateLocation(city: city)
    }

    private func saveAndContinue() {
        if let city = selectedCity {
            controller.updateLocation(city: city)
        }
        controller.goToNextStep()
    }
}

// MARK: - Location Row

private struct LocationRow: View {
    let city: OnboardingCity
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Location icon
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? Color(hex: "#2C4F40") : .gray)
                    .frame(width: 32)

                // City name
                Text("\(city.name), \(city.stateAbbreviation)")
                    .font(.system(size: 17))
                    .foregroundColor(.black)

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
            .padding(.vertical, 16)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())

        Divider()
            .padding(.leading, 48)
    }
}

struct LocationScreen_Previews: PreviewProvider {
    static var previews: some View {
        LocationScreen()
            .environmentObject(ClubRalleyOnboardingController())
    }
}
