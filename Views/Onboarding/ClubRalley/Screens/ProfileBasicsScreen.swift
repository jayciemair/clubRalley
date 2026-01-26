//
//  ProfileBasicsScreen.swift
//  Club Ralley
//
//  Profile basics screen for collecting name and username
//

import SwiftUI

struct ProfileBasicsScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var isCheckingUsername = false
    @State private var usernameAvailable: Bool?
    @State private var showingUsernameTaken = false
    
    var body: some View {
        OnboardingScrollableLayout {
            VStack(spacing: 32) {
                // Header
                OnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: controller.currentStep.subtitle
                )
                
                // Form fields
                VStack(spacing: 24) {
                    // First Name
                    OnboardingTextField(
                        title: "First Name",
                        placeholder: "Enter your first name",
                        text: $firstName
                    )
                    
                    // Last Name
                    OnboardingTextField(
                        title: "Last Name",
                        placeholder: "Enter your last name",
                        text: $lastName
                    )
                    
                    // Username with availability check
                    VStack(alignment: .leading, spacing: 12) {
                        OnboardingTextField(
                            title: "Username",
                            placeholder: "Choose a username",
                            text: $username
                        )
                        
                        // Username feedback
                        if !username.isEmpty {
                            HStack(spacing: 8) {
                                if isCheckingUsername {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else if let available = usernameAvailable {
                                    Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(available ? .green : .red)
                                }
                                
                                Text(usernameStatusText)
                                    .font(.caption)
                                    .foregroundColor(usernameStatusColor)
                                
                                Spacer()
                            }
                        }
                        
                        // Username guidelines
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Username guidelines:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• 3-20 characters")
                                .font(.caption)
                                .foregroundColor(username.count >= 3 && username.count <= 20 ? .green : .secondary)
                            
                            Text("• Letters, numbers, and underscores only")
                                .font(.caption)
                                .foregroundColor(isValidUsernameFormat ? .green : .secondary)
                        }
                        .padding(.leading, 16)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Continue button
                ContinueButton(
                    title: "Continue",
                    isEnabled: canContinue,
                    action: {
                        saveAndContinue()
                    }
                )
                .padding(.horizontal, 32)
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
        .onChange(of: username) { newValue in
            // Clean the username input
            let cleaned = newValue.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
            if cleaned != newValue {
                username = cleaned
            }
            
            // Check availability after a delay
            checkUsernameAvailability()
        }
        .onAppear {
            // Pre-populate if data exists
            firstName = controller.onboardingData.profile.firstName
            lastName = controller.onboardingData.profile.lastName
            username = controller.onboardingData.profile.username
        }
    }
    
    private var canContinue: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        isValidUsernameFormat &&
        usernameAvailable == true &&
        !isCheckingUsername
    }
    
    private var isValidUsernameFormat: Bool {
        username.count >= 3 &&
        username.count <= 20 &&
        username.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }
    
    private var usernameStatusText: String {
        if isCheckingUsername {
            return "Checking availability..."
        } else if let available = usernameAvailable {
            return available ? "Username available!" : "Username already taken"
        } else {
            return ""
        }
    }
    
    private var usernameStatusColor: Color {
        if isCheckingUsername {
            return .secondary
        } else if let available = usernameAvailable {
            return available ? .green : .red
        } else {
            return .secondary
        }
    }
    
    private func checkUsernameAvailability() {
        guard isValidUsernameFormat else {
            usernameAvailable = nil
            return
        }
        
        isCheckingUsername = true
        usernameAvailable = nil
        
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 second debounce
            
            let available = await controller.validateUsername(username)
            
            await MainActor.run {
                isCheckingUsername = false
                usernameAvailable = available
            }
        }
    }
    
    private func saveAndContinue() {
        controller.updateProfileBasics(
            firstName: firstName,
            lastName: lastName,
            username: username,
            email: controller.onboardingData.profile.email
        )
        controller.goToNextStep()
    }
}

// MARK: - Onboarding Text Field Component

struct OnboardingTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words
    var isSecure = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(autocapitalization)
                }
            }
            .textFieldStyle(OnboardingTextFieldStyle())
        }
    }
}

struct OnboardingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .cornerRadius(12)
    }
}

// MARK: - Continue Button Component

struct ContinueButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    isEnabled
                        ? LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Preview

struct ProfileBasicsScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileBasicsScreen()
                .environmentObject(ClubRalleyOnboardingController())
        }
    }
}