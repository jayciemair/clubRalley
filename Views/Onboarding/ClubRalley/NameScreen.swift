//
//  NameScreen.swift
//  Club Ralley
//
//  Onboarding screen for name entry (Figma design)
//

import SwiftUI

struct NameScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController

    @State private var firstName = ""
    @State private var lastName = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case firstName, lastName
    }

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

                VStack(spacing: 24) {
                    // First name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        RalleyUnderlinedTextField(
                            placeholder: "First name",
                            text: $firstName,
                            textContentType: .givenName,
                            autocapitalization: .words
                        )
                        .focused($focusedField, equals: .firstName)
                    }

                    // Last name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        RalleyUnderlinedTextField(
                            placeholder: "Last name",
                            text: $lastName,
                            textContentType: .familyName,
                            autocapitalization: .words
                        )
                        .focused($focusedField, equals: .lastName)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 20)
        }
        .onAppear {
            firstName = controller.onboardingData.profile.firstName
            lastName = controller.onboardingData.profile.lastName
            focusedField = .firstName
        }
    }

    private var canContinue: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func saveAndContinue() {
        controller.onboardingData.profile.firstName = firstName.trimmingCharacters(in: .whitespaces)
        controller.onboardingData.profile.lastName = lastName.trimmingCharacters(in: .whitespaces)
        controller.goToNextStep()
    }
}

struct NameScreen_Previews: PreviewProvider {
    static var previews: some View {
        NameScreen()
            .environmentObject(ClubRalleyOnboardingController())
    }
}
