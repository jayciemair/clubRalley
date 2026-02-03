//
//  YesNoToggle.swift
//  Club Ralley
//
//  Yes/No toggle component for Power Up Profile
//

import SwiftUI

struct YesNoToggle: View {
    let question: String
    @Binding var value: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                YesNoButton(
                    text: "Yes",
                    icon: "hand.thumbsup.fill",
                    isSelected: value == true,
                    onTap: { value = true }
                )

                YesNoButton(
                    text: "No",
                    icon: "hand.thumbsdown.fill",
                    isSelected: value == false,
                    onTap: { value = false }
                )
            }
        }
    }
}

// MARK: - Yes/No Button

struct YesNoButton: View {
    let text: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))

                Text(text)
                    .font(.system(size: 15, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? ClubRalleyTheme.Colors.darkGreen : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? ClubRalleyTheme.Colors.darkGreen : Color(.systemGray5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Simple Toggle (Pill Style)

struct YesNoPillToggle: View {
    @Binding var value: Bool?

    var body: some View {
        HStack(spacing: 0) {
            // Yes button
            Button(action: { value = true }) {
                Text("Yes")
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(value == true ? ClubRalleyTheme.Colors.darkGreen : Color.clear)
                    .foregroundColor(value == true ? .white : .primary)
            }
            .buttonStyle(PlainButtonStyle())

            // No button
            Button(action: { value = false }) {
                Text("No")
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(value == false ? ClubRalleyTheme.Colors.darkGreen : Color.clear)
                    .foregroundColor(value == false ? .white : .primary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color(.systemGray6))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

// MARK: - Preview

struct YesNoToggle_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            YesNoToggle(
                question: "Would you go to happy hour?",
                value: .constant(nil)
            )

            YesNoToggle(
                question: "Would you go to happy hour?",
                value: .constant(true)
            )

            YesNoToggle(
                question: "Would you go to happy hour?",
                value: .constant(false)
            )

            Divider()

            HStack {
                Text("Pill style:")
                YesNoPillToggle(value: .constant(true))
                    .frame(width: 120)
            }
        }
        .padding()
    }
}
