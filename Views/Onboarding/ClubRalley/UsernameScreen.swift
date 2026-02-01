//
//  UsernameScreen.swift
//  Club Ralley
//
//  Onboarding screen for username creation (Figma design)
//

import SwiftUI

struct UsernameScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController

    @State private var username = ""
    @State private var isAvailable: Bool? = nil
    @State private var isChecking = false
    @FocusState private var isUsernameFocused: Bool
    @State private var checkTask: Task<Void, Never>?

    var body: some View {
        ClubRalleyScrollableLayout(
            canGoBack: controller.canGoBack,
            onBack: { controller.goToPreviousStep() },
            onContinue: { saveAndContinue() },
            continueEnabled: canContinue
        ) {
            VStack(spacing: 32) {
                ClubRalleyOnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: controller.currentStep.subtitle
                )

                VStack(alignment: .leading, spacing: 8) {
                    // Username input with @ prefix
                    VStack(spacing: 0) {
                        HStack(spacing: 4) {
                            Text("@")
                                .font(.system(size: 18))
                                .foregroundColor(.black)

                            TextField("username", text: $username)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(size: 18))
                                .focused($isUsernameFocused)
                                .onChange(of: username) { _, newValue in
                                    handleUsernameChange(newValue)
                                }

                            Spacer()

                            // Status indicator
                            if isChecking {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if let available = isAvailable {
                                Image(systemName: available ? "checkmark" : "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(available ? Color(hex: "#2C4F40") : .red)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.vertical, 12)

                        // Underline
                        Rectangle()
                            .fill(underlineColor)
                            .frame(height: 1)
                    }

                    // Validation feedback
                    if let available = isAvailable {
                        if available {
                            Text("@\(username) is available!")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#2C4F40"))
                        } else {
                            Text("This username is taken. Try another one.")
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                        }
                    } else if !username.isEmpty && username.count < 3 {
                        Text("Username must be at least 3 characters")
                            .font(.system(size: 13))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.2), value: isAvailable)

                // Helper text
                Text("You can always change this later")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 20)
        }
        .onAppear {
            username = controller.onboardingData.profile.username
            if username.count >= 3 {
                checkAvailability(for: username)
            }
            isUsernameFocused = true
        }
        .onDisappear {
            checkTask?.cancel()
        }
    }

    // MARK: - Computed Properties

    private var canContinue: Bool {
        username.count >= 3 &&
        username.count <= 20 &&
        isValidCharacters &&
        isAvailable == true
    }

    private var isValidCharacters: Bool {
        !username.isEmpty && username.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }

    private var underlineColor: Color {
        if let available = isAvailable {
            return available ? Color(hex: "#2C4F40") : .red
        }
        return Color.gray.opacity(0.3)
    }

    // MARK: - Actions

    private func handleUsernameChange(_ newValue: String) {
        let cleaned = newValue.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }

        // Only update if different to avoid re-triggering onChange
        if cleaned != newValue {
            username = cleaned
            return // onChange will fire again with the cleaned value
        }

        controller.updateUsername(cleaned)

        // Cancel any pending check
        checkTask?.cancel()

        // Reset availability and check if valid length
        if cleaned.count >= 3 {
            isAvailable = nil
            controller.isUsernameAvailable = nil
            checkAvailability(for: cleaned)
        } else {
            isAvailable = nil
            controller.isUsernameAvailable = nil
            isChecking = false
        }
    }

    private func checkAvailability(for usernameToCheck: String) {
        checkTask = Task {
            isChecking = true

            // Debounce
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else {
                await MainActor.run { isChecking = false }
                return
            }

            let takenUsernames = ["admin", "clubralley", "test", "user", "athlete", "ralley"]
            let available = !takenUsernames.contains(usernameToCheck.lowercased())

            await MainActor.run {
                isChecking = false
                isAvailable = available
                // Also update controller so goToNextStep() works
                controller.isUsernameAvailable = available
            }
        }
    }

    private func saveAndContinue() {
        controller.updateUsername(username)
        controller.goToNextStep()
    }
}

struct UsernameScreen_Previews: PreviewProvider {
    static var previews: some View {
        UsernameScreen()
            .environmentObject(ClubRalleyOnboardingController())
    }
}
