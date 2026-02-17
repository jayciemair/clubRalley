//
//  MilestoneNotificationManager.swift
//  Checkpoint
//
//  Manages milestone notifications for tier unlocks and savings achievements
//  Schedules local notifications that fire automatically even when app is closed
//

import Foundation
import UserNotifications

@MainActor
class MilestoneNotificationManager {

    // MARK: - Singleton

    static let shared = MilestoneNotificationManager()

    // MARK: - Milestone Definitions

    /// Tier unlock thresholds (days)
    private let tierMilestones: [(name: String, days: Int)] = [
        // Skip Bronze (day 0)
        ("Silver", 7),
        ("Gold", 14),
        ("Platinum", 23),
        ("Emerald", 36),
        ("Ruby", 53),
        ("Diamond", 68),
        ("Freedom", 90)
    ]

    /// Savings milestones (dollars)
    private let savingsMilestones: [Int] = [
        100, 250, 500, 1_000, 1_500, 2_000, 2_500, 3_000, 3_500, 4_500, 5_000,
        7_500, 10_000, 20_000, 25_000, 30_000, 35_000, 40_000, 45_000, 50_000,
        60_000, 70_000, 80_000, 90_000, 100_000, 125_000, 150_000, 175_000, 200_000,
        250_000, 300_000, 350_000, 400_000, 450_000, 500_000
    ]

    // MARK: - UserDefaults Keys

    private let sentTiersKey = "milestone_sent_tiers"
    private let sentSavingsKey = "milestone_sent_savings"

    // MARK: - Notification Identifiers

    private let tierNotificationPrefix = "tier_"
    private let savingsNotificationPrefix = "savings_"

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Request notification permissions (call on app launch)
    func requestPermissions() async -> Bool {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    /// Schedule all upcoming milestone notifications
    /// Call this on app launch and after relapse reset
    func scheduleAllMilestones(streakStartedAt: Date, currentSaved: Double, savingsPerSecond: Double) async {
        // Schedule tier milestones
        await scheduleTierMilestones(streakStartedAt: streakStartedAt)

        // Schedule savings milestones
        await scheduleSavingsMilestones(currentSaved: currentSaved, savingsPerSecond: savingsPerSecond)
    }

    /// Cancel all pending milestone notifications and reset tracking
    /// Call this on relapse before rescheduling
    func cancelAllMilestones() async {
        let center = UNUserNotificationCenter.current()

        // Cancel all tier notifications
        let tierIds = tierMilestones.map { "\(tierNotificationPrefix)\($0.name)" }
        center.removePendingNotificationRequests(withIdentifiers: tierIds)

        // Cancel all savings notifications
        let savingsIds = savingsMilestones.map { "\(savingsNotificationPrefix)\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: savingsIds)

        // Reset tracking
        UserDefaults.standard.removeObject(forKey: sentTiersKey)
        UserDefaults.standard.removeObject(forKey: sentSavingsKey)
    }

    // MARK: - Private Methods - Tier Milestones

    private func scheduleTierMilestones(streakStartedAt: Date) async {
        let center = UNUserNotificationCenter.current()
        let sentTiers = getSentTiers()

        for (tierName, days) in tierMilestones {
            // Skip if already sent
            if sentTiers.contains(tierName) {
                continue
            }

            // Calculate unlock date
            guard let unlockDate = Calendar.current.date(byAdding: .day, value: days, to: streakStartedAt) else { continue }

            // Skip if unlock date already passed
            if unlockDate < Date() {
                markTierAsSent(tierName)
                continue
            }

            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "🎉 \(tierName) Card Unlocked!"
            content.body = "You've been gambling-free for \(days) days. Keep up the good work!"
            content.sound = .default

            // Schedule notification
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: unlockDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let identifier = "\(tierNotificationPrefix)\(tierName)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
            } catch {
            }
        }
    }

    // MARK: - Private Methods - Savings Milestones

    private func scheduleSavingsMilestones(currentSaved: Double, savingsPerSecond: Double) async {
        let center = UNUserNotificationCenter.current()
        let sentSavings = getSentSavings()

        // Only schedule next 20 milestones to stay under iOS 64 notification limit
        var scheduledCount = 0
        let maxToSchedule = 20

        for milestone in savingsMilestones {
            // Skip if already sent
            if sentSavings.contains(milestone) {
                continue
            }

            // Skip if already reached
            if Double(milestone) <= currentSaved {
                markSavingsAsSent(milestone)
                continue
            }

            // Stop if we've scheduled enough
            if scheduledCount >= maxToSchedule {
                break
            }

            // Calculate when this milestone will be reached
            let amountNeeded = Double(milestone) - currentSaved
            let secondsUntilMilestone = amountNeeded / savingsPerSecond
            let milestoneDate = Date().addingTimeInterval(secondsUntilMilestone)

            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "💰 $\(formatMilestone(milestone)) Saved!"
            content.body = "You've avoided $\(formatMilestone(milestone)) in gambling losses. Keep it up!"
            content.sound = .default

            // Schedule notification
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: milestoneDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

            let identifier = "\(savingsNotificationPrefix)\(milestone)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
                scheduledCount += 1
            } catch {
            }
        }
    }

    // MARK: - Private Methods - Tracking

    private func getSentTiers() -> Set<String> {
        let array = UserDefaults.standard.array(forKey: sentTiersKey) as? [String] ?? []
        return Set(array)
    }

    private func markTierAsSent(_ tierName: String) {
        var sent = getSentTiers()
        sent.insert(tierName)
        UserDefaults.standard.set(Array(sent), forKey: sentTiersKey)
    }

    private func getSentSavings() -> Set<Int> {
        let array = UserDefaults.standard.array(forKey: sentSavingsKey) as? [Int] ?? []
        return Set(array)
    }

    private func markSavingsAsSent(_ amount: Int) {
        var sent = getSentSavings()
        sent.insert(amount)
        UserDefaults.standard.set(Array(sent), forKey: sentSavingsKey)
    }

    // MARK: - Formatting Helpers

    private func formatMilestone(_ amount: Int) -> String {
        if amount >= 1_000 {
            let thousands = Double(amount) / 1_000.0
            if thousands.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(thousands))k"
            } else {
                return String(format: "%.1fk", thousands)
            }
        } else {
            return "\(amount)"
        }
    }
}
