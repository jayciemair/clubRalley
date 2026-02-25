//
//  CollegeAthleteScreen.swift
//  Club Ralley
//
//  Onboarding screen asking if the user played a sport in college
//

import SwiftUI

struct CollegeAthleteScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController

    @State private var isAthlete = false

    var body: some View {
        ClubRalleyScrollableLayout(
            canGoBack: controller.canGoBack,
            onBack: { controller.goToPreviousStep() },
            onContinue: { saveAndContinue() },
            continueEnabled: true
        ) {
            VStack(spacing: 32) {
                ClubRalleyOnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: controller.currentStep.subtitle
                )

                // College athlete toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isAthlete.toggle()
                    }
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: isAthlete ? "graduationcap.fill" : "graduationcap")
                            .font(.system(size: 24))
                            .foregroundColor(isAthlete ? Color(hex: "#2C4F40") : .gray)
                            .frame(width: 32)

                        Text("I played a sport in college")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(ClubRalleyTheme.Colors.darkGreen)

                        Spacer()

                        if isAthlete {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(hex: "#2C4F40"))
                        } else {
                            Circle()
                                .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
                                .frame(width: 22, height: 22)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isAthlete ? Color(hex: "#2C4F40") : Color.gray.opacity(0.3), lineWidth: isAthlete ? 2 : 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 24)

                Spacer(minLength: 20)
            }
            .padding(.top, 20)
        }
        .onAppear {
            isAthlete = controller.onboardingData.athlete.isAthlete
        }
    }

    private func saveAndContinue() {
        controller.updateAthleteStatus(isAthlete: isAthlete)
        controller.goToNextStep()
    }
}
