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
    case software = "software_onboarding"
    case signIn = "sign_in"
    case dataRecovery = "data_recovery"
}

// MARK: - Screen Types
/// All possible screen types in the onboarding flow
/// Club Ralley - Breakup Recovery App
enum ScreenType: String, Codable {
    // MARK: Authentication
    case supabaseAuth = "auth.supabase"

    // MARK: Setup
    case welcomeToCheckpoint = "setup.welcome"

    // MARK: Data Recovery
    case dataRecoveryIntro = "recovery.intro"
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