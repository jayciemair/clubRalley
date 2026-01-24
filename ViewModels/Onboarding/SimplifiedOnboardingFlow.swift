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
        case .soberOnlyDeletionPrevention, .nuclearDeletionPrevention:
            // TODO: Implement deletion prevention flows
            return createSoftwareOnboardingScreens()
        }
    }

    private func createSoftwareOnboardingScreens() -> [ScreenConfig] {
        // Define screens directly in code - much clearer than JSON!
        // Reordered for better narrative flow: Hook → Educate → Decide → Share → Assess → Setup
        return [
            // PHASE 0: Welcome & Intro
            ScreenConfig(
                id: "welcome_splash",
                type: .welcomeSplash,
                title: "Welcome to Get Over Him",
                isSkippable: false,
                nextScreen: "mochi_intro",
                skipToScreen: nil,
                analyticsName: "welcome_splash_viewed"
            ),
            ScreenConfig(
                id: "mochi_intro",
                type: .mochiIntro,
                title: "Meet Mochi",
                isSkippable: false,
                nextScreen: "not_about_him",
                skipToScreen: nil,
                analyticsName: "mochi_intro_viewed"
            ),
            ScreenConfig(
                id: "not_about_him",
                type: .notAboutHim,
                title: "Not about him",
                isSkippable: false,
                nextScreen: "mochi_bridge",
                skipToScreen: nil,
                analyticsName: "not_about_him_viewed"
            ),
            ScreenConfig(
                id: "mochi_bridge",
                type: .mochiBridge,
                title: "Let's get to know you",
                isSkippable: false,
                nextScreen: "breakup_timing",
                skipToScreen: nil,
                analyticsName: "mochi_bridge_viewed"
            ),
            ScreenConfig(
                id: "breakup_timing",
                type: .breakupTiming,
                title: "How long since you last talked?",
                isSkippable: false,
                nextScreen: "who_ended_it",
                skipToScreen: nil,
                analyticsName: "breakup_timing_viewed"
            ),
            ScreenConfig(
                id: "who_ended_it",
                type: .whoEndedIt,
                title: "Who ended things?",
                isSkippable: false,
                nextScreen: "whats_hurting",
                skipToScreen: nil,
                analyticsName: "who_ended_it_viewed"
            ),
            ScreenConfig(
                id: "whats_hurting",
                type: .whatsHurting,
                title: "What's hurting the most?",
                isSkippable: false,
                nextScreen: "how_coping",
                skipToScreen: nil,
                analyticsName: "whats_hurting_viewed"
            ),
            ScreenConfig(
                id: "how_coping",
                type: .howCoping,
                title: "How are you coping?",
                isSkippable: false,
                nextScreen: "main_goals",
                skipToScreen: nil,
                analyticsName: "how_coping_viewed"
            ),
            ScreenConfig(
                id: "main_goals",
                type: .mainGoals,
                title: "What are your main goals?",
                isSkippable: false,
                nextScreen: "calculating_results",
                skipToScreen: nil,
                analyticsName: "main_goals_viewed"
            ),
            ScreenConfig(
                id: "calculating_results",
                type: .calculatingResults,
                title: "Analyzing your responses",
                isSkippable: false,
                nextScreen: "attachment_reveal",
                skipToScreen: nil,
                analyticsName: "calculating_results_viewed"
            ),
            ScreenConfig(
                id: "attachment_reveal",
                type: .attachmentReveal,
                title: "Your emotional attachment",
                isSkippable: false,
                nextScreen: "you_cared",
                skipToScreen: nil,
                analyticsName: "attachment_reveal_viewed"
            ),
            ScreenConfig(
                id: "you_cared",
                type: .youCared,
                title: "It's clear you cared",
                isSkippable: false,
                nextScreen: "healing_not_linear",
                skipToScreen: nil,
                analyticsName: "you_cared_viewed"
            ),
            ScreenConfig(
                id: "healing_not_linear",
                type: .healingNotLinear,
                title: "Healing isn't linear",
                isSkippable: false,
                nextScreen: "mochi_journey",
                skipToScreen: nil,
                analyticsName: "healing_not_linear_viewed"
            ),
            ScreenConfig(
                id: "mochi_journey",
                type: .mochiJourney,
                title: "The breakup journey",
                isSkippable: false,
                nextScreen: "urge_to_text",
                skipToScreen: nil,
                analyticsName: "mochi_journey_viewed"
            ),
            ScreenConfig(
                id: "urge_to_text",
                type: .urgeToText,
                title: "The urge to text",
                isSkippable: false,
                nextScreen: "text_him_demo",
                skipToScreen: nil,
                analyticsName: "urge_to_text_viewed"
            ),
            ScreenConfig(
                id: "text_him_demo",
                type: .textHimDemo,
                title: "Text him demo",
                isSkippable: false,
                nextScreen: "mochi_real_talk",
                skipToScreen: nil,
                analyticsName: "text_him_demo_viewed"
            ),
            ScreenConfig(
                id: "mochi_real_talk",
                type: .mochiRealTalk,
                title: "Heartbreak sucks",
                isSkippable: false,
                nextScreen: "love_is_a_drug",
                skipToScreen: nil,
                analyticsName: "mochi_real_talk_viewed"
            ),
            ScreenConfig(
                id: "love_is_a_drug",
                type: .loveIsADrug,
                title: "Love is like a drug",
                isSkippable: false,
                nextScreen: "grieve_as_deep",
                skipToScreen: nil,
                analyticsName: "love_is_a_drug_viewed"
            ),
            ScreenConfig(
                id: "grieve_as_deep",
                type: .grieveAsDeep,
                title: "You grieve as deeply as you loved",
                isSkippable: false,
                nextScreen: "the_costs",
                skipToScreen: nil,
                analyticsName: "grieve_as_deep_viewed"
            ),
            ScreenConfig(
                id: "the_costs",
                type: .theCosts,
                title: "The costs",
                isSkippable: false,
                nextScreen: "commit_to_change",
                skipToScreen: nil,
                analyticsName: "the_costs_viewed"
            ),
            ScreenConfig(
                id: "commit_to_change",
                type: .commitToChange,
                title: "Commit to change",
                isSkippable: false,
                nextScreen: "healing_timeline",
                skipToScreen: nil,
                analyticsName: "commit_to_change_viewed"
            ),
            ScreenConfig(
                id: "healing_timeline",
                type: .healingTimeline,
                title: "Healing timeline",
                isSkippable: false,
                nextScreen: "mochi_help",
                skipToScreen: nil,
                analyticsName: "healing_timeline_viewed"
            ),
            ScreenConfig(
                id: "mochi_help",
                type: .mochiHelp,
                title: "How Mochi helps",
                isSkippable: false,
                nextScreen: "checkin_frequency",
                skipToScreen: nil,
                analyticsName: "mochi_help_viewed"
            ),
            ScreenConfig(
                id: "checkin_frequency",
                type: .checkinFrequency,
                title: "Check-in frequency",
                isSkippable: false,
                nextScreen: "social_proof",
                skipToScreen: nil,
                analyticsName: "checkin_frequency_viewed"
            ),
            ScreenConfig(
                id: "social_proof",
                type: .socialProof,
                title: "Women have healed",
                isSkippable: false,
                nextScreen: "mochi_promise",
                skipToScreen: nil,
                analyticsName: "social_proof_viewed"
            ),
            ScreenConfig(
                id: "mochi_promise",
                type: .mochiPromise,
                title: "Mochi's promise",
                isSkippable: false,
                nextScreen: "supabase_auth",
                skipToScreen: nil,
                analyticsName: "mochi_promise_viewed"
            ),
            ScreenConfig(
                id: "supabase_auth",
                type: .supabaseAuth,
                title: "Secure Your Account",
                isSkippable: false,
                nextScreen: "welcome_to_goh",
                skipToScreen: nil,
                analyticsName: "supabase_auth_viewed"
            ),
            ScreenConfig(
                id: "welcome_to_goh",
                type: .welcomeToCheckpoint,
                title: "Welcome to Get Over Him",
                isSkippable: false,
                nextScreen: "last_contact_date",
                skipToScreen: nil,
                analyticsName: "welcome_to_goh_viewed"
            ),
            ScreenConfig(
                id: "last_contact_date",
                type: .lastContactDate,
                title: "When did you last contact him?",
                isSkippable: false,
                nextScreen: nil,  // End onboarding - go to main app
                skipToScreen: nil,
                analyticsName: "last_contact_date_viewed"
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
