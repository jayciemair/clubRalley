//
//  OnboardingStateView.swift
//  Club Ralley
//
//  View for .onboardingRequired app state - now uses Club Ralley onboarding
//  Part of MVVM refactor - extracted from ContentView
//

import SwiftUI

struct OnboardingStateView: View {
    let flowType: OnboardingFlowType
    let onComplete: () -> Void

    @EnvironmentObject var onboardingFlowController: OnboardingFlowController

    var body: some View {
        // Temporary: Skip onboarding for now to get app running
        Color.clear
            .onAppear {
                // Mark onboarding as completed so we go straight to main app
                UserDefaults.standard.set(true, forKey: "hasCompletedInitialOnboarding")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onComplete()
                }
            }
    }
}
