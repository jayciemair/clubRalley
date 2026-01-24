//
//  WelcomeToCheckpointScreen.swift
//  Checkpoint
//
//  Welcome message after subscription to validate user's decision

import SwiftUI

struct WelcomeToCheckpointScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController

    // Animation states for sequential reveal
    @State private var titleOpacity: Double = 0.0
    @State private var message1Opacity: Double = 0.0
    @State private var message2Opacity: Double = 0.0
    @State private var message3Opacity: Double = 0.0
    @State private var showContinueButton = false

    var body: some View {
        ZStack {
            OnboardingGradientBackground(style: .roseGlow, animated: true)

            OnboardingScrollableLayout(
                showBackButton: false,
                showContinueButton: showContinueButton,
                backgroundColor: .clear
            ) {
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()

                // Mochi mascot
                Image("Mochi")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .opacity(titleOpacity)

                VStack(alignment: .center, spacing: AppTheme.Spacing.lg) {
                    // Title
                    Text("welcome to\nget over him 🩷")
                        .font(.custom("Satoshi-Bold", size: 36))
                        .foregroundColor(Color(hex: "#4A2040"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(titleOpacity)

                    // Welcome message
                    VStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                        Text("you just made the best investment")
                            .font(.custom("Satoshi-Bold", size: 22))
                            .foregroundColor(Color(hex: "#4A2040"))
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(message1Opacity)

                        Text("not in an app - in yourself")
                            .font(.custom("Satoshi-Medium", size: 20))
                            .foregroundColor(Color(hex: "#6A3060").opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(message2Opacity)

                        Text("let's finish setting things up")
                            .font(.custom("Satoshi-Regular", size: 18))
                            .foregroundColor(Color(hex: "#6A3060").opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, AppTheme.Spacing.sm)
                            .opacity(message3Opacity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, AppTheme.Spacing.lg)

                Spacer()
            }
            } continueAction: {
                flowController.saveData(for: "welcome_to_checkpoint", data: ["viewed": true])
                flowController.navigateNext()
            }
        }
        .onAppear {
            animateSequence()
        }
    }

    // MARK: - Animations

    private func animateSequence() {
        let generator = UIImpactFeedbackGenerator(style: .medium)

        // 1. Title (0.3s) - instant pop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            titleOpacity = 1.0
            generator.impactOccurred()
        }

        // 2. First message (0.9s) - instant pop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            message1Opacity = 1.0
            generator.impactOccurred()
        }

        // 3. Second message (1.5s) - instant pop
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            message2Opacity = 1.0
            generator.impactOccurred()
        }

        // 4. Third message + continue button (2.1s) - instant pop
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            message3Opacity = 1.0
            showContinueButton = true
            generator.impactOccurred()
        }
    }
}

struct WelcomeToCheckpointScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeToCheckpointScreen()
            .environmentObject(OnboardingFlowController())
    }
}
