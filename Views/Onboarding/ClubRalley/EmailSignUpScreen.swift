//
//  EmailSignUpScreen.swift
//  Club Ralley
//
//  Onboarding screen for email/password sign-up
//

import SwiftUI

struct EmailSignUpScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password, confirmPassword
    }

    private var isReAuth: Bool { controller.isReAuthMode }

    var body: some View {
        ClubRalleyScrollableLayout(
            canGoBack: false,
            onBack: nil,
            onContinue: { isReAuth ? handleSignIn() : handleSignUp() },
            continueEnabled: canContinue,
            continueText: isReAuth ? "Sign In" : "Sign Up"
        ) {
            VStack(spacing: 32) {
                ClubRalleyOnboardingHeader(
                    title: isReAuth ? "Welcome back" : controller.currentStep.title,
                    subtitle: isReAuth ? "Sign in to continue" : controller.currentStep.subtitle
                )

                VStack(spacing: 24) {
                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        RalleyUnderlinedTextField(
                            placeholder: "your@email.com",
                            text: $email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )
                        .focused($focusedField, equals: .email)
                        .onChange(of: email) { _, newValue in
                            controller.updateEmail(newValue)
                        }
                    }

                    // Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        RalleyUnderlinedSecureField(
                            placeholder: isReAuth ? "Enter your password" : "At least 8 characters",
                            text: $password
                        )
                        .focused($focusedField, equals: .password)
                        .onChange(of: password) { _, newValue in
                            controller.onboardingData.profile.password = newValue
                        }
                    }

                    // Confirm password (sign-up only)
                    if !isReAuth {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm password")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            RalleyUnderlinedSecureField(
                                placeholder: "Re-enter password",
                                text: $confirmPassword
                            )
                            .focused($focusedField, equals: .confirmPassword)
                            .onChange(of: confirmPassword) { _, newValue in
                                controller.onboardingData.profile.confirmPassword = newValue
                            }

                            // Password mismatch hint
                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Passwords don't match")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Error message
                if let error = controller.error {
                    Text(error.localizedDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            .padding(.top, 20)
        }
        .onAppear {
            email = controller.onboardingData.profile.email
            password = controller.onboardingData.profile.password
            confirmPassword = controller.onboardingData.profile.confirmPassword
            focusedField = .email
        }
    }

    // MARK: - Validation

    private var canContinue: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        if isReAuth {
            return trimmedEmail.contains("@") &&
                   trimmedEmail.contains(".") &&
                   password.count >= 8
        }
        return trimmedEmail.contains("@") &&
               trimmedEmail.contains(".") &&
               password.count >= 8 &&
               password == confirmPassword
    }

    // MARK: - Actions

    private func handleSignUp() {
        controller.error = nil
        Task {
            let success = await controller.signUpWithEmail()
            if success && !controller.isComplete {
                controller.goToNextStep()
            }
        }
    }

    private func handleSignIn() {
        controller.error = nil
        Task {
            await controller.signInOnly()
        }
    }
}
