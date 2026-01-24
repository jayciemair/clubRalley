//
//  SimulatorReflectionView.swift
//  goh
//
//  Post-simulation reflection flow - 4 questions, one per screen
//

import SwiftUI
import StoreKit

struct SimulatorReflectionView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep: ReflectionStep = .stillWantToText
    @State private var answer1: SimulatorStatsManager.StillWantToTextAnswer?
    @State private var answer2: SimulatorStatsManager.WasItWorthItAnswer?
    @State private var answer3: SimulatorStatsManager.WhatWouldHappenAnswer?
    @State private var answer4: SimulatorStatsManager.DidThisHelpAnswer?
    @State private var hasCompleted = false

    private let statsManager = SimulatorStatsManager.shared

    var onComplete: () -> Void

    enum ReflectionStep {
        case stillWantToText
        case wasItWorthIt
        case whatWouldHappen
        case didThisHelp
        case complete
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "#F8C8DC"),
                    Color(hex: "#F0A0C0"),
                    Color(hex: "#E890B8")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack {
                switch currentStep {
                case .stillWantToText:
                    StillWantToTextScreen { answer in
                        answer1 = answer
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .wasItWorthIt
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                case .wasItWorthIt:
                    WasItWorthItScreen { answer in
                        answer2 = answer
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .whatWouldHappen
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                case .whatWouldHappen:
                    WhatWouldHappenScreen { answer in
                        answer3 = answer
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = .didThisHelp
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                case .didThisHelp:
                    DidThisHelpScreen { answer in
                        answer4 = answer
                        saveAndComplete()
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                case .complete:
                    EmptyView()
                }
            }
        }
    }

    private func saveAndComplete() {
        // Prevent multiple calls
        guard !hasCompleted else { return }
        hasCompleted = true

        // Save the reflection data
        if let a1 = answer1, let a2 = answer2, let a3 = answer3, let a4 = answer4 {
            Task {
                await statsManager.recordReflection(
                    stillWantToText: a1,
                    wasItWorthIt: a2,
                    whatWouldHappen: a3,
                    didThisHelp: a4
                )
            }

            // Request rating if they said it helped (yes or kinda)
            if a4 == .yes || a4 == .kinda {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    requestAppRating()
                }
            }
        }

        // Small delay then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            onComplete()
            dismiss()
        }
    }

    private func requestAppRating() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

// MARK: - Question 1: Still Want To Text?

private struct StillWantToTextScreen: View {
    let onAnswer: (SimulatorStatsManager.StillWantToTextAnswer) -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("do you still want\nto text him?")
                .font(.custom("Satoshi-Bold", size: 28))
                .foregroundColor(Color(hex: "#4A2040"))
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                ReflectionButton(title: "no") {
                    HapticUtility.impact(style: .medium)
                    onAnswer(.no)
                }

                ReflectionButton(title: "less than before") {
                    HapticUtility.impact(style: .medium)
                    onAnswer(.lessThanBefore)
                }

                ReflectionButton(title: "still do") {
                    HapticUtility.impact(style: .medium)
                    onAnswer(.stillDo)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Question 2: Was It Worth It?

private struct WasItWorthItScreen: View {
    let onAnswer: (SimulatorStatsManager.WasItWorthItAnswer) -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("would texting him\nhave been worth it?")
                .font(.custom("Satoshi-Bold", size: 28))
                .foregroundColor(Color(hex: "#4A2040"))
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                ReflectionButton(title: "no") {
                    HapticUtility.impact(style: .medium)
                    onAnswer(.no)
                }

                ReflectionButton(title: "probably not") {
                    HapticUtility.impact(style: .medium)
                    onAnswer(.probablyNot)
                }

                ReflectionButton(title: "maybe") {
                    HapticUtility.impact(style: .medium)
                    onAnswer(.maybe)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Question 3: What Would Happen?

private struct WhatWouldHappenScreen: View {
    let onAnswer: (SimulatorStatsManager.WhatWouldHappenAnswer) -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("what would've happened\nif you sent that for real?")
                .font(.custom("Satoshi-Bold", size: 28))
                .foregroundColor(Color(hex: "#4A2040"))
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                ReflectionButton(title: "regret") {
                    HapticUtility.impact(style: .medium)
                    onAnswer(.regret)
                }

                ReflectionButton(title: "nothing good") {
                    HapticUtility.impact(style: .medium)
                    onAnswer(.nothingGood)
                }

                ReflectionButton(title: "drama") {
                    HapticUtility.impact(style: .medium)
                    onAnswer(.drama)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Question 4: Did This Help?

private struct DidThisHelpScreen: View {
    let onAnswer: (SimulatorStatsManager.DidThisHelpAnswer) -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("did this help?")
                .font(.custom("Satoshi-Bold", size: 28))
                .foregroundColor(Color(hex: "#4A2040"))
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                ReflectionButton(title: "yes") {
                    HapticUtility.impact(style: .medium)
                    onAnswer(.yes)
                }

                ReflectionButton(title: "kinda") {
                    HapticUtility.impact(style: .medium)
                    onAnswer(.kinda)
                }

                ReflectionButton(title: "not really") {
                    HapticUtility.impact(style: .medium)
                    onAnswer(.notReally)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Reusable Button

private struct ReflectionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Satoshi-Medium", size: 18))
                .foregroundColor(Color(hex: "#4A2040"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white.opacity(0.6))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

#Preview {
    SimulatorReflectionView(onComplete: {})
}
