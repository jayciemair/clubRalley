//
//  OnboardingScrollableLayout.swift
//  Dial
//
//  Reusable scrollable layout wrapper for onboarding screens
//  Prevents text overlap issues with proper padding and floating button
//

import SwiftUI

struct OnboardingScrollableLayout<Content: View>: View {
    let showBackButton: Bool
    let showContinueButton: Bool
    let continueEnabled: Bool
    let continueButtonText: String
    let backgroundColor: Color
    let backgroundGradient: LinearGradient?
    let buttonColor: Color
    let textColor: Color
    let backButtonOpacity: Double
    let continueButtonOpacity: Double
    let content: () -> Content
    let continueAction: () -> Void

    @EnvironmentObject var flowController: OnboardingFlowController

    init(
        showBackButton: Bool = true,
        showContinueButton: Bool = true,
        continueEnabled: Bool = true,
        continueButtonText: String = "continue",
        backgroundColor: Color = .white,
        backgroundGradient: LinearGradient? = nil,
        buttonColor: Color? = nil,
        textColor: Color? = nil,
        buttonsOpacity: Double = 1.0,
        backButtonOpacity: Double? = nil,
        continueButtonOpacity: Double? = nil,
        @ViewBuilder content: @escaping () -> Content,
        continueAction: @escaping () -> Void
    ) {
        self.showBackButton = showBackButton
        self.showContinueButton = showContinueButton
        self.continueEnabled = continueEnabled
        self.continueButtonText = continueButtonText
        self.backgroundColor = backgroundColor
        self.backgroundGradient = backgroundGradient
        // Auto-inverse colors based on background
        self.buttonColor = buttonColor ?? (backgroundColor == .white ? AppTheme.Colors.primary : .white)
        self.textColor = textColor ?? (backgroundColor == .white ? .black : .white)
        // Allow separate opacity for back and continue buttons, or use buttonsOpacity for both
        self.backButtonOpacity = backButtonOpacity ?? buttonsOpacity
        self.continueButtonOpacity = continueButtonOpacity ?? buttonsOpacity
        self.content = content
        self.continueAction = continueAction
    }

    var body: some View {
        ZStack {
            // Background (gradient or solid color)
            if let gradient = backgroundGradient {
                gradient
                    .ignoresSafeArea()
            } else {
                backgroundColor
                    .ignoresSafeArea()
            }

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Back button (no badge) - always rendered for layout
                        OnboardingHeader(
                            badge: nil,
                            showBackButton: showBackButton,
                            buttonColor: textColor
                        )
                        .opacity(backButtonOpacity)

                        // Custom content from each screen
                        content()

                        // Bottom padding to prevent content hiding behind floating button
                        if showContinueButton && continueEnabled {
                            Color.clear
                                .frame(height: 100)
                        }
                    }
                    .frame(minHeight: geometry.size.height)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }

            // Floating continue button at bottom - always rendered for layout
            if showContinueButton && continueEnabled {
                VStack {
                    Spacer()
                        .allowsHitTesting(false)
                    OnboardingContinueButton(
                        action: continueAction,
                        text: continueButtonText,
                        buttonColor: buttonColor,
                        textColor: backgroundColor == .white ? .white : .black  // White text on dark buttons, black text on white buttons
                    )
                    .opacity(continueButtonOpacity)
                    .allowsHitTesting(continueButtonOpacity > 0)  // Prevent taps when invisible
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .preferredColorScheme(.light)
    }
}
