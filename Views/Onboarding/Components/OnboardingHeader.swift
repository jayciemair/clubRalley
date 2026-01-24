//
//  OnboardingHeader.swift
//  Dial
//
//  Reusable header with back button and badge for onboarding screens
//

import SwiftUI

struct OnboardingHeader: View {
    let badge: String?
    let showBackButton: Bool
    let buttonColor: Color

    init(
        badge: String? = nil,
        showBackButton: Bool = true,
        buttonColor: Color = .black
    ) {
        self.badge = badge
        self.showBackButton = showBackButton
        self.buttonColor = buttonColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            if showBackButton {
                HStack(spacing: 8) {
                    OnboardingBackButton(color: buttonColor)
                    Spacer()
                }
            }

            if let badge = badge {
                Text(badge)
                    .font(.custom("Satoshi-Medium", size: 14))
                    .foregroundColor(AppTheme.Colors.primary)
                    .tracking(1.5)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .stroke(AppTheme.Colors.primary, lineWidth: 1)
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, 30)
    }
}
