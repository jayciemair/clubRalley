//
//  BoxBreathingPracticeView.swift
//  Checkpoint
//
//  Guided box breathing practice (4-4-4-4)
//

import SwiftUI

struct BoxBreathingPracticeView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.3
    @State private var currentPhase: BreathingPhase = .breatheIn
    @State private var currentRound: Int = 1
    @State private var timeRemaining: Int = 4

    let totalRounds = 4

    enum BreathingPhase {
        case breatheIn, hold1, breatheOut, hold2

        var instruction: String {
            switch self {
            case .breatheIn: return "Breathe In"
            case .hold1: return "Hold"
            case .breatheOut: return "Breathe Out"
            case .hold2: return "Hold"
            }
        }

        var next: BreathingPhase {
            switch self {
            case .breatheIn: return .hold1
            case .hold1: return .breatheOut
            case .breatheOut: return .hold2
            case .hold2: return .breatheIn
            }
        }
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.darkSurface
                .ignoresSafeArea()

            VStack(spacing: 60) {
                Spacer()

                // Breathing circle
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.85, green: 0.68, blue: 0.32).opacity(0.3),
                                    Color(red: 0.89, green: 0.75, blue: 0.45).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(scale)
                        .opacity(opacity)

                    // Inner circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.85, green: 0.68, blue: 0.32).opacity(0.4),
                                    Color(red: 0.89, green: 0.75, blue: 0.45).opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)

                    // Timer
                    Text("\(timeRemaining)")
                        .font(.custom("Satoshi-Bold", size: 48))
                        .foregroundColor(AppTheme.Colors.textPrimary.opacity(0.6))
                }

                // Instruction text
                VStack(spacing: 12) {
                    Text(currentPhase.instruction)
                        .font(.custom("Satoshi-Bold", size: 32))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    // Only show round counter when not complete
                    if currentRound <= totalRounds {
                        Text("Round \(currentRound) of \(totalRounds)")
                            .font(.custom("Satoshi-Regular", size: 16))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }

                Spacer()

                // Done button (only shows after completion)
                if currentRound > totalRounds {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.custom("Satoshi-Bold", size: 16))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.Colors.darkSurface)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppTheme.Colors.textPrimary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startBreathingCycle()
        }
    }

    private func startBreathingCycle() {
        runPhase()
    }

    private func runPhase() {
        // Reset timer
        timeRemaining = 4

        // Animate based on phase
        switch currentPhase {
        case .breatheIn:
            withAnimation(.easeInOut(duration: 4.0)) {
                scale = 1.3
                opacity = 0.7
            }
        case .hold1, .hold2:
            // No animation, just hold
            break
        case .breatheOut:
            withAnimation(.easeInOut(duration: 4.0)) {
                scale = 0.8
                opacity = 0.3
            }
        }

        // Start countdown timer
        startCountdown()
    }

    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if timeRemaining > 1 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
                advancePhase()
            }
        }
    }

    private func advancePhase() {
        // Move to next phase
        let wasLastPhase = currentPhase == .hold2
        currentPhase = currentPhase.next

        // If we completed a full cycle (4 phases), increment round
        if wasLastPhase {
            currentRound += 1
        }

        // Continue if not done
        if currentRound <= totalRounds {
            runPhase()
        } else {
            // Show completion
            withAnimation {
                currentPhase = .breatheIn
                timeRemaining = 0
            }
        }
    }
}

#Preview {
    NavigationView {
        BoxBreathingPracticeView()
    }
}
