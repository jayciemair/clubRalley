//
//  QuitDateCard.swift
//  Checkpoint
//
//  Reusable metallic card component for displaying the user's 77.7-day no-contact date
//  Card gradient evolves through 8 tiers based on current streak
//

import SwiftUI

// MARK: - Tier System

enum StreakTier: String {
    case heartbreak = "Heartbreak"
    case clarity = "Clarity"
    case strength = "Strength"
    case independence = "Independence"
    case growth = "Growth"
    case confidence = "Confidence"
    case peace = "Peace"
    case freedom = "Freedom"

    init(fromStreak streak: Int) {
        switch streak {
        case 0...6:
            self = .heartbreak
        case 7...13:
            self = .clarity
        case 14...22:
            self = .strength
        case 23...35:
            self = .independence
        case 36...52:
            self = .growth
        case 53...67:
            self = .confidence
        case 68...77:
            self = .peace
        default: // 78+
            self = .freedom
        }
    }

    var icon: String {
        switch self {
        case .heartbreak: return "💔"
        case .clarity: return "🌅"
        case .strength: return "💪"
        case .independence: return "🦋"
        case .growth: return "🌱"
        case .confidence: return "✨"
        case .peace: return "🕊️"
        case .freedom: return "👑"
        }
    }

    var gradient: [Color] {
        switch self {
        case .heartbreak:
            // Soft pink/mauve for heartbreak
            return [
                Color(red: 0.80, green: 0.50, blue: 0.60),  // Dark mauve
                Color(red: 0.93, green: 0.71, blue: 0.78),  // Light pink
                Color(red: 0.72, green: 0.45, blue: 0.55),  // Mid mauve
                Color(red: 0.95, green: 0.75, blue: 0.82),  // Highlight
                Color(red: 0.70, green: 0.43, blue: 0.52)   // Shadow
            ]
        case .clarity:
            // Soft dawn silver/lavender
            return [
                Color(red: 0.70, green: 0.70, blue: 0.78),  // Dark lavender silver
                Color(red: 0.92, green: 0.90, blue: 0.95),  // Bright dawn
                Color(red: 0.78, green: 0.76, blue: 0.84),  // Mid silver
                Color(red: 0.96, green: 0.94, blue: 0.98),  // Highlight
                Color(red: 0.75, green: 0.73, blue: 0.82)   // Shadow
            ]
        case .strength:
            // Gold/amber for strength
            return [
                Color(red: 0.85, green: 0.65, blue: 0.13),  // Dark gold
                Color(red: 1.00, green: 0.84, blue: 0.00),  // Bright gold
                Color(red: 0.93, green: 0.75, blue: 0.20),  // Mid gold
                Color(red: 1.00, green: 0.92, blue: 0.40),  // Highlight
                Color(red: 0.80, green: 0.60, blue: 0.10)   // Shadow
            ]
        case .independence:
            // Bright white/chrome for independence
            return [
                Color(red: 0.85, green: 0.85, blue: 0.88),  // Dark platinum
                Color(red: 0.98, green: 0.98, blue: 1.00),  // Bright chrome
                Color(red: 0.90, green: 0.90, blue: 0.94),  // Mid platinum
                Color(red: 1.00, green: 1.00, blue: 1.00),  // Pure white highlight
                Color(red: 0.88, green: 0.88, blue: 0.92)   // Shadow
            ]
        case .growth:
            // Emerald green for growth
            return [
                Color(red: 0.00, green: 0.60, blue: 0.40),  // Dark emerald
                Color(red: 0.20, green: 0.85, blue: 0.60),  // Bright emerald
                Color(red: 0.10, green: 0.72, blue: 0.50),  // Mid emerald
                Color(red: 0.40, green: 0.95, blue: 0.75),  // Highlight
                Color(red: 0.00, green: 0.55, blue: 0.35)   // Shadow
            ]
        case .confidence:
            // Ruby red for confidence
            return [
                Color(red: 0.70, green: 0.10, blue: 0.20),  // Dark ruby
                Color(red: 0.90, green: 0.15, blue: 0.30),  // Bright ruby
                Color(red: 0.80, green: 0.12, blue: 0.25),  // Mid ruby
                Color(red: 0.95, green: 0.30, blue: 0.45),  // Highlight
                Color(red: 0.65, green: 0.08, blue: 0.18)   // Shadow
            ]
        case .peace:
            // Icy blue for peace
            return [
                Color(red: 0.68, green: 0.85, blue: 0.90),  // Dark ice blue
                Color(red: 0.85, green: 0.95, blue: 0.98),  // Bright diamond
                Color(red: 0.75, green: 0.88, blue: 0.94),  // Mid blue
                Color(red: 0.92, green: 0.98, blue: 1.00),  // Highlight
                Color(red: 0.60, green: 0.80, blue: 0.88)   // Shadow
            ]
        case .freedom:
            // Royal purple for freedom
            return [
                Color(red: 0.58, green: 0.40, blue: 0.74),  // Dark purple
                Color(red: 0.75, green: 0.60, blue: 0.90),  // Bright purple
                Color(red: 0.65, green: 0.48, blue: 0.82),  // Mid purple
                Color(red: 0.85, green: 0.70, blue: 0.98),  // Highlight
                Color(red: 0.50, green: 0.35, blue: 0.68)   // Shadow
            ]
        }
    }

