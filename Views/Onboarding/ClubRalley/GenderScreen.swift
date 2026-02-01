//
//  GenderScreen.swift
//  Club Ralley
//
//  Onboarding screen for gender selection
//

import SwiftUI

struct GenderScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController

    @State private var selectedGender: Gender?

    var body: some View {
        ClubRalleyScrollableLayout(
            canGoBack: controller.canGoBack,
            onBack: { controller.goToPreviousStep() },
            onContinue: { saveAndContinue() },
            continueEnabled: selectedGender != nil
        ) {
            VStack(spacing: 32) {
                ClubRalleyOnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: controller.currentStep.subtitle
                )

                // Gender options
                VStack(spacing: 12) {
                    GenderOption(
                        gender: .male,
                        icon: "figure.stand",
                        label: "Male",
                        isSelected: selectedGender == .male,
                        onTap: { selectGender(.male) }
                    )

                    GenderOption(
                        gender: .female,
                        icon: "figure.stand.dress",
                        label: "Female",
                        isSelected: selectedGender == .female,
                        onTap: { selectGender(.female) }
                    )

                    GenderOption(
                        gender: .preferNotToSay,
                        icon: "person.fill.questionmark",
                        label: "I'd prefer not to say",
                        isSelected: selectedGender == .preferNotToSay,
                        onTap: { selectGender(.preferNotToSay) }
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // Privacy note
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#2C4F40"))

                    Text("Your privacy matters")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)

                    Text("This information helps us personalize your experience and is never shared publicly.")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
            }
            .padding(.top, 20)
        }
        .onAppear {
            selectedGender = controller.onboardingData.profile.gender
        }
    }

    // MARK: - Actions

    private func selectGender(_ gender: Gender) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedGender = gender
        }
        controller.updateGender(gender)
    }

    private func saveAndContinue() {
        if let gender = selectedGender {
            controller.updateGender(gender)
        }
        controller.goToNextStep()
    }
}

// MARK: - Gender Option

private struct GenderOption: View {
    let gender: Gender
    let icon: String
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(hex: "#2C4F40") : Color.gray.opacity(0.1))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : Color(hex: "#2C4F40"))
                }

                // Label
                Text(label)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(hex: "#2C4F40") : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color(hex: "#2C4F40"))
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: "#2C4F40") : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color(hex: "#2C4F40").opacity(0.2) : Color.black.opacity(0.05),
                   radius: isSelected ? 8 : 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
