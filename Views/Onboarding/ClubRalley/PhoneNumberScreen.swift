//
//  PhoneNumberScreen.swift
//  Club Ralley
//
//  Onboarding screen for phone number entry and OTP verification.
//  Currently uses mock verification (any 6-digit code accepted).
//  TODO: Replace with real Twilio OTP when configured.
//

import SwiftUI

struct PhoneNumberScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController

    @State private var phoneNumber = ""
    @State private var selectedCountryCode = "+1"
    @State private var showOTP = false
    @State private var otpDigits: [String] = Array(repeating: "", count: 6)
    @State private var resendCooldown: Int = 0
    @State private var cooldownTimer: Timer?

    @FocusState private var isPhoneFocused: Bool
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

    var body: some View {
        ClubRalleyScrollableLayout(
            canGoBack: showOTP,
            onBack: { withAnimation { showOTP = false } },
            onContinue: { handleContinue() },
            continueEnabled: canContinue,
            continueText: showOTP ? "Verify" : "Send Code"
        ) {
            VStack(spacing: 32) {
                ClubRalleyOnboardingHeader(
                    title: showOTP ? "Enter the code" : controller.currentStep.title,
                    subtitle: showOTP ? "Code sent to \(selectedCountryCode) \(formatPhoneNumber(phoneNumber))" : controller.currentStep.subtitle
                )

                if showOTP {
                    otpInputSection
                } else {
                    phoneInputSection
                }

                Spacer()

                // Error message
                if let error = controller.error {
                    Text(error.localizedDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Privacy note (phone entry only)
                if !showOTP {
                    privacyNote
                }
            }
            .padding(.top, 20)
        }
        .onAppear {
            phoneNumber = formatPhoneNumber(controller.onboardingData.profile.phoneNumber)
            selectedCountryCode = controller.onboardingData.profile.phoneCountryCode
            isPhoneFocused = true
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
                                controller.onboardingData.profile.phoneCountryCode = code
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedCountryCode)
                                .font(.system(size: 18))
                                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
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
                            controller.onboardingData.profile.phoneNumber = newValue.filter { $0.isNumber }
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
            // 6 individual OTP digit fields
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    otpDigitField(index: index)
                }
            }
            .padding(.horizontal, 24)

            // Resend button with cooldown
            if resendCooldown > 0 {
                Text("Resend code in \(resendCooldown)s")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            } else {
                Button(action: { resendCode() }) {
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
                let filtered = newValue.filter { $0.isNumber }
                if filtered.count > 1 {
                    // Handle paste: distribute digits across fields
                    let digits = Array(filtered)
                    for i in 0..<min(digits.count, 6 - index) {
                        otpDigits[index + i] = String(digits[i])
                    }
                    focusedOTPField = min(index + digits.count, 5)
                } else {
                    otpDigits[index] = String(filtered.prefix(1))
                    if !filtered.isEmpty && index < 5 {
                        focusedOTPField = index + 1
                    }
                }
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

    // MARK: - Validation

    private var canContinue: Bool {
        if showOTP {
            return otpDigits.joined().count == 6
        }
        return phoneNumber.filter { $0.isNumber }.count >= 10
    }

    // MARK: - Actions

    private func handleContinue() {
        controller.error = nil
        if showOTP {
            // Mock verification — any 6-digit code works
            Task {
                let success = await controller.verifyPhoneCode(otpDigits.joined())
                if success && !controller.isComplete {
                    controller.goToNextStep()
                }
            }
        } else {
            // Transition to OTP entry
            startResendCooldown()
            withAnimation {
                showOTP = true
                focusedOTPField = 0
            }
        }
    }

    private func resendCode() {
        otpDigits = Array(repeating: "", count: 6)
        focusedOTPField = 0
        startResendCooldown()
    }

    private func startResendCooldown() {
        resendCooldown = 30
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if resendCooldown > 0 {
                    resendCooldown -= 1
                } else {
                    cooldownTimer?.invalidate()
                }
            }
        }
    }

    // MARK: - Helpers

    private func formatPhoneNumber(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        let limitedDigits = String(digits.prefix(10))

        var formatted = ""
        for (index, digit) in limitedDigits.enumerated() {
            if index == 0 { formatted += "(" }
            if index == 3 { formatted += ") " }
            if index == 6 { formatted += "-" }
            formatted += String(digit)
        }
        return formatted
    }
}
