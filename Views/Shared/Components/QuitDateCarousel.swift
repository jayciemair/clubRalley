//
//  QuitDateCarousel.swift
//  Checkpoint
//
//  Swipeable carousel showing all 8 no-contact tiers
//  Use in onboarding to preview progression or in-app to explore tiers
//

import SwiftUI

struct QuitDateCarousel: View {
    let quitDate: Date
    let currentStreak: Int
    let streakStartedAt: Date?
    let showHeader: Bool
    let showContent: Bool

    @State private var currentPage: Int = 0

    // All 8 tiers in order with their unlock days
    private let allTiers: [(tier: StreakTier, unlockDay: Int)] = [
        (.heartbreak, 0),      // Unlocked immediately
        (.clarity, 7),         // Unlocks at day 7
        (.strength, 14),       // Unlocks at day 14
        (.independence, 23),   // Unlocks at day 23
        (.growth, 36),         // Unlocks at day 36
        (.confidence, 53),     // Unlocks at day 53
        (.peace, 68),          // Unlocks at day 68
        (.freedom, 78)         // Unlocks at day 78 (77.7 day goal!)
    ]

    // Calculate when each tier unlocks
    private func unlockDate(forDaysFromNow days: Int) -> Date {
        // Use streak_started_at as base date if available, otherwise use Date() (for onboarding)
        let baseDate = streakStartedAt ?? Date()
        return Calendar.current.date(byAdding: .day, value: days, to: baseDate) ?? baseDate
    }

    // Calculate how many days until a tier unlocks
    private func daysUntilUnlock(forTierDay tierDay: Int) -> Int {
        let baseDate = streakStartedAt ?? Date()
        let targetDate = Calendar.current.date(byAdding: .day, value: tierDay, to: baseDate) ?? baseDate
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: targetDate)
        return max(0, components.day ?? 0)  // Never show negative days
    }

    var body: some View {
        VStack(spacing: 16) {
            // Main header
            Text("We built you a custom plan")
                .font(.custom("Satoshi-Bold", size: 36))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(showHeader ? 1.0 : 0.0)

            // Subtitle (appears with content)
            Text("Swipe to see each tier")
                .font(.custom("Satoshi-Regular", size: 14))
                .foregroundColor(.white.opacity(0.7))
                .opacity(showContent ? 1.0 : 0.0)

            // Horizontal pager - each card shows when THAT tier unlocks
            TabView(selection: $currentPage) {
                ForEach(Array(allTiers.enumerated()), id: \.offset) { index, tierInfo in
                    QuitDateCard(
                        quitDate: unlockDate(forDaysFromNow: tierInfo.unlockDay),
                        currentStreak: tierInfo.unlockDay,  // Use unlock day as streak for tier coloring
                        label: {
                            if tierInfo.tier == .freedom {
                                return "Your over-him date"
                            } else if tierInfo.unlockDay == 0 {
                                return "Unlocked today"
                            } else {
                                return "Unlocks on"
                            }
                        }(),
                        subtitle: {
                            let daysRemaining = daysUntilUnlock(forTierDay: tierInfo.unlockDay)
                            if daysRemaining == 0 {
                                return "\(tierInfo.tier.rawValue) • Start here"
                            } else if daysRemaining == 1 {
                                return "\(tierInfo.tier.rawValue) • 1 day away"
                            } else {
                                return "\(tierInfo.tier.rawValue) • \(daysRemaining) days away"
                            }
                        }()
                    )
                    .padding(.horizontal, 20)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 200)
            .opacity(showContent ? 1.0 : 0.0)

            // Custom page indicator
            HStack(spacing: 8) {
                ForEach(0..<allTiers.count, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
            .opacity(showContent ? 1.0 : 0.0)

            // Current tier info
            VStack(spacing: 4) {
                Text(allTiers[currentPage].tier.rawValue + " Tier")
                    .font(.custom("Satoshi-Bold", size: 20))
                    .foregroundColor(.white)

                Text(tierDescription(for: allTiers[currentPage].tier))
                    .font(.custom("Satoshi-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 8)
            .opacity(showContent ? 1.0 : 0.0)
        }
        .onAppear {
            // For onboarding (streak = 0): Start at Freedom to show the ultimate goal
            // For in-app: Start at user's current tier
            if currentStreak == 0 {
                // New users - start at Freedom (index 7) - the end goal they're working towards
                currentPage = 7
            } else if let userTierIndex = allTiers.firstIndex(where: {
                StreakTier(fromStreak: currentStreak) == $0.tier
            }) {
                currentPage = userTierIndex
            }
        }
    }

    private func tierDescription(for tier: StreakTier) -> String {
        switch tier {
        case .heartbreak:
            return "The initial pain. Every healing journey starts here."
        case .clarity:
            return "The fog is lifting. You're starting to see clearly."
        case .strength:
            return "Two weeks strong. You're building resilience."
        case .independence:
            return "Three weeks in. You're finding yourself again."
        case .growth:
            return "Over one month. Personal development in progress."
        case .confidence:
            return "Almost two months. Your self-worth is restored."
        case .peace:
            return "Inner calm achieved. You're almost there!"
        case .freedom:
            return "77.7 days! you're over him."
        }
    }
}

// MARK: - Preview

struct QuitDateCarousel_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppTheme.Colors.primary
                .ignoresSafeArea()

            QuitDateCarousel(
                quitDate: Calendar.current.date(byAdding: .day, value: 90, to: Date())!,
                currentStreak: 20,
                streakStartedAt: Date(),
                showHeader: true,
                showContent: true
            )
        }
    }
}
