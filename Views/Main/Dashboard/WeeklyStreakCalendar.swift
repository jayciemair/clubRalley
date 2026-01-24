//
//  WeeklyStreakCalendar.swift
//  Checkpoint
//
//  Visual weekly calendar showing daily streak status
//

import SwiftUI

struct WeeklyStreakCalendar: View {
    let relapseTimestamps: [Date]
    let isReloading: Bool
    let streakStartDate: Date?
    let hasLoadedOnce: Bool

    private let dayLetters = ["S", "M", "T", "W", "T", "F", "S"]

    init(relapseTimestamps: [Date], isReloading: Bool = false, streakStartDate: Date? = nil, hasLoadedOnce: Bool = false) {
        self.relapseTimestamps = relapseTimestamps
        self.isReloading = isReloading
        self.streakStartDate = streakStartDate
        self.hasLoadedOnce = hasLoadedOnce
    }

    var body: some View {
        VStack(spacing: 12) {
            // Day letters and status circles
            HStack(spacing: 8) {
                ForEach(0..<7) { index in
                    VStack(spacing: 8) {
                        // Day letter
                        Text(dayLetters[index])
                            .font(.custom("Satoshi-Bold", size: 14))
                            .foregroundColor(Color(hex: "#4A2040"))

                        // Status circle
                        if !hasLoadedOnce || isReloading {
                            // Show loading spinner until data loads or during reload
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 36, height: 36)

                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 36, height: 36)

                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                            }
                        } else {
                            let dayStatus = getDayStatus(for: index)
                            ZStack {
                                // Filled circle
                                Circle()
                                    .fill(dayStatus.color)
                                    .frame(width: 36, height: 36)

                                // White outline
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 36, height: 36)

                                // White icon
                                if let icon = dayStatus.icon {
                                    Image(systemName: icon)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.6))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Helper Methods

    private func getDayStatus(for dayIndex: Int) -> DayStatus {
        let calendar = Calendar.current
        let today = Date()

        // Get the date for this day of the current week (Sunday = 0)
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else {
            return DayStatus(icon: nil, color: .gray.opacity(0.3))
        }

        guard let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) else {
            return DayStatus(icon: nil, color: .gray.opacity(0.3))
        }

        let dayStart = calendar.startOfDay(for: dayDate)
        let todayStart = calendar.startOfDay(for: today)

        // Check if this day is in the future
        if dayStart > todayStart {
            return DayStatus(icon: nil, color: .gray.opacity(0.3))
        }

        // Check if this day is before user's streak started (before they joined)
        if let streakStart = streakStartDate {
            let streakStartDay = calendar.startOfDay(for: streakStart)
            if dayStart < streakStartDay {
                return DayStatus(icon: "minus", color: .gray.opacity(0.5))
            }
        }

        // Check if there was a relapse on this day
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        let hadRelapse = relapseTimestamps.contains { relapseDate in
            relapseDate >= dayStart && relapseDate < dayEnd
        }

        // Simple: X if relapsed, checkmark otherwise
        if hadRelapse {
            return DayStatus(icon: "xmark", color: AppTheme.Colors.warning)
        } else {
            return DayStatus(icon: "checkmark", color: AppTheme.Colors.success)
        }
    }
}

// MARK: - Day Status Model

struct DayStatus {
    let icon: String?
    let color: Color
}

struct WeeklyStreakCalendar_Previews: PreviewProvider {
    static var previews: some View {
        WeeklyStreakCalendar(
            relapseTimestamps: [Date().addingTimeInterval(-86400)] // 1 relapse yesterday
        )
        .padding()
        .background(AppTheme.Colors.background)
    }
}
