//
//  BreathingFlowWrapper.swift
//  Checkpoint
//
//  Wrapper for breathing exercise flow that works with callbacks
//  Can be used by deletion prevention or any other feature
//

import SwiftUI

enum BreathingFlowStep {
    case intro
    case exercise
}

struct BreathingFlowWrapper: View {
    let onComplete: () -> Void

    @State private var currentStep: BreathingFlowStep = .intro

    var body: some View {
        ZStack {
            if currentStep == .intro {
                BreathingIntroView(onContinue: {
                    currentStep = .exercise
                })
            } else {
                BreathingExerciseView(onComplete: {
                    onComplete()
                })
            }
        }
    }
}

// MARK: - Breathing Intro (adapted from BreathingIntroScreen)

struct BreathingIntroView: View {
    let onContinue: () -> Void
    @State private var showContinueButton = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.20, blue: 0.35),
                    Color(red: 0.08, green: 0.10, blue: 0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .center, spacing: AppTheme.Spacing.xl) {
                    Text("Take a moment")
                        .font(.custom("Satoshi-Bold", size: 36))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .center, spacing: AppTheme.Spacing.lg) {
                        Image(systemName: "wind")
                            .font(.system(size: 64))
                            .foregroundColor(AppTheme.Colors.primary)

                        VStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                            Text("Let's do 4 breathing cycles")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)

                            Text("Follow the expanding and shrinking circle as you breathe")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                    }
                }

                Spacer()

                // Continue button at bottom
                Button(action: {
                    onContinue()
                }) {
                    Text("Continue")
                        .font(.custom("Satoshi-Bold", size: 17))
                        .foregroundColor(AppTheme.Colors.darkSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.Colors.primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showContinueButton ? 1 : 0)
                .disabled(!showContinueButton)
            }
        }
        .onAppear {
            // Delay showing continue button by 1.5 seconds
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation {
                    showContinueButton = true
                }
            }
        }
    }
}

// MARK: - Breathing Exercise (adapted from BreathingExerciseScreen)

struct BreathingExerciseView: View {
    let onComplete: () -> Void

    @State private var isAnimating = false
    @State private var breathingPhase: BreathingPhase = .inhale
    @State private var completedReps = 0
    @State private var showContinue = false

    let totalReps = 4

    enum BreathingPhase {
        case inhale
        case hold
        case exhale
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.20, blue: 0.35),
                    Color(red: 0.08, green: 0.10, blue: 0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Breathing animation circle
                VStack(spacing: AppTheme.Spacing.lg) {
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.6, blue: 0.9).opacity(0.3),
                                        Color(red: 0.3, green: 0.5, blue: 0.8).opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 200, height: 200)
                            .scaleEffect(isAnimating ? 1.0 : 0.6)
                            .opacity(isAnimating ? 0.6 : 0.3)
                            .animation(.easeInOut(duration: getAnimationDuration()), value: isAnimating)

                        // Animated breathing circle with gradient
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.6, blue: 0.9),
                                        Color(red: 0.3, green: 0.5, blue: 0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: getCircleSize(), height: getCircleSize())
                            .scaleEffect(isAnimating ? 1.0 : 0.6)
                            .opacity(getCircleOpacity())
                            .animation(.easeInOut(duration: getAnimationDuration()), value: isAnimating)
                    }

                    // Breathing instruction text
                    VStack(spacing: 8) {
                        if showContinue {
                            Text("Breathwork Complete")
                                .font(.custom("Satoshi-Bold", size: 24))
                                .foregroundColor(AppTheme.Colors.success)
                                .transition(.opacity)

                            Text(" ")
                                .font(.system(size: 16))
                        } else {
                            Text(getBreathingText())
                                .font(.custom("Satoshi-Bold", size: 24))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .transition(.opacity)

                            Text("(\(completedReps + 1)/\(totalReps))")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                }

                Spacer()
            }

            // Continue button at bottom
            VStack {
                Spacer()

                if showContinue {
                    Button(action: {
                        onComplete()
                    }) {
                        Text("Continue")
                            .font(.custom("Satoshi-Bold", size: 17))
                            .foregroundColor(AppTheme.Colors.darkSurface)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            startBreathingCycle()
        }
    }

    // MARK: - Helper Methods

    private func startBreathingCycle() {
        Task {
            for rep in 0..<totalReps {
                completedReps = rep

                // Inhale (4 seconds)
                breathingPhase = .inhale
                isAnimating = true
                try await Task.sleep(nanoseconds: 4_000_000_000)

                // Hold (4 seconds)
                breathingPhase = .hold
                isAnimating = true
                try await Task.sleep(nanoseconds: 4_000_000_000)

                // Exhale (4 seconds)
                breathingPhase = .exhale
                isAnimating = false
                try await Task.sleep(nanoseconds: 4_000_000_000)

                // Pause between reps
                if rep < totalReps - 1 {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }

            // Complete
            completedReps = totalReps
            showContinue = true
        }
    }

    private func getBreathingText() -> String {
        switch breathingPhase {
        case .inhale:
            return "Breathe in..."
        case .hold:
            return "Hold..."
        case .exhale:
            return "Breathe out..."
        }
    }

    private func getCircleSize() -> CGFloat {
        switch breathingPhase {
        case .inhale, .hold:
            return 180
        case .exhale:
            return 120
        }
    }

    private func getCircleOpacity() -> Double {
        switch breathingPhase {
        case .inhale:
            return 1.0
        case .hold:
            return 0.8
        case .exhale:
            return 0.6
        }
    }

    private func getAnimationDuration() -> Double {
        switch breathingPhase {
        case .inhale, .exhale:
            return 4.0
        case .hold:
            return 0.0
        }
    }
}
