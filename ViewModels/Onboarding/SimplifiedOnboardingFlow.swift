//
//  SimplifiedOnboardingFlow.swift
//  Checkpoint
//
//  Extension to OnboardingFlowController for simplified linear flow without JSON
//

import SwiftUI

extension OnboardingFlowController {

    // MARK: - Simplified Flow Mode

    /// Start a simplified linear flow without JSON configuration
    @MainActor
    func startSimplifiedFlow(type: FlowType = .software) {
        isLoading = false
        error = nil
        shouldExitFlow = false

        // Define the screens directly in code
        let screens = createSimplifiedScreens(for: type)

        // Create a minimal flow configuration
        let config = FlowConfiguration(
            id: "\(type.rawValue)_simplified",
            name: "Simplified \(type.rawValue) Flow",
            version: "2.0.0",
            description: "Direct code-based flow without JSON",
            screens: screens,
            metadata: nil,
            minSupportedProgressVersion: nil
        )

        self.flowConfiguration = config

        // Start with the first screen
        if let firstScreen = screens.first {
            currentScreen = firstScreen
            currentScreenIndex = 0
            screenHistory.append(firstScreen.id)

                    } else {
            self.error = OnboardingError.emptyFlow
        }

        updateProgress()
    }

    // MARK: - Screen Definitions

    private func createSimplifiedScreens(for flowType: FlowType) -> [ScreenConfig] {
        switch flowType {
        case .software:
            return createSoftwareOnboardingScreens()
        case .signIn:
            return createSignInScreens()
        case .dataRecovery:
            return createDataRecoveryScreens()
        }
    }

    private func createSoftwareOnboardingScreens() -> [ScreenConfig] {
        return [
            ScreenConfig(
                id: "supabase_auth",
                type: .supabaseAuth,
                title: "Create Your Account",
                isSkippable: false,
                nextScreen: "welcome_to_club_ralley",
                skipToScreen: nil,
                analyticsName: "supabase_auth_viewed"
            ),
            ScreenConfig(
                id: "welcome_to_club_ralley",
                type: .welcomeToCheckpoint,
                title: "Welcome to Club Ralley",
                isSkippable: false,
                nextScreen: nil,
                skipToScreen: nil,
                analyticsName: "welcome_viewed"
            )
        ]
    }

    private func createSignInScreens() -> [ScreenConfig] {
        return [
            ScreenConfig(
                id: "supabase_auth",
                type: .supabaseAuth,
                title: "Sign In",
                isSkippable: false,
                nextScreen: nil,
                skipToScreen: nil,
                analyticsName: "sign_in_completed"
            )
        ]
    }

    private func createDataRecoveryScreens() -> [ScreenConfig] {
        return [
            ScreenConfig(
                id: "data_recovery_intro",
                type: .dataRecoveryIntro,
                title: "Recover Your Data",
                isSkippable: false,
                nextScreen: "supabase_auth",
                skipToScreen: nil,
                analyticsName: "data_recovery_started"
            ),
            ScreenConfig(
                id: "supabase_auth",
                type: .supabaseAuth,
                title: "Sign In to Recover",
                isSkippable: false,
                nextScreen: "welcome_to_checkpoint",
                skipToScreen: nil,
                analyticsName: "data_recovery_auth_completed"
            ),
            ScreenConfig(
                id: "welcome_to_checkpoint",
                type: .welcomeToCheckpoint,
                title: "Welcome Back",
                isSkippable: false,
                nextScreen: nil,
                skipToScreen: nil,
                analyticsName: "data_recovery_completed"
            )
        ]
    }

    // MARK: - Conditional Navigation

    /// Override navigateNext to add conditional logic
    func navigateNextWithConditions() {
        guard let current = currentScreen,
              let flow = flowConfiguration else {
            return
        }

        // Save current screen to history before leaving
        if !screenHistory.contains(current.id) {
            screenHistory.append(current.id)
        }

        // Get next screen from current screen config
        let nextScreenId = current.nextScreen

        // Navigate to the next screen
        if let nextId = nextScreenId,
           let nextScreen = flow.screen(withId: nextId) {
            currentScreen = nextScreen
        } else {
            // No next screen means flow is complete
            completeOnboarding()
        }

        updateProgress()
        saveProgressToStateManager()
    }
}
