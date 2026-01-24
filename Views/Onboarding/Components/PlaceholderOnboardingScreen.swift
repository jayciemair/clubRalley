//
//  PlaceholderOnboardingScreen.swift
//  Checkpoint
//
//  Temporary placeholder for screens that haven't been implemented yet
//

import SwiftUI

struct PlaceholderOnboardingScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController

    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            OnboardingProgressBar(progress: flowController.flowProgress)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.md)

            Spacer()

            // Content
            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: systemImage)
                    .font(.system(size: 64))
                    .foregroundColor(AppTheme.Colors.primary)

                Text(title)
                    .font(.custom("Satoshi-Bold", size: 28))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }

            Spacer()

            // Navigation buttons
            VStack(spacing: AppTheme.Spacing.md) {
                Button("Continue") {
                    flowController.navigateNext()
                }
                .primaryButtonStyle()

                if let currentScreen = flowController.currentScreen,
                   currentScreen.isSkippable {
                    Button("Skip") {
                        flowController.skip()
                    }
                    .textButtonStyle()
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
    }
}
