//
//  RalleyCreationComponents.swift
//  Club Ralley
//
//  Reusable components for ralley creation
//

import SwiftUI

// MARK: - Sport Selection Card

struct SportSelectionCard: View {
    let sport: RalleySport
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Image(systemName: sport.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : Color(hex: "#2C4F40"))
                    .frame(width: 56, height: 56)
                    .background(
                        isSelected
                            ? Color(hex: "#2C4F40")
                            : Color(hex: "#2C4F40").opacity(0.1)
                    )
                    .cornerRadius(16)

                Text(sport.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "#2C4F40") : .gray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                isSelected
                    ? Color(hex: "#2C4F40").opacity(0.1)
                    : Color.clear
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "#2C4F40") : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Duration Chip

struct DurationChip: View {
    let duration: RalleyDuration
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(duration.shortName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color(hex: "#2C4F40"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    isSelected
                        ? Color(hex: "#2C4F40")
                        : Color(hex: "#2C4F40").opacity(0.1)
                )
                .cornerRadius(20)
        }
    }
}

// MARK: - Player Count Stepper

struct PlayerCountStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                if value > range.lowerBound {
                    value -= 1
                    let feedback = UIImpactFeedbackGenerator(style: .light)
                    feedback.impactOccurred()
                }
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(value > range.lowerBound ? Color(hex: "#2C4F40") : .gray.opacity(0.3))
            }
            .disabled(value <= range.lowerBound)

            Text("\(value)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#2C4F40"))
                .frame(minWidth: 32)

            Button(action: {
                if value < range.upperBound {
                    value += 1
                    let feedback = UIImpactFeedbackGenerator(style: .light)
                    feedback.impactOccurred()
                }
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(value < range.upperBound ? Color(hex: "#2C4F40") : .gray.opacity(0.3))
            }
            .disabled(value >= range.upperBound)
        }
    }
}

// MARK: - Privacy Option Row

struct PrivacyOptionRow: View {
    let title: String
    let description: String
    let iconName: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : Color(hex: "#2C4F40"))
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Color(hex: "#2C4F40") : Color.gray.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
            .padding(12)
            .background(isSelected ? Color(hex: "#2C4F40").opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

// MARK: - Styles & Modifiers

struct RalleyTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
    }
}

extension View {
    func formCard() -> some View {
        self
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Custom Text Field Style (for backwards compatibility)

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
}
