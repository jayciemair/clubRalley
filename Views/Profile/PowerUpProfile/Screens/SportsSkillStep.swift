//
//  SportsSkillStep.swift
//  Club Ralley
//
//  Step 3: Sports selection and skill levels for Power Up Profile
//

import SwiftUI

struct SportsSkillStep: View {
    @EnvironmentObject var viewModel: PowerUpProfileViewModel

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text(PowerUpStep.sportsSkill.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                        .multilineTextAlignment(.center)

                    Text(PowerUpStep.sportsSkill.subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)

                // Sports grid
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select your sports")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.availableSports) { sport in
                            SportSelectionCardPowerUp(
                                sport: sport,
                                isSelected: viewModel.isSportSelected(sport),
                                onTap: {
                                    viewModel.toggleSport(sport)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Selected sports with skill levels
                if !viewModel.data.sportsWithSkills.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Set your skill level")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)

                        VStack(spacing: 12) {
                            ForEach(viewModel.data.sportsWithSkills.indices, id: \.self) { index in
                                let sportWithSkill = viewModel.data.sportsWithSkills[index]
                                SkillLevelPicker(
                                    sport: sportWithSkill.sport,
                                    skillLevel: Binding(
                                        get: { sportWithSkill.skillLevel },
                                        set: { newLevel in
                                            viewModel.updateSkillLevel(for: sportWithSkill.sport.id, to: newLevel)
                                        }
                                    )
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                // Bottom padding for scroll
                Color.clear.frame(height: 120)
            }
        }
    }
}

// MARK: - Sport Selection Card

struct SportSelectionCardPowerUp: View {
    let sport: Sport
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? ClubRalleyTheme.Colors.darkGreen.opacity(0.1) : Color(.systemGray6))
                        .frame(height: 70)

                    Image(systemName: sport.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? ClubRalleyTheme.Colors.darkGreen : .secondary)
                }

                Text(sport.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? ClubRalleyTheme.Colors.darkGreen : Color(.systemGray5), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview

struct SportsSkillStep_Previews: PreviewProvider {
    static var previews: some View {
        SportsSkillStep()
            .environmentObject(PowerUpProfileViewModel())
    }
}
