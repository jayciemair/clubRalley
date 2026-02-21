//
//  WelcomeSplashScreen.swift
//  Club Ralley
//
//  Welcome splash screen - simple and elegant
//

import SwiftUI

struct WelcomeSplashScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController

    // Animation states
    @State private var mochiScale: CGFloat = 0.8
    @State private var mochiOpacity: Double = 0
    @State private var displayedText: String = ""
    @State private var subtitleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var animationsStarted = false

    private let fullTitle = "its time to\nJOIN THE RALLEY"

    var body: some View {
        ZStack {
            // Pink/rose gradient background using the gradient system
            OnboardingGradientBackground(style: .roseGlow, animated: true)

            // DEBUG: Skip to Superwall screen button
            #if DEBUG
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        print("[Superwall] 🔵 DEBUG: Skipping to mochi_promise screen...")
                        flowController.navigateToScreen(withId: "mochi_promise")
                    }) {
                        Text("Skip to Paywall")
                            .font(.custom("Satoshi-Medium", size: 12))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 60)
                }
                Spacer()
            }
            #endif

            VStack(spacing: 0) {
                Spacer()

                // Mochi mascot
                Image("Mochi")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .scaleEffect(mochiScale)
                    .opacity(mochiOpacity)

                Spacer()
                    .frame(height: 32)

                // Main title with typing animation - fixed height so Mochi doesn't shift
                ZStack {
                    // Invisible placeholder for full text size
                    Text("its time to\nJOIN THE RALLEY")
                        .font(.custom("Satoshi-Bold", size: 34))
                        .foregroundColor(.clear)
                        .multilineTextAlignment(.center)

                    // Actual displayed text
                    Text(displayedText)
                        .font(.custom("Satoshi-Bold", size: 34))
                        .foregroundColor(Color(hex: "#4A2040"))
                        .multilineTextAlignment(.center)
                }

                Spacer()
                    .frame(height: 16)

                // Subtitle
                Text("your healing journey starts here")
                    .font(.custom("Satoshi-Regular", size: 17))
                    .foregroundColor(Color(hex: "#6A3060").opacity(0.85))
                    .multilineTextAlignment(.center)
                    .opacity(subtitleOpacity)

                Spacer()

                // Get Started button - more rounded
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()

                    flowController.saveData(for: "welcome_splash", data: [
                        "viewed": true,
                        "timestamp": Date().timeIntervalSince1970
                    ])
                    flowController.navigateNext()
                }) {
                    Text("get started")
                        .font(.custom("Satoshi-Bold", size: 18))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.91, green: 0.30, blue: 0.55),  // Rose pink
                                    Color(red: 0.80, green: 0.25, blue: 0.60)   // Deeper pink
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)  // More rounded
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .opacity(buttonOpacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateEntrance()
            }
        }
    }

    private func animateEntrance() {
        guard !animationsStarted else { return }
        animationsStarted = true

        // Fade in Mochi with scale
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            mochiScale = 1
            mochiOpacity = 1
        }

        // Start typing animation after Mochi appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            typeText()
        }
    }

    private func typeText() {
        let characters = Array(fullTitle)
        var currentIndex = 0
        let typingSpeed = 0.05 // seconds per character

        let lightGenerator = UIImpactFeedbackGenerator(style: .light)
        lightGenerator.prepare()

        Timer.scheduledTimer(withTimeInterval: typingSpeed, repeats: true) { timer in
            if currentIndex < characters.count {
                displayedText.append(characters[currentIndex])
                currentIndex += 1

                // Haptic on every few characters
                if currentIndex % 3 == 0 {
                    lightGenerator.impactOccurred()
                }
            } else {
                timer.invalidate()
                // Show subtitle and button after typing completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        subtitleOpacity = 1
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        buttonOpacity = 1
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct WelcomeSplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeSplashScreen()
            .environmentObject(OnboardingFlowController())
    }
}
