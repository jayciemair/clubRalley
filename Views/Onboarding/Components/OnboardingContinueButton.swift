//
//  OnboardingContinueButton.swift
//  Dial
//
//  Reusable continue button for onboarding screens
//

import SwiftUI

struct OnboardingContinueButton: View {
    let action: () -> Void
    let text: String
    let buttonColor: Color
    let textColor: Color

    init(
        action: @escaping () -> Void,
        text: String = "continue",
        buttonColor: Color = Color(red: 0.996, green: 0.612, blue: 0.867), // #FE9CDD - Mochi pink
        textColor: Color = .white
    ) {
        self.action = action
        self.text = text
        self.buttonColor = buttonColor
        self.textColor = textColor
    }

    var body: some View {
        Button(action: {
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            action()
        }) {
            HStack(spacing: 8) {
                Text(text)
                    .font(.custom("Satoshi-Bold", size: 18))
                    .tracking(0.3)

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(buttonColor)
            .clipShape(RoundedRectangle(cornerRadius: 28)) // More rounded
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, AppTheme.Spacing.xl)
        .padding(.bottom, AppTheme.Spacing.xl)
    }
}
