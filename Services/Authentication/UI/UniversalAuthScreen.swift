//
//  UniversalAuthScreen.swift
//  Checkpoint
//
//  Provider-agnostic authentication screen for onboarding flow
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn

struct UniversalAuthScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController
    @StateObject private var authService = AuthenticationService.shared

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isAuthenticating = false  // Local UI state (industry standard)

    var body: some View {
        ZStack {
            // Background - pink gradient like other onboarding screens
            OnboardingGradientBackground(style: .roseGlow, animated: true)

            // Main content
            ScrollView {
                VStack(spacing: 0) {
                    // Title Section
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("create your account")
                            .font(.custom("Satoshi-Bold", size: 36))
                            .foregroundColor(Color(hex: "#4A2040"))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("sign in to save your progress and continue your journey")
                            .font(.custom("Satoshi-Medium", size: 18))
                            .foregroundColor(Color(hex: "#6A3060").opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    Spacer()
                        .frame(minHeight: 20)

                    // Mochi mascot
                    Image("Mochi")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .padding(.vertical, 20)

                    Spacer()
                        .frame(minHeight: 40)

                    // Authentication Buttons
                    VStack(spacing: AppTheme.Spacing.md) {
                        // Google Sign In Button (now first)
                        Button(action: {
                            handleGoogleSignIn()
                        }) {
                            HStack(spacing: 12) {
                                Image("GoogleIcon")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 20, height: 20)

                                Text("Sign in with Google")
                                    .font(.custom("Satoshi-Bold", size: 18))
                                    .tracking(0.3)
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                        }
                        .disabled(isAuthenticating)  // Use local state to prevent double-click

                        // Apple Sign In Button (now second)
                        SignInWithAppleButton(.signIn) { request in
                            handleAppleSignInRequest(request)
                        } onCompletion: { result in
                            handleAppleSignInCompletion(result)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 56)
                        .cornerRadius(AppTheme.Radius.medium)
                        .allowsHitTesting(!isAuthenticating)  // Prevent interaction during auth

                        // Legal agreement text
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Text("by creating an account, you agree to our")
                                    .font(.custom("Satoshi-Regular", size: 12))
                                    .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                            }

                            HStack(spacing: 4) {
                                Link("terms of service", destination: URL(string: AppLinks.Website.termsOfService)!)
                                    .font(.custom("Satoshi-Medium", size: 12))
                                    .foregroundColor(Color(hex: "#4A2040"))

                                Text("and")
                                    .font(.custom("Satoshi-Regular", size: 12))
                                    .foregroundColor(Color(hex: "#6A3060").opacity(0.7))

                                Link("privacy policy", destination: URL(string: AppLinks.Website.privacyPolicy)!)
                                    .font(.custom("Satoshi-Medium", size: 12))
                                    .foregroundColor(Color(hex: "#4A2040"))
                            }
                        }
                        .padding(.top, AppTheme.Spacing.md)
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.xl)
                }
                .frame(minHeight: UIScreen.main.bounds.height - 100)
            }
            .scrollIndicators(.hidden)
         
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK") {
                showError = false
                authService.clearError()
            }
        } message: {
            Text(errorMessage)
        }
        .overlay(
            Group {
                if isAuthenticating {  // Use local state for loading overlay
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()

                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                        Text("Signing you in...")
                            .font(.custom("Satoshi-Medium", size: 16))
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .fill(Color.black.opacity(0.8))
                    )
                }
            }
        )
        .onChange(of: authService.authState) { newState in
            if case .authenticated = newState {
                handleSuccessfulAuth()
            }
        }
        .onChange(of: authService.currentError) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    // MARK: - Apple Sign In

    private func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    private func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            print("[debugAuth] 🍎 Apple sign in authorized")
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Set loading state BEFORE async work starts
                print("[debugAuth] 🔄 Setting isAuthenticating = true")
                isAuthenticating = true

                Task {
                    do {
                        // Get the identity token
                        guard let identityToken = appleIDCredential.identityToken,
                              let tokenString = String(data: identityToken, encoding: .utf8) else {
                            print("[debugAuth] ❌ No identity token from Apple")
                            throw CheckpointAuthError.invalidCredentials
                        }

                        print("[debugAuth] ✅ Got Apple ID token, calling authService.signInWithApple()")
                        // Sign in with our auth service
                        try await authService.signInWithApple(idToken: tokenString)

                        // Save name if provided (only on first sign-in)
                        if let fullName = appleIDCredential.fullName {
                            await saveAppleUserName(fullName: fullName)
                        }

                        print("[debugAuth] ✅ authService.signInWithApple() completed")
                        // Success - observer will handle navigation, loading cleared there
                    } catch {
                        print("[debugAuth] ❌ authService.signInWithApple() failed: \(error.localizedDescription)")
                        // Clear loading on error
                        await MainActor.run {
                            isAuthenticating = false
                            handleAuthError(error)
                        }
                    }
                }
            }

        case .failure(let error):
            // Check if user cancelled
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                print("[debugAuth] ⚠️ User cancelled Apple sign in")
                // User cancelled, don't show error
                return
            }
            print("[debugAuth] ❌ Apple sign in failed: \(error.localizedDescription)")
            handleAuthError(error)
        }
    }

    private func saveAppleUserName(fullName: PersonNameComponents) async {
        guard var profile = authService.currentProfile else { return }

        // Update profile with Apple-provided name
        profile.firstName = fullName.givenName
        profile.lastName = fullName.familyName
        profile.fullName = [fullName.givenName, fullName.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        try? await authService.updateUserProfile(profile)
    }

    // MARK: - Google Sign In

    private func handleGoogleSignIn() {
        print("[debugAuth] 🔘 handleGoogleSignIn() CALLED")

        guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
            print("[debugAuth] ❌ No presenting view controller")
            handleAuthError(CheckpointAuthError.configurationError("Could not find presenting view controller"))
            return
        }

        // Set loading state BEFORE Google SDK shows
        print("[debugAuth] 🔄 Setting isAuthenticating = true")
        isAuthenticating = true

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
            if let error = error {
                // Check if user cancelled
                if (error as NSError).code == -5 { // User cancelled
                    print("[debugAuth] ⚠️ User cancelled Google sign in")
                    // Clear loading state on cancel
                    isAuthenticating = false
                    return
                }
                print("[debugAuth] ❌ Google sign in error: \(error.localizedDescription)")
                isAuthenticating = false
                handleAuthError(error)
                return
            }

            guard let result = result,
                  let idToken = result.user.idToken?.tokenString else {
                print("[debugAuth] ❌ No ID token from Google")
                isAuthenticating = false
                handleAuthError(CheckpointAuthError.invalidCredentials)
                return
            }

            print("[debugAuth] ✅ Got Google ID token, calling authService.signInWithGoogle()")
            Task {
                do {
                    // Sign in with our auth service
                    try await authService.signInWithGoogle(
                        idToken: idToken,
                        accessToken: result.user.accessToken.tokenString
                    )
                    print("[debugAuth] ✅ authService.signInWithGoogle() completed")
                    // Success - observer will handle navigation, loading cleared there
                } catch {
                    print("[debugAuth] ❌ authService.signInWithGoogle() failed: \(error.localizedDescription)")
                    await MainActor.run {
                        isAuthenticating = false
                        handleAuthError(error)
                    }
                }
            }
        }
    }

    // MARK: - Skip Authentication

    private func skipAuthentication() {
        Task {
            await authService.continueAsAnonymous()

            // Save to flow controller
            await MainActor.run {
                flowController.saveData(for: "authentication", data: [
                    "authenticated": false,
                    "skipped": true,
                    "provider": "anonymous"
                ])

                // Navigate to next screen
                flowController.navigateNext()
            }
        }
    }

    // MARK: - Success Handler

    private func handleSuccessfulAuth() {
        print("[debugAuth] 🎉 handleSuccessfulAuth() CALLED")
        print("[debugAuth] 🎉 isAuthenticating = \(isAuthenticating)")

        // Save authentication data to flow controller
        if let session = authService.currentSession {
            print("[debugAuth] 🎉 Got session, user ID: \(session.userId)")
            flowController.saveData(for: "authentication", data: [
                "authenticated": true,
                "user_id": session.userId,
                "email": session.email ?? "",
                "provider": session.provider.rawValue
            ])

            // Sync profile data immediately (early sync for data safety)
            Task {
                print("[debugAuth] 🔄 Starting async: syncOnboardingDataToSupabase()")
                await syncOnboardingDataToSupabase(userId: session.userId)
                print("[debugAuth] ✅ syncOnboardingDataToSupabase() completed")

                // Navigate to next screen AFTER all async work completes
                await MainActor.run {
                    print("[debugAuth] ➡️ Calling flowController.navigateNext()")
                    flowController.navigateNext()

                    // Clear loading state AFTER navigation (prevents flash)
                    print("[debugAuth] 🔄 Setting isAuthenticating = false")
                    isAuthenticating = false
                    print("[debugAuth] ✅ Authentication flow complete!")
                }
            }
        } else {
            print("[debugAuth] ⚠️ No session - navigating anyway")
            // No session - just navigate
            flowController.navigateNext()
            isAuthenticating = false
        }
    }

    // MARK: - Supabase Sync

    /// Simplified sync - just create basic user record
    private func syncOnboardingDataToSupabase(userId: String) async {
        // For now, just let auth handle user creation
        // Chat messages will be stored when user actually chats
        await authService.refreshOnboardingStatus()
    }

    // MARK: - Error Handler

    private func handleAuthError(_ error: Error) {
        let authError = error as? CheckpointAuthError ?? .unknownError(error.localizedDescription)
        errorMessage = authError.localizedDescription
        showError = true
    }
}

// MARK: - Benefit Row Component

private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.green)
                .frame(width: 28, height: 28)

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

// MARK: - Preview

struct UniversalAuthScreen_Previews: PreviewProvider {
    static var previews: some View {
        UniversalAuthScreen()
            .environmentObject(OnboardingFlowController())
    }
}
