//
//  PowerUpProgressBar.swift
//  Club Ralley
//
//  Progress bar component for Power Up Profile wizard
//

import SwiftUI

struct PowerUpProgressBar: View {
    let currentStep: PowerUpStep
    let onStepTap: ((PowerUpStep) -> Void)?

    init(currentStep: PowerUpStep, onStepTap: ((PowerUpStep) -> Void)? = nil) {
        self.currentStep = currentStep
        self.onStepTap = onStepTap
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(PowerUpStep.allCases, id: \.rawValue) { step in
                stepIndicator(for: step)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private func stepIndicator(for step: PowerUpStep) -> some View {
        let isComplete = step.rawValue < currentStep.rawValue
        let isCurrent = step == currentStep
        let isUpcoming = step.rawValue > currentStep.rawValue

        Button(action: {
            // Only allow tapping on completed steps
            if isComplete {
                onStepTap?(step)
            }
        }) {
            VStack(spacing: 6) {
                // Step circle
                ZStack {
                    Circle()
                        .fill(fillColor(isComplete: isComplete, isCurrent: isCurrent))
                        .frame(width: 32, height: 32)

                    if isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(step.rawValue + 1)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(textColor(isComplete: isComplete, isCurrent: isCurrent))
                    }
                }

                // Step label (only show for current)
                if isCurrent {
                    Text(step.title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isComplete)
        .frame(maxWidth: .infinity)

        // Connector line
        if step != PowerUpStep.allCases.last {
            Rectangle()
                .fill(connectorColor(stepComplete: isComplete))
                .frame(height: 2)
                .frame(maxWidth: 20)
        }
    }

    private func fillColor(isComplete: Bool, isCurrent: Bool) -> Color {
        if isComplete {
            return ClubRalleyTheme.Colors.darkGreen
        } else if isCurrent {
            return ClubRalleyTheme.Colors.darkGreen
        } else {
            return Color(.systemGray5)
        }
    }

    private func textColor(isComplete: Bool, isCurrent: Bool) -> Color {
        if isComplete || isCurrent {
            return .white
        } else {
            return Color(.systemGray3)
        }
    }

    private func connectorColor(stepComplete: Bool) -> Color {
        stepComplete ? ClubRalleyTheme.Colors.darkGreen : Color(.systemGray5)
    }
}

// MARK: - Simple Progress Bar (Alternative)

struct PowerUpSimpleProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 8)

                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(ClubRalleyTheme.Colors.darkGreen)
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 8)
        .padding(.horizontal, 24)
    }
}

// MARK: - Preview

struct PowerUpProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            PowerUpProgressBar(currentStep: .rosterPhoto)
            PowerUpProgressBar(currentStep: .socialBio)
            PowerUpProgressBar(currentStep: .sportsSkill)
            PowerUpProgressBar(currentStep: .availability)
            PowerUpProgressBar(currentStep: .funQuestions)

            Divider()

            PowerUpSimpleProgressBar(progress: 0.2)
            PowerUpSimpleProgressBar(progress: 0.6)
            PowerUpSimpleProgressBar(progress: 1.0)
        }
        .padding()
    }
}
