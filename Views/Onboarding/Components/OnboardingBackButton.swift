//
//  OnboardingBackButton.swift
//  Dial
//
//  Universal back button component for onboarding screens
//

import SwiftUI

struct OnboardingBackButton: View {
    @EnvironmentObject var flowController: OnboardingFlowController
    var color: Color = .black
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            if let customAction = action {
                customAction()
            } else {
                flowController.navigateBack()
            }
        }) {
            Image(systemName: "arrow.left")
                .font(.system(size: 24))
                .foregroundColor(color)
                .padding()
        }
    }
}

struct OnboardingBackButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    OnboardingBackButton()
                    Spacer()
                }
                Spacer()
            }
        }
        .environmentObject(OnboardingFlowController())
    }
}