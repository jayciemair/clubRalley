//
//  SignInSheet.swift
//  Club Ralley
//
//  Sign in form for returning users
//

import SwiftUI

struct SignInSheet: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let supabaseManager = SupabaseManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Welcome Back")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)

                    Text("Sign in to your account")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)

                // Form fields
                VStack(spacing: 16) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        TextField("Enter your email", text: $email)
                            .textFieldStyle(.plain)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }

                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(.plain)
                            .textContentType(.password)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Sign In button
                Button(action: signIn) {
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        (email.isEmpty || password.isEmpty || isLoading)
                            ? Color.gray.opacity(0.5)
                            : Color(hex: "#2C4F40")
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .disabled(email.isEmpty || password.isEmpty || isLoading)

                // Forgot password link
                Button(action: {
                    // TODO: Implement forgot password flow
                }) {
                    Text("Forgot password?")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
    }

    private func signIn() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let userId = try await supabaseManager.signIn(email: email, password: password)

                // Try to load user profile from database
                if let profile = try await supabaseManager.fetchUserProfile(userId: userId) {
                    // Save profile locally
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    if let profileData = try? encoder.encode(profile) {
                        UserDefaults.standard.set(profileData, forKey: "currentUserProfile")
                    }

                    // Update SupabaseManager with full user info
                    await MainActor.run {
                        supabaseManager.currentUser = SupabaseUser(
                            id: profile.id,
                            email: profile.email,
                            firstName: profile.firstName,
                            lastName: profile.lastName
                        )
                    }
                }

                // Mark as complete and dismiss
                UserDefaults.standard.set(true, forKey: "hasCompletedClubRalleyOnboarding")

                await MainActor.run {
                    controller.isComplete = true
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    let errorDesc = error.localizedDescription.lowercased()
                    if errorDesc.contains("invalid") || errorDesc.contains("credentials") {
                        errorMessage = "Invalid email or password"
                    } else if errorDesc.contains("not found") {
                        errorMessage = "Account not found"
                    } else {
                        errorMessage = "Unable to sign in. Please try again."
                    }
                    isLoading = false
                }
            }
        }
    }
}

struct SignInSheet_Previews: PreviewProvider {
    static var previews: some View {
        SignInSheet()
            .environmentObject(ClubRalleyOnboardingController())
    }
}
