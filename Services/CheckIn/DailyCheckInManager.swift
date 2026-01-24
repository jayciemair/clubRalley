//
//  DailyCheckInManager.swift
//  Checkpoint
//
//  Manages daily check-in state (UserDefaults only for now - DB integration later)
//

import Foundation
import SwiftUI
import UserNotifications

/// Manages daily check-in tracking
@MainActor
final class DailyCheckInManager: ObservableObject {

    // MARK: - Singleton

    static let shared = DailyCheckInManager()

    // MARK: - Published Properties

    @Published var hasCheckedInToday: Bool = false
    @Published var checkInStreak: Int = 0

    // MARK: - Private Properties

    private let lastCheckInDateKey = "daily_checkin_last_date"
    private let checkInStreakKey = "daily_checkin_streak"
    private let checkInNotificationIdentifier = "daily_checkin_reminder"
    private let frequencyKey = "mochi_checkin_frequency"
    private let wakingStartHour = 9  // 9 AM
    private let wakingEndHour = 21   // 9 PM

    // MARK: - Initialization

    private init() {
        loadCheckInState()
    }

    // MARK: - Public Methods

    /// Check if user needs to see the daily check-in prompt
    func needsCheckIn() -> Bool {
        return !hasCheckedInToday
    }

    /// Record a check-in (regardless of outcome)
    func recordCheckIn(stayedClean: Bool) {
        let today = Calendar.current.startOfDay(for: Date())

        // Log to event sourcing
        Task {
            if let userId = getCurrentUserId() {
                await EventLoggingService.shared.logDailyCheckIn(userId: userId, stayedClean: stayedClean)
            }
        }

        // Always mark check-in as done for today (so it doesn't keep appearing)
        UserDefaults.standard.set(today.timeIntervalSince1970, forKey: lastCheckInDateKey)
        hasCheckedInToday = true
        cancelTodayCheckInReminder()

        if stayedClean {
            // Update streak only if they stayed clean
            if let lastDate = getLastCheckInDate() {
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
                if Calendar.current.isDate(lastDate, inSameDayAs: yesterday) {
                    // Consecutive day - increment streak
                    checkInStreak += 1
                } else if !Calendar.current.isDate(lastDate, inSameDayAs: today) {
                    // Missed days - reset streak
                    checkInStreak = 1
                }
            } else {
                // First ever check-in
                checkInStreak = 1
            }
            UserDefaults.standard.set(checkInStreak, forKey: checkInStreakKey)
        }
        // If stayedClean is false, streak will be reset by the relapse flow
    }

    /// Reset check-in state (for testing or new day)
    func resetForNewDay() {
        loadCheckInState()
    }

    // MARK: - Notification Scheduling

    /// Get the user's check-in frequency (1-10 times per day, default 3)
    private func getCheckInFrequency() -> Int {
        let frequency = UserDefaults.standard.integer(forKey: frequencyKey)
        return frequency > 0 ? min(frequency, 10) : 3 // Default to 3 if not set
    }

    /// Calculate reminder hours based on frequency
    /// Spreads notifications evenly between wakingStartHour and wakingEndHour
    private func calculateReminderHours(frequency: Int) -> [Int] {
        guard frequency > 0 else { return [] }

        let totalWakingHours = wakingEndHour - wakingStartHour // 12 hours (9 AM - 9 PM)

        if frequency == 1 {
            // Single reminder at midday-ish (2 PM)
            return [14]
        }

        // Spread evenly across waking hours
        var hours: [Int] = []
        let interval = Double(totalWakingHours) / Double(frequency - 1)

        for i in 0..<frequency {
            let hour = wakingStartHour + Int(Double(i) * interval)
            hours.append(min(hour, wakingEndHour))
        }

        return hours
    }

