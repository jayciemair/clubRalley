//
//  PowerUpProfileCoordinator.swift
//  Club Ralley
//
//  Main coordinator for Power Up Profile wizard flow
//

import SwiftUI

struct PowerUpProfileCoordinator: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PowerUpProfileViewModel()

    var body: some View {
        ZStack {
            // Background
            Color.white
                .ignoresSafeArea()

            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Top bar with back button and progress
                    topBar

                    // Progress bar
                    PowerUpSimpleProgressBar(progress: viewModel.progress)
                        .padding(.bottom, 8)

                    // Main content
                    ScrollView(showsIndicators: false) {
                        currentStepView
                            .frame(minHeight: geometry.size.height - 200)
                    }
                }
            }

            // Floating continue button
            VStack {
                Spacer()
                continueButton
            }

            // Loading overlay
            if viewModel.isSaving {
                loadingOverlay
            }
        }
        .navigationBarHidden(true)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.error ?? "An error occurred")
        }
        .onChange(of: viewModel.isComplete) { _, isComplete in
            if isComplete {
                dismiss()
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Back button
            if viewModel.canGoBack {
                Button(action: { viewModel.goToPreviousStep() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                }
            } else {
                // Close button on first step
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
            }

            Spacer()

            // Step indicator
            Text("\(viewModel.currentStep.rawValue + 1) of \(PowerUpStep.allCases.count)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()

            // Skip button (only on non-required steps)
            if viewModel.currentStep == .rosterPhoto || viewModel.currentStep == .funQuestions {
                Button(action: { viewModel.goToNextStep() }) {
                    Text("Skip")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                }
            } else {
                // Placeholder for alignment
                Text("Skip")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.clear)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Current Step View

    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.currentStep {
        case .rosterPhoto:
            RosterPhotoStep()
                .environmentObject(viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

        case .socialBio:
            SocialBioStep()
                .environmentObject(viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

        case .sportsSkill:
            SportsSkillStep()
                .environmentObject(viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

        case .availability:
            AvailabilityStep()
                .environmentObject(viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

        case .funQuestions:
            FunQuestionsStep()
                .environmentObject(viewModel)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: {
            if viewModel.isLastStep {
                viewModel.completeFlow()
            } else {
                viewModel.goToNextStep()
            }
        }) {
            HStack {
                Text(viewModel.continueButtonText)
                    .font(.system(size: 17, weight: .semibold))

                if viewModel.isLastStep {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ClubRalleyTheme.Colors.darkGreen)
            .cornerRadius(30)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .allowsHitTesting(false)
        )
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("Saving your profile...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

// MARK: - Completion Celebration View

struct PowerUpCompletionView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Celebration icon
            ZStack {
                Circle()
                    .fill(ClubRalleyTheme.Colors.darkGreen.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "star.fill")
                    .font(.system(size: 50))
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
            }

            VStack(spacing: 12) {
                Text("Profile Powered Up!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)

                Text("Your profile is now complete and ready to impress your teammates")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            Button(action: onDismiss) {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ClubRalleyTheme.Colors.darkGreen)
                    .cornerRadius(30)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Preview

struct PowerUpProfileCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        PowerUpProfileCoordinator()
    }
}
