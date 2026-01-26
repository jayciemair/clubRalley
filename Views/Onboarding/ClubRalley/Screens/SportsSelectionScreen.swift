//
//  SportsSelectionScreen.swift
//  Club Ralley
//
//  Sports selection screen for choosing sports and skill levels
//

import SwiftUI

struct SportsSelectionScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController
    @State private var selectedSports: [UserSport] = []
    @State private var availableSports: [Sport] = []
    
    var body: some View {
        OnboardingScrollableLayout {
            VStack(spacing: 32) {
                // Header
                OnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: controller.currentStep.subtitle
                )
                
                VStack(spacing: 24) {
                    Text("Select the sports you play or want to try")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    // Sports grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(availableSports) { sport in
                            SportSelectionCard(
                                sport: sport,
                                isSelected: selectedSports.contains { $0.sport.id == sport.id },
                                onTap: {
                                    toggleSport(sport)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Selected sports with skill levels
                    if !selectedSports.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Set your skill level")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ForEach(selectedSports.indices, id: \.self) { index in
                                SkillLevelSelector(
                                    userSport: $selectedSports[index]
                                )
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                }
                
                Spacer()
                
                // Continue button
                ContinueButton(
                    title: "Continue",
                    isEnabled: !selectedSports.isEmpty,
                    action: {
                        saveAndContinue()
                    }
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    controller.goToPreviousStep()
                }
            }
        }
        .task {
            await loadSports()
        }
        .onAppear {
            selectedSports = controller.onboardingData.interests.selectedSports
        }
    }
    
    private func loadSports() async {
        // Mock sports data
        availableSports = [
            Sport(id: UUID(), name: "Basketball", category: .team, iconName: "basketball.fill", isPopular: true),
            Sport(id: UUID(), name: "Football", category: .team, iconName: "football.fill", isPopular: true),
            Sport(id: UUID(), name: "Soccer", category: .team, iconName: "soccerball", isPopular: true),
            Sport(id: UUID(), name: "Tennis", category: .individual, iconName: "tennisball.fill", isPopular: true),
            Sport(id: UUID(), name: "Swimming", category: .waterSports, iconName: "figure.pool.swim", isPopular: true),
            Sport(id: UUID(), name: "Running", category: .individual, iconName: "figure.run", isPopular: true),
            Sport(id: UUID(), name: "Volleyball", category: .team, iconName: "volleyball.fill", isPopular: true),
            Sport(id: UUID(), name: "Baseball", category: .team, iconName: "baseball.fill", isPopular: true),
            Sport(id: UUID(), name: "Cycling", category: .individual, iconName: "bicycle", isPopular: false),
            Sport(id: UUID(), name: "Golf", category: .individual, iconName: "figure.golf", isPopular: false)
        ]
    }
    
    private func toggleSport(_ sport: Sport) {
        if let index = selectedSports.firstIndex(where: { $0.sport.id == sport.id }) {
            selectedSports.remove(at: index)
        } else {
            let userSport = UserSport(
                id: UUID(),
                userId: UUID(), // Will be set later
                sport: sport,
                skillLevel: .intermediate,
                isPreferred: true,
                createdAt: Date()
            )
            selectedSports.append(userSport)
        }
    }
    
    private func saveAndContinue() {
        controller.updateSportsSelection(selectedSports)
        controller.goToNextStep()
    }
}

// MARK: - Sport Selection Card

struct SportSelectionCard: View {
    let sport: Sport
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        .frame(height: 80)
                    
                    Image(systemName: sport.iconName)
                        .font(.system(size: 30))
                        .foregroundColor(isSelected ? .blue : .secondary)
                }
                
                Text(sport.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Skill Level Selector

struct SkillLevelSelector: View {
    @Binding var userSport: UserSport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(userSport.sport.name)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
            
            HStack(spacing: 8) {
                ForEach(SkillLevel.allCases, id: \.self) { level in
                    Button(action: {
                        userSport = UserSport(
                            id: userSport.id,
                            userId: userSport.userId,
                            sport: userSport.sport,
                            skillLevel: level,
                            isPreferred: userSport.isPreferred,
                            createdAt: userSport.createdAt
                        )
                    }) {
                        VStack(spacing: 4) {
                            Text(level.emoji)
                                .font(.title3)
                            
                            Text(level.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(userSport.skillLevel == level ? .blue : .secondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(userSport.skillLevel == level ? Color.blue.opacity(0.1) : Color(.systemGray6))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

struct SportsSelectionScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SportsSelectionScreen()
                .environmentObject(ClubRalleyOnboardingController())
        }
    }
}