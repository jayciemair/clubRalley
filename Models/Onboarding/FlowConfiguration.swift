//
//  FlowConfiguration.swift
//  Dial
//
//  Created on 2025-07-21
//  Defines the data models for the JSON-driven onboarding flow system
//

import Foundation

// MARK: - Flow Types
/// Represents different types of onboarding flows available in the app
enum FlowType: String, CaseIterable {
    case software = "software_onboarding"  // Main onboarding flow
    case signIn = "sign_in"               // Sign in flow for returning users
    case dataRecovery = "data_recovery"   // Recovery flow for orphaned accounts
    case soberOnlyDeletionPrevention = "sober_only_deletion_prevention"  // Deletion prevention flow
    case nuclearDeletionPrevention = "nuclear_deletion_prevention"        // Nuclear deletion flow
}

// MARK: - Screen Types
/// All possible screen types in the onboarding flow
/// Get Over Him - Breakup Recovery App
enum ScreenType: String, Codable {
    // MARK: Authentication
    case supabaseAuth = "auth.supabase"

    // MARK: Intro (Hook Screens)
    case welcomeSplash = "intro.welcome_splash"
    case mochiIntro = "intro.mochi_intro"
    case nameInput = "intro.name_input"
    case notAboutHim = "intro.not_about_him"
    case mochiBridge = "intro.mochi_bridge"
    case breakupTiming = "intro.breakup_timing"
    case whoEndedIt = "intro.who_ended_it"
    case whatsHurting = "intro.whats_hurting"
    case howCoping = "intro.how_coping"
    case mainGoals = "intro.main_goals"
    case calculatingResults = "intro.calculating_results"
    case attachmentReveal = "intro.attachment_reveal"
    case youCared = "intro.you_cared"
    case healingNotLinear = "intro.healing_not_linear"
    case mochiJourney = "intro.mochi_journey"
    case urgeToText = "intro.urge_to_text"
    case textHimPreview = "intro.text_him_preview"
    case textHimDemo = "intro.text_him_demo"
    case mochiRealTalk = "intro.mochi_real_talk"
    case loveIsADrug = "intro.love_is_a_drug"
    case grieveAsDeep = "intro.grieve_as_deep"
    case theCosts = "intro.the_costs"
    case commitToChange = "intro.commit_to_change"
    case healingTimeline = "intro.healing_timeline"
    case mochiHelp = "intro.mochi_help"
    case checkinFrequency = "intro.checkin_frequency"
    case mochiPromise = "intro.mochi_promise"
    case socialProof = "intro.social_proof"

    // MARK: Setup
    case welcomeToCheckpoint = "setup.welcome"
    case lastContactDate = "setup.last_contact_date"

    // MARK: Data Recovery
    case dataRecoveryIntro = "recovery.intro"

    // MARK: Deletion Prevention (keep for app functionality)
    case breathingIntro = "deletion.breathing_intro"
    case breathingExercise = "deletion.breathing_exercise"
}

// MARK: - Screen Configuration
/// Configuration for an individual screen in the onboarding flow
struct ScreenConfig: Codable, Identifiable {
    /// Unique identifier for this screen
    let id: String
    
    /// The type of screen to display
    let type: ScreenType
    
    /// Optional title to display on the screen
    let title: String?
    
    /// Whether the user can skip this screen
    let isSkippable: Bool
    
    /// ID of the next screen in the flow
    let nextScreen: String?
    
    /// ID of the screen to skip to (if skippable)
    let skipToScreen: String?
    
    /// Analytics event name for tracking
    let analyticsName: String?

    // MARK: CodingKeys for JSON mapping
    private enum CodingKeys: String, CodingKey {
        case id, type, title
        case isSkippable = "is_skippable"
        case nextScreen = "next_screen"
        case skipToScreen = "skip_to_screen"
        case analyticsName = "analytics_name"
    }
}

// MARK: - Flow Configuration
/// Complete configuration for an onboarding flow
struct FlowConfiguration: Codable {
    /// Unique identifier for this flow configuration
    let id: String
    
    /// Human-readable name for the flow
    let name: String
    
    /// Version of this flow configuration
    let version: String
    
    /// Optional description of the flow's purpose
    let description: String?
    
    /// Ordered list of screens in this flow
    let screens: [ScreenConfig]
    
    /// Additional metadata about the flow
    let metadata: FlowMetadata?
    
    /// Minimum supported progress version for migration
    let minSupportedProgressVersion: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, version, description, screens, metadata
        case minSupportedProgressVersion
    }
}

// MARK: - Flow Metadata
/// Additional information about a flow configuration
struct FlowMetadata: Codable {
    /// Estimated time to complete this flow in minutes
    let estimatedMinutes: Int?
    
    /// Target audience for this flow variant
    let targetAudience: String?
    
    /// A/B test variant identifier
    let abTestVariant: String?
    
    /// Minimum app version required for this flow
    let minAppVersion: String?
    
    /// Feature flags required for this flow
    let requiredFeatures: [String]?
    
    /// Type of onboarding
    let onboardingType: String?
    
    // MARK: CodingKeys for JSON mapping
    private enum CodingKeys: String, CodingKey {
        case estimatedMinutes = "estimated_minutes"
        case targetAudience = "target_audience"
        case abTestVariant = "ab_test_variant"
        case minAppVersion = "min_app_version"
        case requiredFeatures = "required_features"
        case onboardingType = "onboarding_type"
    }
}

// MARK: - Flow Configuration Extensions
extension FlowConfiguration {
    /// Find a screen configuration by ID
    func screen(withId id: String) -> ScreenConfig? {
        screens.first { $0.id == id }
    }
    
    /// Get the index of a screen by ID
    func index(of screenId: String) -> Int? {
        screens.firstIndex { $0.id == screenId }
    }
    
    /// Calculate progress for a given screen ID
    func progress(for screenId: String) -> Double {
        guard let index = index(of: screenId) else { return 0.0 }
        return Double(index + 1) / Double(screens.count)
    }
}