    /// Schedule check-in reminders based on user's frequency preference
    /// Called on app launch to refresh the rolling 7-day window
    func scheduleCheckInReminders() {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let frequency = getCheckInFrequency()
        let reminderHours = calculateReminderHours(frequency: frequency)

        print("[DailyCheckIn] Scheduling with frequency: \(frequency), hours: \(reminderHours)")

        // Get all pending check-in notifications and cancel them
        center.getPendingNotificationRequests { requests in
            let checkInIdentifiers = requests
                .filter { $0.identifier.hasPrefix(self.checkInNotificationIdentifier) }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: checkInIdentifiers)

            // Schedule for the next 7 days on main thread
            DispatchQueue.main.async {
                let currentHour = calendar.component(.hour, from: Date())

                for dayOffset in 0..<7 {
                    guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }

                    // Skip today if already checked in
                    if dayOffset == 0 && self.hasCheckedInToday {
                        continue
                    }

                    let dateString = dateFormatter.string(from: targetDate)

                    // Schedule notification for each reminder hour
                    for (index, hour) in reminderHours.enumerated() {
                        // Skip if it's today and we're past this hour
                        if dayOffset == 0 && currentHour >= hour {
                            continue
                        }

                        // Create notification content
                        let content = UNMutableNotificationContent()
                        content.title = "check in with mochi"
                        content.body = self.getRandomReminderBody()
                        content.sound = .default

                        // Set trigger for this hour on target date
                        var dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
                        dateComponents.hour = hour
                        dateComponents.minute = 0

                        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

                        // Unique identifier for each notification
                        let identifier = "\(self.checkInNotificationIdentifier)_\(dateString)_\(index)"

                        let request = UNNotificationRequest(
                            identifier: identifier,
                            content: content,
                            trigger: trigger
                        )

                        center.add(request) { error in
                            if let error = error {
                                print("[DailyCheckIn] Failed to schedule reminder: \(error)")
                            }
                        }
                    }
                }

                print("[DailyCheckIn] Scheduled \(frequency) check-ins/day for next 7 days")
            }
        }
    }

    /// Random encouraging reminder messages
    private func getRandomReminderBody() -> String {
        let messages = [
            "how are you doing? let's check in",
            "thinking of you - did you stay strong today?",
            "quick check: did you contact him?",
            "hey, just checking in on you",
            "you got this - time for your check-in"
        ]
        return messages.randomElement() ?? messages[0]
    }

    /// Cancel all of today's check-in reminders (called after successful check-in)
    func cancelTodayCheckInReminder() {
        let center = UNUserNotificationCenter.current()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())

        // Cancel all notifications for today (we have multiple per day now)
        center.getPendingNotificationRequests { requests in
            let todayIdentifiers = requests
                .filter { $0.identifier.hasPrefix("\(self.checkInNotificationIdentifier)_\(todayString)") }
                .map { $0.identifier }

            if !todayIdentifiers.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: todayIdentifiers)
                print("[DailyCheckIn] Cancelled \(todayIdentifiers.count) reminder(s) for today")
            }
        }
    }

    // MARK: - Private Methods

    private func loadCheckInState() {
        let today = Calendar.current.startOfDay(for: Date())

        // Load streak
        checkInStreak = UserDefaults.standard.integer(forKey: checkInStreakKey)

        // Check if already checked in today
        if let lastDate = getLastCheckInDate() {
            hasCheckedInToday = Calendar.current.isDate(lastDate, inSameDayAs: today)

            // Also check if streak should be reset due to missed days
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            if !Calendar.current.isDate(lastDate, inSameDayAs: today) &&
               !Calendar.current.isDate(lastDate, inSameDayAs: yesterday) {
                // Missed more than one day - streak will reset on next check-in
            }
        } else {
            hasCheckedInToday = false
        }
    }

    private func getLastCheckInDate() -> Date? {
        let timestamp = UserDefaults.standard.double(forKey: lastCheckInDateKey)
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    private func getCurrentUserId() -> UUID? {
        if case .authenticated(let session) = AuthenticationService.shared.authState,
           let uuid = UUID(uuidString: session.userId) {
            return uuid
        }
        return nil
    }

    // MARK: - Debug Methods

    #if DEBUG
    /// Reset check-in state to allow showing again
    func debugResetCheckIn() {
        UserDefaults.standard.removeObject(forKey: lastCheckInDateKey)
        hasCheckedInToday = false
    }

    /// Reset the check-in streak to 0
    func debugResetStreak() {
        UserDefaults.standard.removeObject(forKey: checkInStreakKey)
        checkInStreak = 0
    }

    /// Trigger the daily check-in to show (posts notification)
    func debugTriggerCheckIn() {
        debugResetCheckIn()
        NotificationCenter.default.post(name: .showDailyCheckIn, object: nil)
    }
    #endif
}

// MARK: - Notification Names

extension Notification.Name {
    static let showDailyCheckIn = Notification.Name("showDailyCheckIn")
}
