//
//  UnitModuleCard.swift
//  Checkpoint
//
//  Unit module card for recovery program
//

import SwiftUI

struct UnitModuleCard: View {
    let week: WeekModule
    let onTap: (() -> Void)?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [week.color, week.color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .leading, spacing: 12) {
                    // Unit number badge
                    Text("Unit \(week.weekNumber)")
                        .font(.custom("Satoshi-Bold", size: 12))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)

                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 6) {
                        Text(week.title)
                            .font(.custom("Satoshi-Bold", size: 22))
                            .foregroundColor(.white)

                        Text(week.subtitle)
                            .font(.custom("Satoshi-Regular", size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Spacer()

                    // Progress indicator
                    if !week.isLocked {
                        HStack(spacing: 8) {
                            Text("\(week.completedCount) of \(week.totalCount) modules")
                                .font(.custom("Satoshi-Medium", size: 13))
                                .foregroundColor(.white.opacity(0.9))

                            Spacer()

                            if week.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(Int((Double(week.completedCount) / Double(week.totalCount)) * 100))%")
                                    .font(.custom("Satoshi-Bold", size: 13))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .frame(height: 160)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            .opacity(week.isLocked ? 0.6 : 1.0)

            // Lock indicator
            if week.isLocked {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 32, height: 32)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(week.color)
                }
                .offset(x: -12, y: 12)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        UnitModuleCard(
            week: WeekModule(
                id: UUID(),
                weekNumber: 1,
                title: "Crisis & Understanding",
                subtitle: "Immediate tools and neuroscience",
                days: [],
                color: Color(red: 0.85, green: 0.68, blue: 0.32)
            ),
            onTap: nil
        )

        UnitModuleCard(
            week: WeekModule(
                id: UUID(),
                weekNumber: 2,
                title: "Rebuilding Foundations",
                subtitle: "Lifestyle and practical recovery",
                days: [],
                color: Color(red: 0.93, green: 0.35, blue: 0.35)
            ),
            onTap: nil
        )

        UnitModuleCard(
            week: WeekModule(
                id: UUID(),
                weekNumber: 3,
                title: "Identity & Boundaries",
                subtitle: "Removing toxic influences",
                days: [],
                color: Color(red: 0.67, green: 0.28, blue: 0.74)
            ),
            onTap: nil
        )
    }
    .padding()
    .background(Color.white)
}
