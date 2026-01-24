//
//  TierProgressManager.swift
//  Checkpoint
//
//  Manages tier progression logic and HUD display independently from dashboard
//

import Foundation
import SwiftUI

/// Singleton service that manages tier progression and unlock celebrations
@MainActor
final class TierProgressManager: ObservableObject {

    // MARK: - Singleton

    static let shared = TierProgressManager()

    // MARK: - Published Properties (for HUD display)

    @Published var showTierUnlockedHUD = false
    @Published var unlockedTierName = ""
    @Published var unlockedTierDays = 0
    @Published var currentQuitDate: Date?

    // MARK: - Private Properties

    private let lastShownTierKey = "last_shown_tier_days"
    private let hasCheckedTierThisSessionKey = "has_checked_tier_this_session"

    // Current user state (cached)
    private var currentStreak: Int = 0
    private var lastCheckedDate: Date?

    // Tier thresholds (days to unlock each tier)
    private let tierThresholds: [(name: String, days: Int)] = [
        ("Heartbreak", 0),   // Your Healing Begins!
        ("Clarity", 7),
        ("Strength", 14),
        ("Independence", 23),
        ("Growth", 36),
        ("Confidence", 53),
        ("Peace", 68),
        ("Freedom", 78)
    ]

    // MARK: - Initialization

    private init() {
        // Reset session flag on init (app launch)
        UserDefaults.standard.set(false, forKey: hasCheckedTierThisSessionKey)
    }

    // MARK: - Public Methods

    /// Update the current streak and quit date (called by DashboardDataService)
    func updateStreakData(streak: Int, quitDate: Date?) {
        self.currentStreak = streak
        self.currentQuitDate = quitDate
        self.lastCheckedDate = Date()
    }

    /// Check if user should see a tier unlock celebration
    /// - Parameter force: Force check even if already checked this session
    func checkForTierUnlock(force: Bool = false) {
        // Skip if already checked this session (unless forced)
        let hasCheckedThisSession = UserDefaults.standard.bool(forKey: hasCheckedTierThisSessionKey)

        if hasCheckedThisSession && !force {
            return
        }

        // Use -1 as default to indicate "no tier shown yet"
        let stored = UserDefaults.standard.object(forKey: lastShownTierKey) as? Int
        let lastShownTierDays = stored ?? -1

        // Find which tier the user should be at
        var unlockedTier: (name: String, days: Int)?
        for tier in tierThresholds {
            if currentStreak >= tier.days && lastShownTierDays < tier.days {
                // User crossed this threshold since last shown
                unlockedTier = tier
                break
            }
        }

        guard let tier = unlockedTier else {
            // Mark as checked for this session
            UserDefaults.standard.set(true, forKey: hasCheckedTierThisSessionKey)
            return
        }

        // Update tracking
        UserDefaults.standard.set(tier.days, forKey: lastShownTierKey)
        UserDefaults.standard.set(true, forKey: hasCheckedTierThisSessionKey)

        // Log tier_unlocked event for event sourcing
        if let userId = AuthenticationService.shared.currentSession?.userId,
           let userUUID = UUID(uuidString: userId) {
            Task {
                await EventLoggingService.shared.logTierUnlocked(
                    userId: userUUID,
                    tier: tier.name.lowercased(),
                    days: tier.days
                )
            }
        }

        // Trigger HUD
        unlockedTierName = tier.name
        unlockedTierDays = tier.days
        showTierUnlockedHUD = true
    }

    /// Reset tier tracking (call on relapse)
    func resetTierTracking() {
        UserDefaults.standard.set(-1, forKey: lastShownTierKey)
        UserDefaults.standard.set(false, forKey: hasCheckedTierThisSessionKey)
        currentStreak = 0
    }

    /// Reset session tracking (call when app becomes active)
    func resetSessionTracking() {
        UserDefaults.standard.set(false, forKey: hasCheckedTierThisSessionKey)
    }

    /// Get current tier info (for display purposes)
    func getCurrentTierInfo() -> (tier: StreakTier, nextTier: StreakTier?, daysUntilNext: Int) {
        let currentTier = StreakTier(fromStreak: currentStreak)
        let nextTier = currentTier.nextTier

        var daysUntilNext = 0
        if let nextTierThreshold = tierThresholds.first(where: { $0.name.lowercased() == nextTier?.rawValue })?.days {
            daysUntilNext = max(0, nextTierThreshold - currentStreak)
        }

        return (currentTier, nextTier, daysUntilNext)
    }

    // MARK: - Debug Methods

    #if DEBUG
    /// DEBUG: Force show a specific tier HUD for testing
    func debugShowTierHUD(tierName: String = "Bronze", days: Int = 0) {
        UserDefaults.standard.set(-1, forKey: lastShownTierKey)

        unlockedTierName = tierName
        unlockedTierDays = days
        showTierUnlockedHUD = true
    }

    /// DEBUG: Reset and force check
    func debugResetAndCheck(withStreak streak: Int = 0) {
        UserDefaults.standard.set(-1, forKey: lastShownTierKey)
        UserDefaults.standard.set(false, forKey: hasCheckedTierThisSessionKey)

        currentStreak = streak
        checkForTierUnlock(force: true)
    }
    #endif
}