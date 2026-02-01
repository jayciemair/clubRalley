//
//  PasswordScreen.swift
//  Club Ralley
//
//  Onboarding screen for password creation (Figma design)
//

import SwiftUI

struct PasswordScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController

    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case password, confirm
    }

    var body: some View {
        ClubRalleyScrollableLayout(
            canGoBack: controller.canGoBack,
            onBack: { controller.goToPreviousStep() },
            onContinue: { saveAndContinue() },
            continueEnabled: canContinue
        ) {
            VStack(spacing: 32) {
                ClubRalleyOnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: nil
                )

                VStack(spacing: 24) {
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        RalleyUnderlinedSecureField(
                            placeholder: "Password",
                            text: $password
                        )
                        .focused($focusedField, equals: .password)
                        .onChange(of: password) { _, newValue in
                            controller.updatePassword(newValue, confirm: confirmPassword)
                        }
                    }

                    // Confirm password field
                    VStack(alignment: .leading, spacing: 8) {
                        RalleyUnderlinedSecureField(
                            placeholder: "Confirm password",
                            text: $confirmPassword
                        )
                        .focused($focusedField, equals: .confirm)
                        .onChange(of: confirmPassword) { _, newValue in
                            controller.updatePassword(password, confirm: newValue)
                        }

                        if !confirmPassword.isEmpty && !passwordsMatch {
                            Text("Passwords don't match")
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Password requirements
                VStack(alignment: .leading, spacing: 12) {
                    PasswordRequirementRow(
                        text: "8 to 20 characters",
                        isMet: password.count >= 8 && password.count <= 20
                    )
                    PasswordRequirementRow(
                        text: "Letters, numbers, and special characters",
                        isMet: hasRequiredCharacters
                    )
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 20)
        }
        .onAppear {
            password = controller.onboardingData.profile.password
            confirmPassword = controller.onboardingData.profile.confirmPassword
            focusedField = .password
        }
    }

    // MARK: - Computed Properties

    private var canContinue: Bool {
        password.count >= 8 &&
        password.count <= 20 &&
        hasRequiredCharacters &&
        passwordsMatch
    }

    private var passwordsMatch: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }

    private var hasRequiredCharacters: Bool {
        let hasLetter = password.contains(where: { $0.isLetter })
        let hasNumber = password.contains(where: { $0.isNumber })
        return hasLetter && hasNumber
    }

    // MARK: - Actions

    private func saveAndContinue() {
        controller.updatePassword(password, confirm: confirmPassword)
        controller.goToNextStep()
    }
}

// MARK: - Password Requirement Row

private struct PasswordRequirementRow: View {
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundColor(isMet ? Color(hex: "#2C4F40") : .gray.opacity(0.4))

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(isMet ? .black : .gray)
        }
    }
}

struct PasswordScreen_Previews: PreviewProvider {
    static var previews: some View {
        PasswordScreen()
            .environmentObject(ClubRalleyOnboardingController())
    }
}
