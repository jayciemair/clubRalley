//
//  ClubRalleyOnboardingCoordinator.swift
//  Club Ralley
//
//  Main coordinator for Club Ralley onboarding flow
//

import SwiftUI

struct ClubRalleyOnboardingCoordinator: View {
    @StateObject private var controller = ClubRalleyOnboardingController()
    let completion: () -> Void

    var body: some View {
        ZStack {
            // Background - white per Figma
            Color.white
                .ignoresSafeArea()

            if controller.isComplete {
                // Completion celebration
                OnboardingCompletionView {
                    completion()
                }
                .transition(.opacity)
            } else {
                // Main onboarding content
                VStack(spacing: 0) {
                    // Progress bar (hide on welcome and completion screens)
                    if controller.currentStep != .welcome && controller.currentStep != .completion {
                        ClubRalleyProgressBar(progress: controller.currentProgress)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }

                    // Current screen content
                    screenView(for: controller.currentStep)
                        .environmentObject(controller)
                }
            }

            // Loading overlay
            if controller.isLoading {
                LoadingOverlay()
            }
        }
        .alert("Error", isPresented: Binding(
            get: { controller.error != nil },
            set: { if !$0 { controller.error = nil } }
        )) {
            Button("OK") {
                controller.error = nil
            }
        } message: {
            Text(controller.error?.localizedDescription ?? "Unknown error")
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private func screenView(for step: ClubRalleyOnboardingStep) -> some View {
        switch step {
        case .welcome:
            RalleyWelcomeScreen()
                .environmentObject(controller)

        case .email:
            EmailScreen()
                .environmentObject(controller)

        case .password:
            PasswordScreen()
                .environmentObject(controller)

        case .name:
            NameScreen()
                .environmentObject(controller)

        case .username:
            UsernameScreen()
                .environmentObject(controller)

        case .profilePhoto:
            ProfilePhotoScreen()
                .environmentObject(controller)

        case .location:
            LocationScreen()
                .environmentObject(controller)

        case .sports:
            SportsOnboardingScreen()
                .environmentObject(controller)

        case .completion:
            OnboardingCompletionView {
                completion()
            }
        }
    }
}

// MARK: - Progress Bar Component

struct ClubRalleyProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)

                // Progress fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "#2C4F40"))
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#2C4F40")))
                    .scaleEffect(1.2)

                Text("Setting up your profile...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
    }
}

// MARK: - Completion View

struct OnboardingCompletionView: View {
    let completion: () -> Void
    @State private var animateCheckmark = false
    @State private var animateContent = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Success icon with animation
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color(hex: "#2C4F40").opacity(0.2), lineWidth: 4)
                        .frame(width: 140, height: 140)

                    // Animated ring
                    Circle()
                        .trim(from: 0, to: animateCheckmark ? 1 : 0)
                        .stroke(Color(hex: "#2C4F40"), lineWidth: 4)
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.8), value: animateCheckmark)

                    // Inner circle
                    Circle()
                        .fill(Color(hex: "#2C4F40"))
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(animateCheckmark ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.4), value: animateCheckmark)
                }

                VStack(spacing: 16) {
                    Text("Congrats!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.6), value: animateContent)

                    Text("You made the team!")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(hex: "#2C4F40"))
                        .multilineTextAlignment(.center)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.5).delay(0.8), value: animateContent)
                }
                .padding(.horizontal, 32)

                Spacer()

                Button(action: completion) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#2C4F40"))
                        .cornerRadius(30)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 30)
                .animation(.easeOut(duration: 0.5).delay(1.0), value: animateContent)
            }
        }
        .onAppear {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
            animateCheckmark = true
            animateContent = true
        }
    }
}

// MARK: - Preview

struct ClubRalleyOnboardingCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        ClubRalleyOnboardingCoordinator {
            print("Onboarding completed!")
        }
    }
}
