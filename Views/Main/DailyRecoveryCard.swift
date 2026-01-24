//
//  DailyRecoveryCard.swift
//  Checkpoint
//
//  Daily recovery program card for main dashboard
//

import SwiftUI

struct DailyRecoveryCard: View {
    let dayNumber: Int
    let hasCompletedToday: Bool
    let meditationTitle: String
    let lessonTitle: String

    @State private var showDailyProgram = false
    @Environment(\.colorScheme) private var colorScheme

    // Progress percentages (0-1)
    let checkInComplete: Bool
    let meditationComplete: Bool
    let lessonComplete: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Left side: Brain illustration
            Image(systemName: "brain.head.profile")
                .font(.system(size: 70))
                .foregroundColor(Color(red: 0.95, green: 0.5, blue: 0.5)) // Coral/salmon color

            // Right side: All text content
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text("Recovery Program")
                    .font(.custom("Satoshi-Bold", size: 18))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                // Summary
                Text("Heal your heart with science-backed methods")
                    .font(.custom("Satoshi-Regular", size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)

                // Begin button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showDailyProgram = true
                }) {
                    HStack(spacing: 8) {
                        Text("Begin")
                            .font(.custom("Satoshi-Bold", size: 15))
                            .foregroundColor(colorScheme == .dark ? .black : .white)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(colorScheme == .dark ? .white : .black)
                    .cornerRadius(10)
                }
                .padding(.top, 4)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            LinearGradient(
                colors: [
                    AppTheme.Colors.darkSurface.opacity(0.9),
                    AppTheme.Colors.darkSurface
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppTheme.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .fullScreenCover(isPresented: $showDailyProgram) {
            RecoveryProgramCoordinator()
        }
    }
}

// MARK: - Checkbox Item Component

struct CheckboxItem: View {
    let text: String
    let isChecked: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox circle (on left)
            ZStack {
                Circle()
                    .stroke(AppTheme.Colors.textPrimary, lineWidth: 2)
                    .frame(width: 24, height: 24)

                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.Colors.success)
                }
            }

            Text(text)
                .font(.custom("Satoshi-Medium", size: 16))
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Not completed
        DailyRecoveryCard(
            dayNumber: 47,
            hasCompletedToday: false,
            meditationTitle: "Managing Triggers",
            lessonTitle: "The 'Just One Text' Trap",
            checkInComplete: false,
            meditationComplete: false,
            lessonComplete: false
        )

        // Completed
        DailyRecoveryCard(
            dayNumber: 47,
            hasCompletedToday: true,
            meditationTitle: "Managing Triggers",
            lessonTitle: "The 'Just One Text' Trap",
            checkInComplete: true,
            meditationComplete: true,
            lessonComplete: true
        )
    }
    .padding()
    .background(AppTheme.Colors.background)
}
