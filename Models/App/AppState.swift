//
//  AppState.swift
//  Club Ralley
//
//  App state machine enums for Club Ralley social platform
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
    case ready(selectedTab: MainTab, showSuccessHUD: Bool)

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
        if case .ready(_, let showSuccessHUD) = self {
            return showSuccessHUD
        }
        return false
    }
    
    /// Helper to get selected tab
    var selectedTab: MainTab {
        if case .ready(let selectedTab, _) = self {
            return selectedTab
        }
        return .home
    }
}

/// Types of onboarding flows for Club Ralley
enum OnboardingFlowType {
    case firstTime          // First-time user onboarding
    case profileSetup       // Profile and preferences setup
    case athleteVerification // Athlete verification process
}

/// Main tab navigation for Club Ralley (based on Figma design)
enum MainTab: String, CaseIterable {
    case home = "home"
    case leagueFinder = "league_finder"
    case post = "post"
    case teams = "teams"
    case profile = "profile"
    
    var displayName: String {
        switch self {
        case .home: return "Home"
        case .leagueFinder: return "League Finder"
        case .post: return "Post"
        case .teams: return "Teams"
        case .profile: return "Profile"
        }
    }
    
    var iconName: String {
        switch self {
        case .home: return "house"
        case .leagueFinder: return "magnifyingglass"
        case .post: return "camera"
        case .teams: return "person.2"
        case .profile: return "person"
        }
    }
    
    var selectedIconName: String {
        switch self {
        case .home: return "house.fill"
        case .leagueFinder: return "magnifyingglass"
        case .post: return "camera.fill"
        case .teams: return "person.2.fill"
        case .profile: return "person.fill"
        }
    }
}

