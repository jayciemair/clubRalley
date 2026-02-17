//
//  PhoneNumberScreen.swift
//  Club Ralley
//
//  Onboarding screen for phone number entry and OTP verification
//

import SwiftUI

struct PhoneNumberScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController

    @State private var phoneNumber = ""
    @State private var selectedCountryCode = "+1"
    @FocusState private var isPhoneFocused: Bool

    // OTP fields
    @State private var otpDigits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedOTPField: Int?

    private let countryCodes = [
        ("+1", "US"),
        ("+44", "UK"),
        ("+61", "AU"),
        ("+91", "IN"),
        ("+81", "JP"),
        ("+49", "DE"),
        ("+33", "FR"),
        ("+55", "BR"),
        ("+52", "MX"),
        ("+86", "CN"),
    ]

    /// True when we're on the OTP verification step
    private var isOTPStep: Bool {
        controller.currentStep == .otpVerification
    }

    var body: some View {
        ClubRalleyScrollableLayout(
            canGoBack: controller.canGoBack,
            onBack: { controller.goToPreviousStep() },
            onContinue: { handleContinue() },
            continueEnabled: canContinue,
            continueText: isOTPStep ? "Verify" : "Send Code"
        ) {
            VStack(spacing: 32) {
                ClubRalleyOnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: controller.currentStep.subtitle
                )

                if isOTPStep {
                    otpInputSection
                } else {
                    phoneInputSection
                }

                Spacer()

                // Error message
                if let error = controller.error {
                    Text(error.localizedDescription ?? "An error occurred")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Privacy note
                if !isOTPStep {
                    privacyNote
                }
            }
            .padding(.top, 20)
        }
        .onAppear {
            if isOTPStep {
                focusedOTPField = 0
            } else {
                phoneNumber = formatPhoneNumber(controller.onboardingData.profile.phoneNumber)
                selectedCountryCode = controller.onboardingData.profile.phoneCountryCode
                isPhoneFocused = true
            }
        }
        .onChange(of: controller.currentStep) { _, _ in
            controller.error = nil
        }
    }

    // MARK: - Phone Input Section

    private var phoneInputSection: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    // Country code picker
                    Menu {
                        ForEach(countryCodes, id: \.0) { code, label in
                            Button("\(code) \(label)") {
                                selectedCountryCode = code
                                controller.updatePhoneNumber(phoneNumber, countryCode: code)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedCountryCode)
                                .font(.system(size: 18))
                                .foregroundColor(.black)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 12)
                        .padding(.trailing, 12)
                    }

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
                            controller.updatePhoneNumber(newValue, countryCode: selectedCountryCode)
                        }
                }
                .padding(.vertical, 4)

                // Underline
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - OTP Input Section

    private var otpInputSection: some View {
        VStack(spacing: 24) {
            // Phone display
            Text("Code sent to \(selectedCountryCode) \(formatPhoneNumber(controller.onboardingData.profile.phoneNumber))")
                .font(.system(size: 15))
                .foregroundColor(.gray)

            // 6 individual OTP digit fields
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    otpDigitField(index: index)
                }
            }
            .padding(.horizontal, 24)

            // Resend button with cooldown
            if controller.resendCooldown > 0 {
                Text("Resend code in \(controller.resendCooldown)s")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            } else {
                Button(action: { Task { await resendCode() } }) {
                    Text("Didn't receive code? Resend")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func otpDigitField(index: Int) -> some View {
        TextField("", text: $otpDigits[index])
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 24, weight: .semibold))
            .frame(width: 48, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        focusedOTPField == index ? Color(hex: "#2C4F40") : Color.gray.opacity(0.3),
                        lineWidth: focusedOTPField == index ? 2 : 1
                    )
            )
            .focused($focusedOTPField, equals: index)
            .onChange(of: otpDigits[index]) { _, newValue in
                // Only allow single digit
                let filtered = newValue.filter { $0.isNumber }
                if filtered.count > 1 {
                    // Handle paste: distribute digits across fields
                    let digits = Array(filtered)
                    for i in 0..<min(digits.count, 6 - index) {
                        otpDigits[index + i] = String(digits[i])
                    }
                    let nextIndex = min(index + digits.count, 5)
                    focusedOTPField = nextIndex
                } else {
                    otpDigits[index] = String(filtered.prefix(1))
                    if !filtered.isEmpty && index < 5 {
                        focusedOTPField = index + 1
                    }
                }
                updateVerificationCode()
            }
    }

    // MARK: - Privacy Note

    private var privacyNote: some View {
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

    // MARK: - Computed Properties

    private var canContinue: Bool {
        if isOTPStep {
            return otpDigits.joined().count == 6
        }
        return phoneNumber.filter { $0.isNumber }.count >= 10
    }

    // MARK: - Actions

    private func handleContinue() {
        if isOTPStep {
            Task {
                let code = otpDigits.joined()
                if await controller.verifyPhoneCode(code) {
                    // If controller marked isComplete, returning user was handled
                    if !controller.isComplete {
                        controller.goToNextStep()
                    }
                }
            }
        } else {
            Task {
                if await controller.sendVerificationCode() {
                    controller.goToNextStep()
                }
            }
        }
    }

    private func resendCode() async {
        // Clear existing OTP
        otpDigits = Array(repeating: "", count: 6)
        focusedOTPField = 0
        updateVerificationCode()
        _ = await controller.sendVerificationCode()
    }

    private func updateVerificationCode() {
        controller.verificationCode = otpDigits.joined()
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
