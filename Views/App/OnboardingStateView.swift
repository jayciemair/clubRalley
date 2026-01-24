//
//  OnboardingStateView.swift
//  Checkpoint
//
//  View for .onboardingRequired app state
//  Part of MVVM refactor - extracted from ContentView
//

import SwiftUI

struct OnboardingStateView: View {
    let flowType: OnboardingFlowType
    let onComplete: () -> Void

    @EnvironmentObject var onboardingFlowController: OnboardingFlowController

    var body: some View {
        AuthLoadingView()
            .id("authLoadingViewWithOnboarding")
            .fullScreenCover(isPresented: .constant(true)) {
                let actualFlowType: FlowType = flowType == .software ? .software : .dataRecovery
                OnboardingCoordinator(flowType: actualFlowType) { result in
                    print("[debugRefactorFlows] 📬 OnboardingStateView received completion result: \(result)")
                    switch result {
                    case .completed(_):
                        print("[debugRefactorFlows] 📬 Calling onComplete() callback to ContentView")
                        onComplete()
                        print("[debugRefactorFlows] 📬 onComplete() callback executed")
                    case .cancelled:
                        print("[debugRefactorFlows] 📬 Onboarding cancelled")
                        break
                    case .failed(_):
                        print("[debugRefactorFlows] 📬 Onboarding failed")
                        break
                    }
                }
                .environmentObject(onboardingFlowController)
                .interactiveDismissDisabled()
            }
    }
}
