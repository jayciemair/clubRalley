//
//  EmailScreen.swift
//  Club Ralley
//
//  Onboarding screen for email entry (Figma design)
//

import SwiftUI

struct EmailScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController

    @State private var email = ""
    @State private var isValidEmail = false
    @FocusState private var isEmailFocused: Bool

    var body: some View {
        ClubRalleyScrollableLayout(
            canGoBack: controller.canGoBack,
            onBack: { controller.goToPreviousStep() },
            onContinue: { saveAndContinue() },
            continueEnabled: isValidEmail
        ) {
            VStack(spacing: 32) {
                ClubRalleyOnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: nil
                )

                VStack(alignment: .leading, spacing: 8) {
                    RalleyUnderlinedTextField(
                        placeholder: "email@example.com",
                        text: $email,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        isValid: email.isEmpty ? nil : isValidEmail
                    )
                    .focused($isEmailFocused)
                    .onChange(of: email) { _, newValue in
                        email = newValue.trimmingCharacters(in: .whitespaces)
                        isValidEmail = controller.isValidEmail(email)
                        controller.updateEmail(email)
                    }

                    // Validation feedback
                    if !email.isEmpty && !isValidEmail {
                        Text("Please enter a valid email address")
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.2), value: isValidEmail)

                Spacer()
            }
            .padding(.top, 20)
        }
        .onAppear {
            email = controller.onboardingData.profile.email
            isValidEmail = controller.isValidEmail(email)
            isEmailFocused = true
        }
    }

    private func saveAndContinue() {
        controller.updateEmail(email)
        controller.goToNextStep()
    }
}

struct EmailScreen_Previews: PreviewProvider {
    static var previews: some View {
        EmailScreen()
            .environmentObject(ClubRalleyOnboardingController())
    }
}
