//
//  AppCoordinator.swift
//  Checkpoint
//
//  App-level coordinator managing app state, health checks, and DNS monitoring
//  Extracted from ContentView as part of MVVM refactoring
//

import SwiftUI
import Combine

/// App-level coordinator managing application state machine and lifecycle
@MainActor
class AppCoordinator: ObservableObject {

    // MARK: - Published Properties

    /// Current application state
    @Published var appState: AppState = .initializing {
        didSet {
            print("[debugFlowTransition] ⚡ AppCoordinator.appState CHANGED:")
            print("[debugFlowTransition] ⚡   FROM: \(oldValue)")
            print("[debugFlowTransition] ⚡   TO:   \(appState)")
        }
    }

    // MARK: - Dependencies (Services)

    private let authService = AuthenticationService.shared
    private let supabase = SupabaseClientManager.shared

    // MARK: - Private State

    private var previousAuthState: CheckpointAuthState?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupObservers()
    }

    // MARK: - Public Methods

    /// Called when app first appears - checks if services are ready
    func onAppAppear() {
        // Check if both services have already completed initial checks
        if authService.hasCompletedInitialCheck && supabase.hasCompletedInitialSessionCheck {
            handleAuthStateResolved()
        }
    }

    // MARK: - Setup

    /// Setup observers for auth and Supabase state changes
    private func setupObservers() {
        // Observe auth state changes
        authService.$authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                guard let self = self else { return }
                self.updateOnboardingModalState()
            }
            .store(in: &cancellables)

        // Observe onboarding completion (READ-ONLY - no state changes!)
        authService.$hasCompletedOnboarding
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self = self else { return }
                print("[debugFlowTransition] 👀 hasCompletedOnboarding observer fired: \(String(describing: newValue))")
                print("[debugFlowTransition] 👀 Current appState: \(self.appState)")

                // Industry standard: Observers should be READ-ONLY
                // All state transitions happen via explicit callbacks
                // This observer exists only for debugging/logging
            }
            .store(in: &cancellables)

        // Observe Supabase initial session check
        supabase.$hasCompletedInitialSessionCheck
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completed in
                guard let self = self else { return }
                if completed {
                    self.checkIfBothServicesReady()
                }
            }
            .store(in: &cancellables)

        // Observe AuthService initial check
        authService.$hasCompletedInitialCheck
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completed in
                guard let self = self else { return }
                if completed {
                    self.checkIfBothServicesReady()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - State Machine Logic

    /// Check if both auth and Supabase services are ready
    private func checkIfBothServicesReady() {
        guard authService.hasCompletedInitialCheck && supabase.hasCompletedInitialSessionCheck else {
            return
        }

        handleAuthStateResolved()
    }

    /// Handle auth state after both services are ready (APP STARTUP ONLY)
    private func handleAuthStateResolved() {
        print("[debugFlowTransition] 🚀 handleAuthStateResolved() - app startup")
        print("[debugFlowTransition] 🚀 Auth state: \(authService.authState)")
        print("[debugFlowTransition] 🚀 Has completed onboarding: \(String(describing: authService.hasCompletedOnboarding))")

        switch authService.authState {
        case .authenticated:
            // User is authenticated - determine next step based on onboarding status
            if let hasCompletedOnboarding = authService.hasCompletedOnboarding {
                if hasCompletedOnboarding {
                    // Returning user - go straight to app (no celebration)
                    print("[debugFlowTransition] 🚀 Returning user - going to ready state")
                    performHealthCheck()
                } else {
                    // Authenticated but hasn't completed onboarding
                    print("[debugFlowTransition] 🚀 User needs onboarding")
                    appState = .onboardingRequired(flowType: .software)
                }
            } else {
                // Onboarding status unknown - wait for it to load
                print("[debugFlowTransition] 🚀 Onboarding status unknown - staying in initializing")
            }

        case .unauthenticated, .error:
            print("[debugFlowTransition] 🚀 User not authenticated - showing onboarding")
            appState = .onboardingRequired(flowType: .software)

        case .authenticating:
            print("[debugFlowTransition] 🚀 Authentication in progress - waiting")
            break
        }
    }

    /// Update onboarding modal state based on auth and onboarding status
    /// This is called when authState changes mid-flow (e.g., user signs out)
    func updateOnboardingModalState() {
        print("[debugFlowTransition] 🔄 updateOnboardingModalState() called, current state: \(appState)")
        print("[debugFlowTransition] 🔄 Auth state: \(authService.authState)")

        // Don't process until both services are ready (app startup is handled by handleAuthStateResolved)
        if !authService.hasCompletedInitialCheck || !supabase.hasCompletedInitialSessionCheck {
            print("[debugFlowTransition] 🔄 Services not ready - skipping")
            return
        }

        // Handle auth state changes
        switch authService.authState {
        case .unauthenticated, .error:
            // User signed out or auth error - ALWAYS go to onboarding (don't skip!)
            print("[debugFlowTransition] 🔄 User unauthenticated - showing onboarding")
            appState = .onboardingRequired(flowType: .software)

        case .authenticated:
            // Only update state during initialization or onboarding
            // Don't interfere with setup/ready/health check flows
            switch appState {
            case .initializing:
                // App startup - don't do anything, handleAuthStateResolved handles it
                print("[debugFlowTransition] 🔄 Initializing - handleAuthStateResolved will handle")
                break

            case .onboardingRequired:
                // User just authenticated during onboarding
                // Let the explicit callback (handleOnboardingCompletion) handle transition
                print("[debugFlowTransition] 🔄 Onboarding flow - explicit callback will handle")
                break

            case .ready:
                // Don't interfere with ready state
                print("[debugFlowTransition] 🔄 Already ready - not updating")
                break
            }

        case .authenticating:
            print("[debugFlowTransition] 🔄 Authenticating - waiting for completion")
            break
        }
    }

    /// Perform health check - simplified, just go to ready
    func performHealthCheck() {
        print("[debugFlowTransition] 🏥 performHealthCheck() CALLED")
        print("[debugFlowTransition] 🏥 Setting appState = .ready(showSuccessHUD: false)")
        appState = .ready(showSuccessHUD: false)
    }

    /// Handle onboarding completion - go directly to ready state with celebration
    func handleOnboardingCompletion() {
        print("[debugFlowTransition] 🎬 AppCoordinator.handleOnboardingCompletion() CALLED")
        print("[debugFlowTransition] 🎬 Current appState: \(appState)")

        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "hasCompletedInitialOnboarding")

        // Go to ready state WITH success celebration
        print("[debugFlowTransition] 🎉 Setting appState = .ready(showSuccessHUD: true)")
        appState = .ready(showSuccessHUD: true)
    }

    /// Clear the success HUD after it's been shown
    func clearSuccessHUD() {
        if case .ready(showSuccessHUD: true) = appState {
            appState = .ready(showSuccessHUD: false)
        }
    }
}
