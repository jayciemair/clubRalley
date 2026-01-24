//
//  TierCarouselFullscreenView.swift
//  Checkpoint
//
//  Trophy case view showing all tier cards in a premium display
//  Unlocked cards glow with achievement, locked cards await discovery
//

import SwiftUI

struct TierCarouselFullscreenView: View {
    @Environment(\.dismiss) var dismiss

    let quitDate: Date
    let currentStreak: Int
    let streakStartedAt: Date?

    @State private var shimmerPhase: CGFloat = 0

    // All 8 tiers with unlock days
    private let allTiers: [(tier: StreakTier, unlockDay: Int)] = [
        (.heartbreak, 0),
        (.clarity, 7),
        (.strength, 14),
        (.independence, 23),
        (.growth, 36),
        (.confidence, 53),
        (.peace, 68),
        (.freedom, 78)
    ]

    private var currentTier: StreakTier {
        StreakTier(fromStreak: currentStreak)
    }

    private var unlockedCount: Int {
        allTiers.filter { !isLocked(tierUnlockDay: $0.unlockDay) }.count
    }

    private func unlockDate(forDaysFromNow days: Int) -> Date {
        let baseDate = streakStartedAt ?? Date()
        return Calendar.current.date(byAdding: .day, value: days, to: baseDate) ?? baseDate
    }

    private func isLocked(tierUnlockDay: Int) -> Bool {
        return currentStreak < tierUnlockDay
    }

