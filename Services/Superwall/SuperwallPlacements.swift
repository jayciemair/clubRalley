//
//  SuperwallPlacements.swift
//  Checkpoint
//
//  Centralized placement definitions for Superwall SDK
//

import Foundation

/// Centralized placement definitions for Superwall campaigns
/// Following best practices: specific placements for each action
enum SuperwallPlacements {

    // MARK: - Onboarding Placements
    static let onboardingComplete = "onboarding_complete"

    // MARK: - Feature Limit Placements
    static let featureLimit = "feature_limit"

    // MARK: - Session & Lifecycle Placements
    static let sessionStart = "session_start"
    static let sessionEnd = "session_end"
    static let appInstall = "app_install"
    static let appLaunch = "app_launch"

    // MARK: - Transaction Recovery Placements
    static let transactionAbandonDiscount = "transaction_abandon"
    static let paywallDeclineDiscount = "paywall_decline_discount"

    // MARK: - Win-Back Placements (for lapsed subscribers - no trial offered)
    static let winBack = "win_back"

    // MARK: - Settings Placements
    static let settingsUpgrade = "settings_upgrade"
    static let settingsPremiumFeature = "settings_premium_feature"

    // MARK: - Quick Action Placements
    static let quickActionTryFree = "quick_action_try_free"

    // MARK: - Debug Placements
    static let debugPaywallTest = "debug_paywall_test"
    static let debugPaywallTest2 = "debug_paywall_test_2"

    // MARK: - Generic Campaign (to be deprecated)
    @available(*, deprecated, message: "Use specific placements instead of generic campaign_trigger")
    static let campaignTrigger = "campaign_trigger"
}

/// Placement parameters for consistent key usage
enum SuperwallPlacementParams {
    static let source = "source"
    static let screen = "screen"
    static let tier = "tier"
    static let carouselPosition = "carousel_position"
    static let daysToQuit = "days_to_quit"
    static let projectedLoss = "projected_loss"
    static let riskScore = "risk_score"
    static let userAge = "age"
    static let gender = "gender"
    static let userGoal = "user_goal"
    static let originalPlacement = "original_placement"
    static let attemptCount = "attempt_count"
}