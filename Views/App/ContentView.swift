//
//  ContentView.swift
//  Checkpoint
//
//  Main app root view using MVVM pattern with AppCoordinator
//  Refactored to use AppCoordinator ViewModel and extracted state views
//

import SwiftUI
import CoreData

struct ContentView: View {
    // MARK: - Environment and Storage Properties
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var onboardingFlowController: OnboardingFlowController

    // MARK: - App Storage for Persistent State
    @AppStorage("selectedTab") var selectedTab: Tab = .v3test

    // MARK: - Coordinator (ViewModel)
    @StateObject private var coordinator = AppCoordinator()

    // MARK: - Welcome Celebration State
    @State private var showWelcomeConfetti = false

    // MARK: - Bindings for External Navigation
    @Binding var selectedTabOverride: Int
    @Binding var showAnalytics: Bool

    init(selectedTab: Binding<Int> = .constant(-1), showAnalytics: Binding<Bool> = .constant(false)) {
        self._selectedTabOverride = selectedTab
        self._showAnalytics = showAnalytics
    }

    var body: some View {
        stateView
            .navigationViewStyle(.stack)
            .withErrorHandling()
            .overlay(
                Group {
                    if showWelcomeConfetti {
                        WelcomeCelebrationView(isShowing: $showWelcomeConfetti)
                    }
                }
                .ignoresSafeArea(.all)
            )
            .onAppear {
                coordinator.onAppAppear()
            }
            .onChange(of: coordinator.appState) { newState in
                print("[debugFlowTransition] 🔄 ContentView appState CHANGED to: \(newState)")

                // Trigger welcome confetti when coming from onboarding
                if case .ready(showSuccessHUD: true) = newState {
                    showWelcomeConfetti = true
                    coordinator.clearSuccessHUD()
                }
            }
            .onChange(of: selectedTabOverride) { newValue in
                guard newValue >= 0 else { return }
                switch newValue {
                case 0: selectedTab = .v3test
                case 1: selectedTab = .analytics
                case 2: selectedTab = .settings
                default: break
                }
                selectedTabOverride = -1
            }
    }

    // MARK: - State View Switcher

    @ViewBuilder
    private var stateView: some View {
        switch coordinator.appState {
        case .initializing:
            LoadingStateView()
                .onAppear {
                    print("[debugFlowTransition] 📺 ContentView rendering: LoadingStateView")
                }

        case .onboardingRequired(let flowType):
            OnboardingStateView(
                flowType: flowType,
                onComplete: {
                    print("[debugFlowTransition] 📥 ContentView onComplete closure called")
                    coordinator.handleOnboardingCompletion()
                    print("[debugFlowTransition] 📥 coordinator.handleOnboardingCompletion() executed")
                }
            )
            .environmentObject(onboardingFlowController)
            .onAppear {
                print("[debugFlowTransition] 📺 ContentView rendering: OnboardingStateView (flowType: \(flowType))")
            }

        case .ready:
            ReadyStateView(
                onAuthenticatedAppear: {
                    handleAuthenticatedAppear()
                }
            )
            .onAppear {
                print("[debugFlowTransition] 📺 ContentView rendering: ReadyStateView (main app)")
            }
        }
    }

    // MARK: - Helper Methods

    /// Called when authenticated views appear (analytics setup, etc.)
    private func handleAuthenticatedAppear() {
        // Set default tab if needed
        if selectedTab != .v3test && selectedTab != .analytics && selectedTab != .settings {
            selectedTab = .v3test
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(OnboardingFlowController())
    }
}
