//
//  TierProgressView.swift
//  Checkpoint
//
//  Container showing current tier card + next tier preview + view all button
//

import SwiftUI

struct TierProgressView: View {
    let quitDate: Date
    let currentStreak: Int
    let streakStartedAt: Date?
    let isLoading: Bool

    @State private var showAllTiers = false
    @Environment(\.colorScheme) private var colorScheme

    private var currentTier: StreakTier {
        StreakTier(fromStreak: currentStreak)
    }

    private var nextTier: StreakTier? {
        currentTier.nextTier
    }

    private var daysUntilNextTier: Int {
        guard let nextTierDays = currentTier.daysToNextTier else { return 0 }
        return nextTierDays - currentStreak
    }

    // Calculate when the current tier unlocked (based on tier thresholds)
    private var currentTierUnlockDate: Date {
        let tierUnlockDay: Int
        switch currentTier {
        case .heartbreak: tierUnlockDay = 0
        case .clarity: tierUnlockDay = 7
        case .strength: tierUnlockDay = 14
        case .independence: tierUnlockDay = 23
        case .growth: tierUnlockDay = 36
        case .confidence: tierUnlockDay = 53
        case .peace: tierUnlockDay = 68
        case .freedom: tierUnlockDay = 78
        }
        // Use streak_started_at as the base date (when current streak began)
        let baseDate = streakStartedAt ?? Date()
        return Calendar.current.date(byAdding: .day, value: tierUnlockDay, to: baseDate) ?? baseDate
    }

    var body: some View {
        VStack(spacing: 16) {
            // Show loading skeleton or actual content
            if isLoading {
                // Loading skeleton
                HStack(spacing: 12) {
                    // Left skeleton
                    VStack {
                        Spacer()
                    }
                    .frame(width: 110)
                    .frame(height: 140)
                    .background(AppTheme.Colors.darkSurface.opacity(0.5))
                    .cornerRadius(AppTheme.Radius.medium)

                    // Right skeleton
                    VStack {
                        Spacer()
                    }
                    .frame(width: 200, height: 140)
                    .background(AppTheme.Colors.darkSurface.opacity(0.5))
                    .cornerRadius(AppTheme.Radius.medium)
                }
            } else {
                // Actual content
                HStack(spacing: 12) {
                // Left: Next tier locked preview
                if let nextTier = nextTier {
                    VStack(spacing: 8) {
                        Spacer()

                        VStack(spacing: 2) {
                            Text("\(daysUntilNextTier) \(daysUntilNextTier == 1 ? "day" : "days")")
                                .font(.custom("Satoshi-Bold", size: 18))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .multilineTextAlignment(.center)

                            Text("until next")
                                .font(.custom("Satoshi-Bold", size: 18))
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Text("card")
                                .font(.custom("Satoshi-Bold", size: 18))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        }

                        Spacer()
                    }
                    .frame(width: 110)
                    .frame(height: 140)
                    .background(AppTheme.Colors.darkSurface)
                    .cornerRadius(AppTheme.Radius.medium)
                } else {
                    // At max tier - show celebration
                    VStack(spacing: 8) {
                        Spacer()

                        VStack(spacing: 4) {
                            Text("Max Tier")
                                .font(.custom("Satoshi-Bold", size: 20))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .multilineTextAlignment(.center)

                            Text("Reached!")
                                .font(.custom("Satoshi-Regular", size: 12))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }

                        Spacer()
                    }
                    .frame(width: 110)
                    .frame(height: 140)
                    .background(AppTheme.Colors.darkSurface)
                    .cornerRadius(AppTheme.Radius.medium)
                }

                // Right: Current tier card (compact version)
                // Calculate when current tier unlocked
                CompactTierCard(
                    quitDate: currentTierUnlockDate,
                    currentStreak: currentStreak
                )
                }
            }

            // Button to view trophy case (always show, even when loading)
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                showAllTiers = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 14))
                    Text("View Trophy Case")
                        .font(.custom("Satoshi-Bold", size: 16))
                }
                .foregroundColor(colorScheme == .dark ? Color.black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    colorScheme == .dark
                        ? (isLoading ? Color.white.opacity(0.5) : Color.white)
                        : (isLoading ? Color(red: 0.118, green: 0.118, blue: 0.118).opacity(0.5) : Color(red: 0.118, green: 0.118, blue: 0.118))
                )
                .cornerRadius(AppTheme.Radius.medium)
            }
            .disabled(isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
        .cornerRadius(AppTheme.Radius.large)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .fullScreenCover(isPresented: $showAllTiers) {
            TierCarouselFullscreenView(
                quitDate: quitDate,
                currentStreak: currentStreak,
                streakStartedAt: streakStartedAt
            )
        }
    }
}

// MARK: - Preview

struct TierProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Loading state
                TierProgressView(
                    quitDate: Date(),
                    currentStreak: 0,
                    streakStartedAt: Date(),
                    isLoading: true
                )
                .padding()

                // Loaded state
                TierProgressView(
                    quitDate: Calendar.current.date(byAdding: .day, value: 90, to: Date())!,
                    currentStreak: 3,
                    streakStartedAt: Date().addingTimeInterval(-3 * 24 * 60 * 60),
                    isLoading: false
                )
                .padding()
            }
        }
    }
}
