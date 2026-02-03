//
//  ForgotPasswordView.swift
//  Club Ralley
//
//  Password reset flow for users who forgot their password
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let supabase = SupabaseManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Email Input
                    emailInputSection

                    // Submit Button
                    submitButton

                    // Back to Login
                    backToLoginButton

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
            }
            .background(Color(hex: "#F5F5F5"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred. Please try again.")
            }
            .sheet(isPresented: $showSuccess) {
                PasswordResetSuccessView(email: email) {
                    showSuccess = false
                    dismiss()
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.rotation")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#2C4F40"))

            Text("Forgot Password?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)

            Text("No worries! Enter your email address and we'll send you a link to reset your password.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Email Input Section

    private var emailInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email Address")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)

            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)

                TextField("Enter your email", text: $email)
                    .font(.system(size: 16))
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button(action: { Task { await sendResetEmail() } }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                }
                Text(isLoading ? "Sending..." : "Send Reset Link")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#2C4F40"), Color(hex: "#3A6B4F")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color(hex: "#2C4F40").opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading || !isValidEmail)
        .opacity(isValidEmail ? 1.0 : 0.6)
    }

    // MARK: - Back to Login Button

    private var backToLoginButton: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 14, weight: .medium))
                Text("Back to Sign In")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(Color(hex: "#2C4F40"))
        }
    }

    // MARK: - Helpers

    private var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func sendResetEmail() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.resetPassword(email: email)
            await MainActor.run {
                isLoading = false
                showSuccess = true
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to send reset email. Please check your email address and try again."
                showError = true
            }
        }
    }
}

// MARK: - Password Reset Success View

struct PasswordResetSuccessView: View {
    let email: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "#2C4F40").opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }

            // Success Message
            VStack(spacing: 12) {
                Text("Check Your Email")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)

                Text("We've sent a password reset link to:")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)

                Text(email)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#2C4F40"))

                Text("Click the link in the email to reset your password. If you don't see the email, check your spam folder.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Done Button
            Button(action: onDismiss) {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#2C4F40"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(hex: "#F5F5F5"))
    }
}

// MARK: - Preview

#Preview {
    ForgotPasswordView()
}
