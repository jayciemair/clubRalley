//
//  StatsGridCard.swift
//  Checkpoint
//
//  Reusable stat card component for analytics metrics
//

import SwiftUI

struct StatsGridCard: View {

    // MARK: - Properties

    let icon: String
    let value: String
    let title: String
    let iconColor: Color

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(iconColor)

            Text(value)
                .font(.custom("Satoshi-Bold", size: 36))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text(title)
                .font(.custom("Satoshi-Regular", size: 13))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
        .background(AppTheme.Colors.darkSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
    }
}

// MARK: - Stats Grid Layout

struct StatsGridLayout: View {

    // MARK: - Properties

    let stats: [StatItem]

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // First row
            HStack(spacing: AppTheme.Spacing.md) {
                if stats.count > 0 {
                    StatsGridCard(
                        icon: stats[0].icon,
                        value: stats[0].value,
                        title: stats[0].title,
                        iconColor: stats[0].iconColor
                    )
                }

                if stats.count > 1 {
                    StatsGridCard(
                        icon: stats[1].icon,
                        value: stats[1].value,
                        title: stats[1].title,
                        iconColor: stats[1].iconColor
                    )
                }
            }

            // Second row
            if stats.count > 2 {
                HStack(spacing: AppTheme.Spacing.md) {
                    if stats.count > 2 {
                        StatsGridCard(
                            icon: stats[2].icon,
                            value: stats[2].value,
                            title: stats[2].title,
                            iconColor: stats[2].iconColor
                        )
                    }

                    if stats.count > 3 {
                        StatsGridCard(
                            icon: stats[3].icon,
                            value: stats[3].value,
                            title: stats[3].title,
                            iconColor: stats[3].iconColor
                        )
                    }
                }
            }

            // Third row for 5th card
            if stats.count > 4 {
                StatsGridCard(
                    icon: stats[4].icon,
                    value: stats[4].value,
                    title: stats[4].title,
                    iconColor: stats[4].iconColor
                )
            }
        }
    }
}

// MARK: - Preview

struct StatsGridCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            StatsGridCard(
                icon: "calendar",
                value: "42",
                title: "Days Since Joining",
                iconColor: .green
            )

            StatsGridLayout(stats: [
                .init(icon: "calendar", value: "42", title: "Days Since Joining", iconColor: .green),
                .init(icon: "xmark.circle.fill", value: "126", title: "Texts Avoided", iconColor: .green),
                .init(icon: "shield.checkered", value: "18", title: "Contact-Free Days", iconColor: .green),
                .init(icon: "flame.fill", value: "21", title: "Longest Streak", iconColor: .orange)
            ])
        }
        .padding()
        .background(AppTheme.Colors.background)
    }
}