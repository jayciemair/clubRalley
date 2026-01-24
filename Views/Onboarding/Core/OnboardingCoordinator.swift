//
//  OnboardingCoordinator.swift
//  Get Over Him
//
//  Maps screen types to actual SwiftUI views and handles navigation
//

import SwiftUI

/// Coordinator that handles the mapping between screen types and actual SwiftUI views
struct OnboardingCoordinator: View {
    @EnvironmentObject var flowController: OnboardingFlowController
    @StateObject private var completionViewModel = OnboardingCompletionViewModel()

    let flowType: FlowType
    let skipCompletion: Bool
    let completion: ((OnboardingResult) -> Void)?

    init(flowType: FlowType? = nil, skipCompletion: Bool = false, completion: ((OnboardingResult) -> Void)? = nil) {
        if let providedType = flowType {
            self.flowType = providedType
        } else {
            let typeManager = OnboardingTypeManager.shared
            if let _ = typeManager.determineRequiredOnboarding() {
                self.flowType = .software
            } else {
                self.flowType = .software
            }
        }
        self.skipCompletion = skipCompletion
        self.completion = completion
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            if flowController.isLoading {
                loadingView
            } else if let error = flowController.error {
                errorView(error: error)
            } else if let currentScreen = flowController.currentScreen {
                screenView(for: currentScreen)
                    .id(currentScreen.id)
            } else {
                emptyStateView
            }
        }
        .onAppear {
            flowController.startSimplifiedFlow(type: flowType)
            flowController.checkForSavedProgress()
        }
        .onChange(of: flowController.isComplete) { isComplete in
            if isComplete {
                let collectedData = flowController.getAllCollectedData()

                if skipCompletion {
                    OnboardingStateManager.shared.clearProgress()
                    completion?(.completed(collectedData: collectedData))
                } else {
                    let flowMetadata: [String: Any] = [
                        "current_screen_id": flowController.currentScreen?.id ?? "unknown",
                        "current_screen_title": flowController.currentScreen?.title ?? "unknown",
                        "screens_completed": flowController.screenHistory.count,
                        "flow_progress": flowController.flowProgress,
                        "flow_type": flowType.rawValue
                    ]

                    Task {
                        do {
                            try await completionViewModel.completeOnboarding(
                                collectedData: collectedData,
                                flowMetadata: flowMetadata
                            )
                        } catch {
                            // Continue anyway
                        }

                        await MainActor.run {
                            OnboardingStateManager.shared.clearProgress()

                            let typeManager = OnboardingTypeManager.shared
                            if flowType == .software {
                                typeManager.markOnboardingCompleted(for: .software)
                            } else if flowType == .dataRecovery {
                                typeManager.markOnboardingCompleted(for: .software)
                            }

                            completion?(.completed(collectedData: collectedData))
                        }
                    }
                }
            }
        }
        .onChange(of: flowController.shouldExitFlow) { shouldExit in
            if shouldExit {
                OnboardingStateManager.shared.clearProgress()
                completion?(.cancelled)
                flowController.resetOnboarding()
            }
        }
        .onChange(of: flowController.error) { error in
            if let error = error {
                completion?(.failed(error: error))
            }
        }
    }

    private var loadingView: some View {
        Color.clear
    }

    private func errorView(error: OnboardingError) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("Something went wrong")
                .font(.custom("Satoshi-Bold", size: 20))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text(error.localizedDescription)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)

            Button("Try Again") {
                flowController.startSimplifiedFlow(type: flowType)
            }
            .primaryButtonStyle()
            .padding(.horizontal, AppTheme.Spacing.xl)
        }
    }

    private var emptyStateView: some View {
        loadingView
    }

    // MARK: - Screen View Mapping
    @ViewBuilder
    private func screenView(for screen: ScreenConfig) -> some View {
        switch screen.type {
        // MARK: - Intro Screens
        case .welcomeSplash:
            WelcomeSplashScreen()
                .environmentObject(flowController)

        case .mochiIntro:
            MochiIntroScreen()
                .environmentObject(flowController)

        case .nameInput:
            NameInputScreen()
                .environmentObject(flowController)

        case .notAboutHim:
            NotAboutHimScreen()
                .environmentObject(flowController)

        case .mochiBridge:
            MochiBridgeScreen()
                .environmentObject(flowController)

        case .breakupTiming:
            BreakupTimingScreen()
                .environmentObject(flowController)

        case .whoEndedIt:
            WhoEndedItScreen()
                .environmentObject(flowController)

        case .whatsHurting:
            WhatsHurtingScreen()
                .environmentObject(flowController)

        case .howCoping:
            HowCopingScreen()
                .environmentObject(flowController)

        case .mainGoals:
            MainGoalsScreen()
                .environmentObject(flowController)

        case .calculatingResults:
            CalculatingResultsScreen()
                .environmentObject(flowController)

        case .attachmentReveal:
            AttachmentRevealScreen()
                .environmentObject(flowController)

        case .youCared:
            YouCaredScreen()
                .environmentObject(flowController)

        case .healingNotLinear:
            HealingNotLinearScreen()
                .environmentObject(flowController)

        case .mochiJourney:
            MochiJourneyScreen()
                .environmentObject(flowController)

        case .urgeToText:
            UrgeToTextScreen()
                .environmentObject(flowController)

        case .textHimPreview:
            TextHimPreviewScreen()
                .environmentObject(flowController)

        case .textHimDemo:
            TextHimDemoScreen()
                .environmentObject(flowController)

        case .mochiRealTalk:
            MochiRealTalkScreen()
                .environmentObject(flowController)

        case .loveIsADrug:
            LoveIsADrugScreen()
                .environmentObject(flowController)

        case .grieveAsDeep:
            GrieveAsDeepScreen()
                .environmentObject(flowController)

        case .theCosts:
            TheCostsScreen()
                .environmentObject(flowController)

        case .commitToChange:
            CommitToChangeScreen()
                .environmentObject(flowController)

        case .healingTimeline:
            HealingTimelineScreen()
                .environmentObject(flowController)

        case .mochiHelp:
            MochiHelpScreen()
                .environmentObject(flowController)

        case .checkinFrequency:
            CheckInFrequencyScreen()
                .environmentObject(flowController)

        case .mochiPromise:
            MochiPromiseScreen()
                .environmentObject(flowController)

        case .socialProof:
            SocialProofScreen()
                .environmentObject(flowController)

        // MARK: - Auth
        case .supabaseAuth:
            UniversalAuthScreen()
                .environmentObject(flowController)

        // MARK: - Setup Screens
        case .welcomeToCheckpoint:
            WelcomeToCheckpointScreen()
                .environmentObject(flowController)

        case .lastContactDate:
            LastContactDateScreen()
                .environmentObject(flowController)

        // MARK: - Data Recovery
        case .dataRecoveryIntro:
            // Placeholder for data recovery intro - uses welcome screen for now
            WelcomeToCheckpointScreen()
                .environmentObject(flowController)

        // MARK: - Deletion Prevention
        case .breathingIntro:
            BreathingIntroScreen()
                .environmentObject(flowController)

        case .breathingExercise:
            BreathingExerciseScreen()
                .environmentObject(flowController)
        }
    }
}