    var body: some View {
        ZStack {
            // Rich trophy case background
            trophyCaseBackground

            // Content
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection

                    // Collection stats
                    collectionStats
                        .padding(.top, 8)
                        .padding(.bottom, 24)

                    // Unlocked section
                    if unlockedCount > 0 {
                        sectionHeader(title: "YOUR COLLECTION", icon: "trophy.fill", color: .yellow)
                            .padding(.bottom, 16)

                        unlockedCardsSection
                            .padding(.bottom, 32)
                    }

                    // Locked section
                    if unlockedCount < allTiers.count {
                        sectionHeader(title: "COMING SOON", icon: "lock.fill", color: .gray)
                            .padding(.bottom, 16)

                        lockedCardsSection
                    }

                    // Bottom spacing
                    Color.clear.frame(height: 60)
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                shimmerPhase = 1
            }
        }
    }

    // MARK: - Trophy Case Background

    private var trophyCaseBackground: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep velvet base - rich purple/burgundy
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.08, green: 0.04, blue: 0.10), location: 0.0),
                        .init(color: Color(red: 0.12, green: 0.06, blue: 0.14), location: 0.3),
                        .init(color: Color(red: 0.10, green: 0.05, blue: 0.12), location: 0.6),
                        .init(color: Color(red: 0.06, green: 0.03, blue: 0.08), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Warm golden ambient light from top
                RadialGradient(
                    colors: [
                        Color(red: 0.6, green: 0.45, blue: 0.2).opacity(0.3),
                        Color(red: 0.4, green: 0.3, blue: 0.15).opacity(0.15),
                        .clear
                    ],
                    center: .init(x: 0.5, y: 0.0),
                    startRadius: 0,
                    endRadius: geometry.size.height * 0.6
                )

                // Subtle spotlight effect
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        .clear
                    ],
                    center: .init(x: 0.5, y: 0.15),
                    startRadius: 0,
                    endRadius: geometry.size.width * 0.8
                )

                // Bottom warm glow
                RadialGradient(
                    colors: [
                        Color(red: 0.5, green: 0.35, blue: 0.15).opacity(0.2),
                        .clear
                    ],
                    center: .init(x: 0.5, y: 1.1),
                    startRadius: 0,
                    endRadius: geometry.size.width * 0.9
                )

                // Vignette for depth
                RadialGradient(
                    colors: [
                        .clear,
                        Color.black.opacity(0.4)
                    ],
                    center: .center,
                    startRadius: geometry.size.width * 0.4,
                    endRadius: geometry.size.width * 1.2
                )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        ZStack {
            // Title with trophy icon
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.85, blue: 0.4),
                                    Color(red: 0.9, green: 0.7, blue: 0.2)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text("Trophy Case")
                        .font(.custom("Satoshi-Bold", size: 28))
                        .foregroundColor(.white)
                }

                Text("Your achievement collection")
                    .font(.custom("Satoshi-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }

            // Close button - top left
            HStack {
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
    }

    // MARK: - Collection Stats

    private var collectionStats: some View {
        HStack(spacing: 24) {
            statPill(value: "\(unlockedCount)/8", label: "Collected")
            statPill(value: currentTier.rawValue, label: "Current Tier")
        }
        .padding(.horizontal, 24)
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.custom("Satoshi-Bold", size: 18))
                .foregroundColor(.white)
            Text(label)
                .font(.custom("Satoshi-Regular", size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Section Header

    private func sectionHeader(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)

            Text(title)
                .font(.custom("Satoshi-Bold", size: 14))
                .foregroundColor(.white.opacity(0.8))
                .tracking(1.5)

            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Unlocked Cards Section

    private var unlockedCardsSection: some View {
        let unlockedTiers = allTiers.filter { !isLocked(tierUnlockDay: $0.unlockDay) }

        return VStack(spacing: 20) {
            ForEach(unlockedTiers.indices, id: \.self) { index in
                let tierInfo = unlockedTiers[index]
                let tierUnlockDate = unlockDate(forDaysFromNow: tierInfo.unlockDay)
                let isCurrentTier = tierInfo.tier == currentTier

                VStack(spacing: 12) {
                    // Card with glow effect
                    ZStack {
                        // Glow halo for unlocked cards
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium + 8)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        tierGlowColor(for: tierInfo.tier).opacity(isCurrentTier ? 0.4 : 0.2),
                                        tierGlowColor(for: tierInfo.tier).opacity(0.1),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 200
                                )
                            )
                            .frame(height: 220)
                            .blur(radius: 20)

                        // The card itself
                        QuitDateCard(
                            quitDate: tierUnlockDate,
                            currentStreak: tierInfo.unlockDay,
                            label: isCurrentTier ? "Current tier" : "Unlocked on",
                            subtitle: "\(tierInfo.tier.rawValue) \(tierInfo.tier.icon)"
                        )
                        .shadow(color: tierGlowColor(for: tierInfo.tier).opacity(0.3), radius: 15, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)

                    // Achievement badge
                    if isCurrentTier {
                        currentTierBadge
                    } else {
                        Text(tierDescription(for: tierInfo.tier))
                            .font(.custom("Satoshi-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
            }
        }
    }

    private var currentTierBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 12))
            Text("CURRENT TIER")
                .font(.custom("Satoshi-Bold", size: 12))
                .tracking(1)
        }
        .foregroundColor(.black)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.85, blue: 0.4),
                            Color(red: 0.95, green: 0.75, blue: 0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }

    // MARK: - Locked Cards Section

    private var lockedCardsSection: some View {
        let lockedTiers = allTiers.filter { isLocked(tierUnlockDay: $0.unlockDay) }

        return VStack(spacing: 20) {
            ForEach(lockedTiers.indices, id: \.self) { index in
                let tierInfo = lockedTiers[index]
                let tierUnlockDate = unlockDate(forDaysFromNow: tierInfo.unlockDay)
                let daysRemaining = tierInfo.unlockDay - currentStreak

                VStack(spacing: 12) {
                    ZStack {
                        // Card (dimmed)
                        QuitDateCard(
                            quitDate: tierUnlockDate,
                            currentStreak: tierInfo.unlockDay,
                            label: "Unlocks on",
                            subtitle: "\(tierInfo.tier.rawValue) • \(tierInfo.unlockDay) days"
                        )
                        .opacity(0.35)
                        .blur(radius: 1)

                        // Frosted glass overlay
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .fill(Color.black.opacity(0.3))
                            .frame(height: 200)

                        // Lock icon and countdown
                        VStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))

                            Text("\(daysRemaining) days to unlock")
                                .font(.custom("Satoshi-Bold", size: 16))
                                .foregroundColor(.white.opacity(0.9))

                            Text(tierInfo.tier.rawValue)
                                .font(.custom("Satoshi-Medium", size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 24)

                    // Tier preview description
                    Text(tierDescription(for: tierInfo.tier))
                        .font(.custom("Satoshi-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
    }

    // MARK: - Helpers

    private func tierGlowColor(for tier: StreakTier) -> Color {
        switch tier {
        case .heartbreak:
            return Color(red: 0.8, green: 0.5, blue: 0.6)
        case .clarity:
            return Color(red: 0.75, green: 0.73, blue: 0.82)
        case .strength:
            return Color(red: 1.0, green: 0.8, blue: 0.2)
        case .independence:
            return Color(red: 0.9, green: 0.9, blue: 1.0)
        case .growth:
            return Color(red: 0.2, green: 0.8, blue: 0.5)
        case .confidence:
            return Color(red: 0.9, green: 0.2, blue: 0.3)
        case .peace:
            return Color(red: 0.6, green: 0.85, blue: 1.0)
        case .freedom:
            return Color(red: 0.7, green: 0.5, blue: 0.9)
        }
    }

    private func tierDescription(for tier: StreakTier) -> String {
        switch tier {
        case .heartbreak:
            return "Every healing journey begins with a single step."
        case .clarity:
            return "The fog is lifting, one day at a time."
        case .strength:
            return "Two weeks of resilience and determination."
        case .independence:
            return "Three weeks in. Finding yourself again."
        case .growth:
            return "One month strong. Personal development in progress."
        case .confidence:
            return "Almost two months. Self-worth restored."
        case .peace:
            return "Inner calm achieved. The finish line awaits."
        case .freedom:
            return "77.7 days. you're over him."
        }
    }
}

// MARK: - Preview

struct TierCarouselFullscreenView_Previews: PreviewProvider {
    static var previews: some View {
        TierCarouselFullscreenView(
            quitDate: Calendar.current.date(byAdding: .day, value: 90, to: Date())!,
            currentStreak: 70,  // Diamond tier for preview
            streakStartedAt: Date().addingTimeInterval(-70 * 24 * 60 * 60)
        )
    }
}
