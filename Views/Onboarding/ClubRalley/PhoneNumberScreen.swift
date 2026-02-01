//
//  PhoneNumberScreen.swift
//  Club Ralley
//
//  Onboarding screen for phone number entry (Figma design)
//

import SwiftUI

struct PhoneNumberScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController

    @State private var phoneNumber = ""
    @State private var showVerification = false
    @State private var verificationCode = ""
    @State private var isCodeSent = false
    @FocusState private var isPhoneFocused: Bool

    var body: some View {
        ClubRalleyScrollableLayout(
            canGoBack: controller.canGoBack,
            onBack: { controller.goToPreviousStep() },
            onContinue: { handleContinue() },
            continueEnabled: canContinue,
            continueText: "Submit"
        ) {
            VStack(spacing: 32) {
                ClubRalleyOnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: nil
                )

                VStack(spacing: 24) {
                    // Phone number input with country code
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            // Country code dropdown
                            HStack(spacing: 4) {
                                Text("+1")
                                    .font(.system(size: 18))
                                    .foregroundColor(.black)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 12)
                            .padding(.trailing, 12)

                            // Vertical divider
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 1, height: 24)

                            // Phone number field
                            TextField("Phone number", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .font(.system(size: 18))
                                .focused($isPhoneFocused)
                                .onChange(of: phoneNumber) { _, newValue in
                                    phoneNumber = formatPhoneNumber(newValue)
                                    controller.updatePhoneNumber(newValue)
                                }
                        }
                        .padding(.vertical, 4)

                        // Underline
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }

                    // Verification code section (shown after code sent)
                    if isCodeSent {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Verification Code")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            RalleyUnderlinedTextField(
                                placeholder: "Enter 6-digit code",
                                text: $verificationCode,
                                keyboardType: .numberPad
                            )

                            Button(action: { Task { await resendCode() } }) {
                                Text("Didn't receive code? Resend")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#2C4F40"))
                            }
                            .padding(.top, 8)
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Privacy note with links
                VStack(spacing: 4) {
                    Text("By continuing, you agree to our")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    HStack(spacing: 4) {
                        Button(action: {}) {
                            Text("Privacy Policy")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "#2C4F40"))
                                .underline()
                        }
                        Text("and")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Button(action: {}) {
                            Text("Terms of Service")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "#2C4F40"))
                                .underline()
                        }
                    }
                }
                .padding(.horizontal, 32)
            }
            .padding(.top, 20)
        }
        .onAppear {
            phoneNumber = controller.onboardingData.profile.phoneNumber
            isPhoneFocused = true
        }
    }

    // MARK: - Computed Properties

    private var canContinue: Bool {
        if isCodeSent {
            return verificationCode.count == 6
        }
        return phoneNumber.filter { $0.isNumber }.count >= 10
    }

    // MARK: - Actions

    private func handleContinue() {
        if isCodeSent {
            Task {
                if await controller.verifyPhoneCode(verificationCode) {
                    controller.goToNextStep()
                }
            }
        } else {
            Task {
                if await controller.sendVerificationCode() {
                    withAnimation {
                        isCodeSent = true
                    }
                }
            }
        }
    }

    private func resendCode() async {
        _ = await controller.sendVerificationCode()
    }

    // MARK: - Helpers

    private func formatPhoneNumber(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        let limitedDigits = String(digits.prefix(10))

        var formatted = ""
        for (index, digit) in limitedDigits.enumerated() {
            if index == 0 {
                formatted += "("
            }
            if index == 3 {
                formatted += ") "
            }
            if index == 6 {
                formatted += "-"
            }
            formatted += String(digit)
        }
        return formatted
    }
}

struct PhoneNumberScreen_Previews: PreviewProvider {
    static var previews: some View {
        PhoneNumberScreen()
            .environmentObject(ClubRalleyOnboardingController())
    }
}