    var borderGradient: [Color] {
        switch self {
        case .heartbreak:
            return [
                Color(red: 0.60, green: 0.35, blue: 0.45),
                Color(red: 0.90, green: 0.65, blue: 0.72),
                Color(red: 0.70, green: 0.45, blue: 0.52)
            ]
        case .clarity:
            return [
                Color(red: 0.55, green: 0.55, blue: 0.65),
                Color(red: 0.88, green: 0.86, blue: 0.92),
                Color(red: 0.65, green: 0.63, blue: 0.72)
            ]
        case .strength:
            return [
                Color(red: 0.75, green: 0.55, blue: 0.10),
                Color(red: 1.00, green: 0.85, blue: 0.20),
                Color(red: 0.85, green: 0.65, blue: 0.15)
            ]
        case .independence:
            return [
                Color(red: 0.75, green: 0.75, blue: 0.80),
                Color(red: 0.95, green: 0.95, blue: 1.00),
                Color(red: 0.85, green: 0.85, blue: 0.90)
            ]
        case .growth:
            return [
                Color(red: 0.00, green: 0.50, blue: 0.30),
                Color(red: 0.30, green: 0.90, blue: 0.65),
                Color(red: 0.10, green: 0.70, blue: 0.45)
            ]
        case .confidence:
            return [
                Color(red: 0.60, green: 0.05, blue: 0.15),
                Color(red: 0.95, green: 0.20, blue: 0.35),
                Color(red: 0.75, green: 0.10, blue: 0.22)
            ]
        case .peace:
            return [
                Color(red: 0.50, green: 0.75, blue: 0.85),
                Color(red: 0.80, green: 0.92, blue: 0.98),
                Color(red: 0.60, green: 0.82, blue: 0.92)
            ]
        case .freedom:
            return [
                Color(red: 0.45, green: 0.30, blue: 0.65),
                Color(red: 0.70, green: 0.55, blue: 0.88),
                Color(red: 0.58, green: 0.40, blue: 0.75)
            ]
        }
    }

    var nextTier: StreakTier? {
        switch self {
        case .heartbreak: return .clarity
        case .clarity: return .strength
        case .strength: return .independence
        case .independence: return .growth
        case .growth: return .confidence
        case .confidence: return .peace
        case .peace: return .freedom
        case .freedom: return nil  // Max tier
        }
    }

    var daysToNextTier: Int? {
        switch self {
        case .heartbreak: return 7
        case .clarity: return 14
        case .strength: return 23
        case .independence: return 36
        case .growth: return 53
        case .confidence: return 68
        case .peace: return 78
        case .freedom: return nil  // Max tier
        }
    }

    // Determine which logo to use based on card brightness
    var logoImageName: String {
        switch self {
        case .clarity, .independence, .peace:
            // Light cards - use dark logo
            return "darkCheckpointText"
        case .heartbreak, .strength, .growth, .confidence, .freedom:
            // Dark/colored cards - use light logo
            return "lightCheckpointText"
        }
    }
}

