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
            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
                    // Progress bar
                    OnboardingProgressBar(progress: controller.currentProgress)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
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
        .alert("Error", isPresented: .constant(controller.error != nil)) {
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
            WelcomeScreen()
                .environmentObject(controller)
                
        case .signUp:
            SignUpScreen()
                .environmentObject(controller)
                
        case .profileBasics:
            ProfileBasicsScreen()
                .environmentObject(controller)
                
        case .profileDetails:
            ProfileDetailsScreen()
                .environmentObject(controller)
                
        case .athleteQuestion:
            AthleteQuestionScreen()
                .environmentObject(controller)
                
        case .athleteVerification:
            AthleteVerificationScreen()
                .environmentObject(controller)
                
        case .sportsSelection:
            SportsSelectionScreen()
                .environmentObject(controller)
                
        case .interests:
            InterestsScreen()
                .environmentObject(controller)
                
        case .availability:
            AvailabilityScreen()
                .environmentObject(controller)
                
        case .completion:
            OnboardingCompletionView {
                completion()
            }
        }
    }
}

// MARK: - Progress Bar Component

struct OnboardingProgressBar: View {
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Getting Started")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 4)
        }
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
                    .scaleEffect(1.2)
                
                Text("Setting up your profile...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            )
        }
    }
}

// MARK: - Completion View

struct OnboardingCompletionView: View {
    let completion: () -> Void
    @State private var showingConfetti = true
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success icon with animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(showingConfetti ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showingConfetti)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 16) {
                Text("Welcome to Club Ralley! 🎉")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                
                Text("You're all set up and ready to start rallying with your community!")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("GFTO - Get the F*** Outside")
                    .font(.title2.bold())
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button(action: completion) {
                Text("Start Rallying")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .onAppear {
            // Trigger haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
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