//
//  ClubRalleyOnboardingLayout.swift
//  Club Ralley
//
//  Reusable scrollable layout wrapper for Club Ralley onboarding screens
//

import SwiftUI

struct ClubRalleyScrollableLayout<Content: View>: View {
    let canGoBack: Bool
    let onBack: (() -> Void)?
    let onContinue: () -> Void
    let continueEnabled: Bool
    let continueText: String
    let content: Content

    init(
        canGoBack: Bool = true,
        onBack: (() -> Void)? = nil,
        onContinue: @escaping () -> Void,
        continueEnabled: Bool = true,
        continueText: String = "Submit",
        @ViewBuilder content: () -> Content
    ) {
        self.canGoBack = canGoBack
        self.onBack = onBack
        self.onContinue = onContinue
        self.continueEnabled = continueEnabled
        self.continueText = continueText
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Background - white per Figma
            Color.white
                .ignoresSafeArea()

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Back button
                        if canGoBack {
                            HStack {
                                Button(action: { onBack?() }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                        }

                        // Custom content
                        content

                        // Bottom padding for continue button
                        Color.clear
                            .frame(height: 120)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }

            // Floating continue button
            VStack {
                Spacer()

                Button(action: onContinue) {
                    Text(continueText)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            continueEnabled
                                ? Color(hex: "#2C4F40")
                                : Color(hex: "#2C4F40").opacity(0.4)
                        )
                        .cornerRadius(30)
                }
                .disabled(!continueEnabled)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0), Color.white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 120)
                    .allowsHitTesting(false)
                )
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Club Ralley Onboarding Header

struct ClubRalleyOnboardingHeader: View {
    let title: String
    let subtitle: String?

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                .multilineTextAlignment(.center)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }
}

// MARK: - Underlined Text Field (Figma Style)

struct RalleyUnderlinedTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .never
    var isValid: Bool? = nil
    var prefix: String? = nil
    var isFocused: FocusState<Bool>.Binding?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                if let prefix = prefix {
                    Text(prefix)
                        .font(.system(size: 18))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                }

                TextField(placeholder, text: $text)
                    .font(.system(size: 18))
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled()

                if let valid = isValid {
                    Image(systemName: valid ? "checkmark" : "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(valid ? Color(hex: "#2C4F40") : .red)
                }
            }
            .padding(.vertical, 12)

            // Underline
            Rectangle()
                .fill(underlineColor)
                .frame(height: 1)
        }
    }

    private var underlineColor: Color {
        if let valid = isValid {
            return valid ? Color(hex: "#2C4F40") : .red
        }
        return Color.gray.opacity(0.3)
    }
}

// MARK: - Underlined Secure Field

struct RalleyUnderlinedSecureField: View {
    let placeholder: String
    @Binding var text: String
    @State private var showPassword = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Group {
                    if showPassword {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .font(.system(size: 18))
                .textContentType(.newPassword)

                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 12)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }
}

// MARK: - Continue Button Component

struct ContinueButton: View {
    let text: String
    let enabled: Bool
    let action: () -> Void

    init(
        text: String = "Continue",
        enabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.enabled = enabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    enabled
                        ? Color(hex: "#2C4F40")
                        : Color.gray.opacity(0.4)
                )
                .cornerRadius(12)
        }
        .disabled(!enabled)
    }
}