struct QuitDateCard: View {
    let quitDate: Date
    let currentStreak: Int
    let label: String
    let customSubtitle: String?
    let hideDate: Bool

    init(quitDate: Date, currentStreak: Int = 0, label: String = "Your over-him date", subtitle: String? = nil, hideDate: Bool = false) {
        self.quitDate = quitDate
        self.currentStreak = currentStreak
        self.label = label
        self.customSubtitle = subtitle
        self.hideDate = hideDate
    }

    private var tier: StreakTier {
        StreakTier(fromStreak: currentStreak)
    }

    // Auto-generate subtitle based on tier
    private var subtitle: String {
        if let customSubtitle = customSubtitle {
            return customSubtitle
        }

        if let nextTier = tier.nextTier, let targetDays = tier.daysToNextTier {
            let daysRemaining = targetDays - currentStreak
            return "\(tier.rawValue) • \(daysRemaining) days to \(nextTier.rawValue)"
        } else {
            // Max tier reached
            return "\(tier.rawValue) Tier • You're Free!"
        }
    }

    // Format date as "March 15, 2025"
    private var formattedQuitDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: quitDate)
    }

    var body: some View {
        VStack(spacing: 8) {  // Reduced from AppTheme.Spacing.md to 8
            // Label
            Text(label)
                .font(.custom("Satoshi-MediumItalic", size: 16))
                .foregroundColor(.black.opacity(0.6))
                .multilineTextAlignment(.center)
                .italic()

            // Date (optional)
            if !hideDate {
                Text(formattedQuitDate)
                    .font(.custom("Satoshi-Bold", size: 40))
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }

            // Tier subtitle with branding
            VStack(spacing: 2) {
                Text(subtitle)
                    .font(.custom("Satoshi-Regular", size: 14))
                    .foregroundColor(.black.opacity(0.5))
                    .multilineTextAlignment(.center)

                Text("Checkpoint Card")
                    .font(.custom("Satoshi-Regular", size: 10))
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
            }
        }
        .padding(.vertical, 24)  // Reduced from 32 to 24
        .padding(.horizontal, AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 200)
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
                .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 2)  // Inner highlight
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)  // Depth shadow
        )
    }
}

// MARK: - Preview

struct QuitDateCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("All Tier States")
                    .font(.custom("Satoshi-Bold", size: 24))
                    .foregroundColor(.white)
                    .padding(.top)

                // Bronze (0-6 days)
                QuitDateCard(quitDate: Calendar.current.date(byAdding: .day, value: 90, to: Date())!, currentStreak: 3)
                    .padding()

                // Silver (7-13 days)
                QuitDateCard(quitDate: Calendar.current.date(byAdding: .day, value: 83, to: Date())!, currentStreak: 10)
                    .padding()

                // Gold (14-22 days)
                QuitDateCard(quitDate: Calendar.current.date(byAdding: .day, value: 76, to: Date())!, currentStreak: 18)
                    .padding()

                // Emerald (23-35 days)
                QuitDateCard(quitDate: Calendar.current.date(byAdding: .day, value: 67, to: Date())!, currentStreak: 28)
                    .padding()

                // Ruby (36-52 days)
                QuitDateCard(quitDate: Calendar.current.date(byAdding: .day, value: 54, to: Date())!, currentStreak: 44)
                    .padding()

                // Platinum (53-67 days)
                QuitDateCard(quitDate: Calendar.current.date(byAdding: .day, value: 37, to: Date())!, currentStreak: 60)
                    .padding()

                // Diamond (68-89 days)
                QuitDateCard(quitDate: Calendar.current.date(byAdding: .day, value: 22, to: Date())!, currentStreak: 78)
                    .padding()

                // Freedom (90+ days)
                QuitDateCard(quitDate: Date(), currentStreak: 95)
                    .padding()
            }
            .padding(.bottom, 40)
        }
        .background(AppTheme.Colors.primary)
    }
}
