//
//  OnboardingProgressBar.swift
//  Checkpoint
//
//  Simple progress bar component for onboarding screens
//

import SwiftUI

/// Simple progress bar component for onboarding screens
struct OnboardingProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.Colors.border)
                    .frame(height: 8)

                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.Colors.primary)
                    .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 8)
    }
}
