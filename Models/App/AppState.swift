//
//  AppState.swift
//  Checkpoint
//
//  App state machine enums
//  Extracted from ContentView during MVVM refactor
//

import Foundation

// MARK: - App State Machine

/// Unified state machine for app navigation and UI
/// Prevents race conditions and impossible states by having single source of truth
enum AppState: Equatable {
    // Initial loading - checking authentication and fetching user data
    case initializing

    // Onboarding required (user needs to complete flow)
    case onboardingRequired(flowType: OnboardingFlowType)

    // Ready - main app loaded and functional
    case ready(showSuccessHUD: Bool)

    /// Helper to check if we should show loading screen
    var showsLoadingScreen: Bool {
        if case .initializing = self {
            return true
        }
        return false
    }

    /// Helper to check if we should show onboarding modal
    var showsOnboarding: Bool {
        if case .onboardingRequired = self {
            return true
        }
        return false
    }

    /// Helper to get onboarding flow type
    var onboardingFlowType: OnboardingFlowType? {
        if case .onboardingRequired(let flowType) = self {
            return flowType
        }
        return nil
    }

    /// Helper to check if we should show success HUD
    var showsSuccessHUD: Bool {
        if case .ready(let showSuccessHUD) = self {
            return showSuccessHUD
        }
        return false
    }

}

/// Types of onboarding flows
enum OnboardingFlowType {
    case software           // Normal first-time onboarding
    case dataRecovery      // Recovering data for existing user
}

