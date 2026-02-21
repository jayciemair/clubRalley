//
//  NameInputScreen.swift
//  Club Ralley
//
//  Asks for the user's name - "What should I call you?"
//

import SwiftUI

struct NameInputScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController
    @State private var nameText: String = ""
    @State private var hasInteracted: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ZStack {
            OnboardingGradientBackground(style: .roseGlow, animated: true)

            OnboardingScrollableLayout(
                showBackButton: true,
                showContinueButton: !nameText.trimmingCharacters(in: .whitespaces).isEmpty,
                backgroundColor: .clear
            ) {
                VStack(spacing: 0) {
                    // Question
                    VStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                        Text("What should I call you?")
                            .font(.custom("Satoshi-Bold", size: 32))
                            .foregroundColor(Color(hex: "#4A2040"))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, AppTheme.Spacing.xl)
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    VStack(spacing: AppTheme.Spacing.xl) {
                        Spacer()

                        // Text input container
                        VStack(spacing: AppTheme.Spacing.md) {
                            TextField("Your name", text: $nameText)
                                .font(.custom("Satoshi-Bold", size: 36))
                                .foregroundColor(Color(hex: "#4A2040"))
                                .multilineTextAlignment(.center)
                                .focused($isTextFieldFocused)
                                .onChange(of: nameText) { _, newValue in
                                    // Limit to 30 characters
                                    if newValue.count > 30 {
                                        nameText = String(newValue.prefix(30))
                                    }

                                    if !hasInteracted && !nameText.isEmpty {
                                        hasInteracted = true
                                    }
                                }
                                .padding(.horizontal, AppTheme.Spacing.lg)
                                .padding(.vertical, AppTheme.Spacing.xl)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white.opacity(0.5))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(isTextFieldFocused ? Color(hex: "#E080C0") : Color.white.opacity(0.3), lineWidth: 2)
                                )
                        }
                        .padding(.horizontal, AppTheme.Spacing.xl)

                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = false
                }
            } continueAction: {
                let trimmedName = nameText.trimmingCharacters(in: .whitespaces)
                if !trimmedName.isEmpty {
                    flowController.saveData(for: "user_name", data: [
                        "name": trimmedName,
                        "timestamp": Date().timeIntervalSince1970
                    ])
                    flowController.navigateNext()
                }
            }
        }
        .onAppear {
            // Restore saved name if exists
            if let data = flowController.getData(for: "user_name"),
               let savedName = data["name"] as? String {
                nameText = savedName
                hasInteracted = true
            } else {
                // Auto-focus text field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
    }
}

struct NameInputScreen_Previews: PreviewProvider {
    static var previews: some View {
        NameInputScreen()
            .environmentObject(OnboardingFlowController())
    }
}
