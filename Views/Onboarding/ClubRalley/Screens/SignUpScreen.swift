//
//  SignUpScreen.swift
//  Club Ralley
//
//  Sign up screen with Google Sign In and email registration
//

import SwiftUI

struct SignUpScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingEmailSignUp = false
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        OnboardingScrollableLayout {
            VStack(spacing: 32) {
                // Header
                OnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: controller.currentStep.subtitle
                )
                
                Spacer()
                
                // Sign up options
                VStack(spacing: 20) {
                    // Google Sign In (Primary)
                    Button(action: signInWithGoogle) {
                        HStack {
                            Image(systemName: "globe")
                                .font(.headline)
                            
                            Text("Continue with Google")
                                .font(.headline)
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 1)
                    }
                    
                    // Email Sign Up
                    if showingEmailSignUp {
                        emailSignUpForm
                    } else {
                        Button(action: {
                            withAnimation {
                                showingEmailSignUp = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "envelope")
                                    .font(.headline)
                                
                                Text("Sign Up with Email")
                                    .font(.headline)
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Already have account
                Button(action: {
                    // Handle sign in for existing users
                    signInExistingUser()
                }) {
                    Text("Already have an account? **Sign In**")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    controller.goToPreviousStep()
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    @ViewBuilder
    private var emailSignUpForm: some View {
        VStack(spacing: 16) {
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email Address")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                
                SecureField("Create a password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Confirm password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                
                SecureField("Confirm your password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Password requirements
            VStack(alignment: .leading, spacing: 4) {
                Text("Password must contain:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                PasswordRequirement("At least 8 characters", isValid: password.count >= 8)
                PasswordRequirement("One uppercase letter", isValid: password.contains { $0.isUppercase })
                PasswordRequirement("One lowercase letter", isValid: password.contains { $0.isLowercase })
                PasswordRequirement("One number", isValid: password.contains { $0.isNumber })
                PasswordRequirement("Passwords match", isValid: !confirmPassword.isEmpty && password == confirmPassword)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Sign up button
            Button(action: signUpWithEmail) {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Creating Account...")
                    }
                } else {
                    Text("Create Account")
                        .font(.headline)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                (isEmailFormValid && !isLoading) 
                    ? LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(12)
            .disabled(!isEmailFormValid || isLoading)
        }
    }
    
    private var isEmailFormValid: Bool {
        controller.isValidEmail(email) &&
        controller.isValidPassword(password) &&
        password == confirmPassword
    }
    
    // MARK: - Actions
    
    private func signInWithGoogle() {
        isLoading = true
        
        Task {
            do {
                // Mock Google Sign In
                try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                // Update profile with Google data
                await MainActor.run {
                    controller.updateProfileBasics(
                        firstName: "Google",
                        lastName: "User",
                        username: "googleuser\(Int.random(in: 1000...9999))",
                        email: "user@gmail.com"
                    )
                    
                    isLoading = false
                    controller.goToNextStep()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to sign in with Google. Please try again."
                    showingError = true
                }
            }
        }
    }
    
    private func signUpWithEmail() {
        isLoading = true
        
        Task {
            do {
                // Mock email sign up
                try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                await MainActor.run {
                    controller.updateProfileBasics(
                        firstName: "",
                        lastName: "",
                        username: "",
                        email: email
                    )
                    
                    isLoading = false
                    controller.goToNextStep()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to create account. Please try again."
                    showingError = true
                }
            }
        }
    }
    
    private func signInExistingUser() {
        // Handle existing user sign in
        // This would typically show a different screen or modal
        print("Sign in existing user tapped")
    }
}

// MARK: - Password Requirement Component

struct PasswordRequirement: View {
    let text: String
    let isValid: Bool
    
    init(_ text: String, isValid: Bool) {
        self.text = text
        self.isValid = isValid
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(isValid ? .green : .secondary)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isValid ? .green : .secondary)
        }
    }
}

// MARK: - Onboarding Header Component

struct OnboardingHeader: View {
    let title: String
    let subtitle: String?
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
    }
}

// MARK: - Preview

struct SignUpScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SignUpScreen()
                .environmentObject(ClubRalleyOnboardingController())
        }
    }
}