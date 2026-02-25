//
//  CompactTierCard.swift
//  Checkpoint
//
//  Compact tier card for container views - shows gradient, tier name, and date
//  Used in TierProgressView for displaying current tier in minimal space
//

import SwiftUI

struct CompactTierCard: View {
    let quitDate: Date
    let currentStreak: Int

    private var tier: StreakTier {
        StreakTier(fromStreak: currentStreak)
    }

    // Format date as "Feb 9, 2026" (abbreviated)
    private var formattedQuitDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: quitDate)
    }

    var body: some View {
        VStack(spacing: 8) {
            Spacer()

            // Tier name
            Text(tier.rawValue)
                .font(.custom("Satoshi-Bold", size: 24))
                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)

            // Quit date (compact format)
            Text(formattedQuitDate)
                .font(.custom("Satoshi-Regular", size: 16))
                .foregroundColor(.black.opacity(0.7))

            // Branding
            Text("Checkpoint Card")
                .font(.custom("Satoshi-Regular", size: 10))
                .foregroundColor(.black.opacity(0.6))

            Spacer()
        }
        .frame(width: 200, height: 140)  // Fixed dimensions for rectangular shape
        .aspectRatio(contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: tier.gradient),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: tier.borderGradient),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
                .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 2)
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
        )
        .onTapGesture {
            // Easter egg - haptic feedback when tapping the card
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
    }
}

// MARK: - Preview

struct CompactTierCard_Previews: PreviewProvider {
    static var previews: some View {
        let quitDate = Calendar.current.date(byAdding: .day, value: 90, to: Date())!
        HStack(spacing: 12) {
            // Preview different tiers
            CompactTierCard(quitDate: quitDate, currentStreak: 3)  // Bronze
            CompactTierCard(quitDate: quitDate, currentStreak: 10)  // Silver
            CompactTierCard(quitDate: quitDate, currentStreak: 20)  // Gold
        }
        .padding()
        .background(AppTheme.Colors.background)
    }
}
