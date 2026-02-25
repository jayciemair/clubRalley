//
//  SportsOnboardingScreen.swift
//  Club Ralley
//
//  Onboarding screen for sports selection (Figma design)
//

import SwiftUI

struct SportsOnboardingScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController

    @State private var selectedSports: Set<String> = []
    @State private var lovesAllSports = false

    private let sports = [
        ("Tennis", "tennisball.fill"),
        ("Golf", "figure.golf"),
        ("Soccer", "soccerball"),
        ("Volleyball", "volleyball.fill"),
        ("Pickleball", "figure.pickleball"),
        ("Basketball", "basketball.fill"),
        ("Running", "figure.run"),
        ("Cycling", "bicycle"),
        ("Swimming", "figure.pool.swim"),
        ("Hiking", "figure.hiking"),
        ("Yoga", "figure.yoga"),
        ("CrossFit", "dumbbell.fill")
    ]

    var body: some View {
        ClubRalleyScrollableLayout(
            canGoBack: controller.canGoBack,
            onBack: { controller.goToPreviousStep() },
            onContinue: { saveAndContinue() },
            continueEnabled: !selectedSports.isEmpty || lovesAllSports
        ) {
            VStack(spacing: 24) {
                ClubRalleyOnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: nil
                )

                // Sports list
                VStack(spacing: 0) {
                    ForEach(sports, id: \.0) { sport in
                        SportRow(
                            name: sport.0,
                            icon: sport.1,
                            isSelected: selectedSports.contains(sport.0),
                            onTap: { toggleSport(sport.0) }
                        )
                    }
                }
                .padding(.horizontal, 24)

                // "I love all sports" button
                Button(action: {
                    withAnimation {
                        lovesAllSports.toggle()
                        if lovesAllSports {
                            selectedSports = Set(sports.map { $0.0 })
                        } else {
                            selectedSports.removeAll()
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: lovesAllSports ? "checkmark.circle.fill" : "heart.fill")
                            .font(.system(size: 20))
                            .foregroundColor(lovesAllSports ? Color(hex: "#2C4F40") : .gray)

                        Text("I love all sports")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(ClubRalleyTheme.Colors.darkGreen)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(lovesAllSports ? Color(hex: "#2C4F40") : Color.gray.opacity(0.3), lineWidth: lovesAllSports ? 2 : 1)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer(minLength: 20)
            }
            .padding(.top, 20)
        }
        .onAppear {
            // Load previously selected sports
            let existingSports = controller.onboardingData.interests.selectedSports.map { $0.sport.name }
            selectedSports = Set(existingSports)
        }
    }

    private func toggleSport(_ sport: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedSports.contains(sport) {
                selectedSports.remove(sport)
                lovesAllSports = false
            } else {
                selectedSports.insert(sport)
                if selectedSports.count == sports.count {
                    lovesAllSports = true
                }
            }
        }
    }

    private func saveAndContinue() {
        // Convert selected sports to UserSport objects
        let userSports: [UserSport] = selectedSports.map { sportName in
            let sport = Sport(
                id: UUID(),
                name: sportName,
                category: .recreational,
                iconName: sportIcon(for: sportName),
                isPopular: true
            )
            return UserSport(
                id: UUID(),
                userId: UUID(),
                sport: sport,
                skillLevel: .intermediate,
                isPreferred: true,
                createdAt: Date()
            )
        }
        controller.updateSportsSelection(userSports)
        controller.goToNextStep()
    }

    private func sportIcon(for name: String) -> String {
        switch name {
        case "Tennis": return "tennisball.fill"
        case "Golf": return "figure.golf"
        case "Soccer": return "soccerball"
        case "Volleyball": return "volleyball.fill"
        case "Pickleball": return "figure.pickleball"
        case "Basketball": return "basketball.fill"
        case "Running": return "figure.run"
        case "Cycling": return "bicycle"
        case "Swimming": return "figure.pool.swim"
        case "Hiking": return "figure.hiking"
        case "Yoga": return "figure.yoga"
        case "CrossFit": return "dumbbell.fill"
        default: return "sportscourt"
        }
    }
}

// MARK: - Sport Row

private struct SportRow: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Sport icon
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? Color(hex: "#2C4F40") : .gray)
                    .frame(width: 32)

                // Sport name
                Text(name)
                    .font(.system(size: 17))
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)

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

struct SportsOnboardingScreen_Previews: PreviewProvider {
    static var previews: some View {
        SportsOnboardingScreen()
            .environmentObject(ClubRalleyOnboardingController())
    }
}
