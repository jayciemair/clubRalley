//
//  SkillLevelPicker.swift
//  Club Ralley
//
//  Skill level picker component (Rookie/Competitor/All-Star)
//

import SwiftUI

struct SkillLevelPicker: View {
    let sport: Sport
    @Binding var skillLevel: PowerUpSkillLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Sport name header
            HStack(spacing: 8) {
                Image(systemName: sport.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)

                Text(sport.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }

            // Skill level buttons
            HStack(spacing: 8) {
                ForEach(PowerUpSkillLevel.allCases, id: \.self) { level in
                    SkillLevelButton(
                        level: level,
                        isSelected: skillLevel == level,
                        onTap: { skillLevel = level }
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
        )
    }
}

// MARK: - Skill Level Button

struct SkillLevelButton: View {
    let level: PowerUpSkillLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(level.emoji)
                    .font(.system(size: 20))

                Text(level.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? ClubRalleyTheme.Colors.darkGreen.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? ClubRalleyTheme.Colors.darkGreen : Color.clear, lineWidth: 2)
            )
            .foregroundColor(isSelected ? ClubRalleyTheme.Colors.darkGreen : .secondary)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Compact Skill Level Picker (Inline)

struct SkillLevelPickerCompact: View {
    @Binding var skillLevel: PowerUpSkillLevel

    var body: some View {
        HStack(spacing: 6) {
            ForEach(PowerUpSkillLevel.allCases, id: \.self) { level in
                Button(action: { skillLevel = level }) {
                    HStack(spacing: 4) {
                        Text(level.emoji)
                            .font(.system(size: 14))
                        Text(level.displayName)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(skillLevel == level ? ClubRalleyTheme.Colors.darkGreen : Color(.systemGray6))
                    )
                    .foregroundColor(skillLevel == level ? .white : .primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Preview

struct SkillLevelPicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SkillLevelPicker(
                sport: Sport(id: UUID(), name: "Basketball", category: .team, iconName: "basketball.fill", isPopular: true),
                skillLevel: .constant(.competitor)
            )

            SkillLevelPicker(
                sport: Sport(id: UUID(), name: "Tennis", category: .individual, iconName: "tennisball.fill", isPopular: true),
                skillLevel: .constant(.rookie)
            )

            SkillLevelPickerCompact(skillLevel: .constant(.allStar))
        }
        .padding()
        .background(Color(.systemGray6))
    }
}
