//
//  ContactsAccessScreen.swift
//  Club Ralley
//
//  Onboarding screen for contacts access (Figma design)
//

import SwiftUI
import Contacts

struct ContactsAccessScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController

    @State private var isRequesting = false
    @State private var accessGranted: Bool?

    var body: some View {
        ClubRalleyScrollableLayout(
            canGoBack: controller.canGoBack,
            onBack: { controller.goToPreviousStep() },
            onContinue: { saveAndContinue() },
            continueEnabled: true,
            continueText: accessGranted == true ? "Submit" : "Skip"
        ) {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 40)

                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "#2C4F40").opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "person.2.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }

                // Header
                VStack(spacing: 12) {
                    Text(controller.currentStep.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                // Benefits list
                VStack(alignment: .leading, spacing: 20) {
                    ContactBenefitRow(
                        icon: "person.badge.plus",
                        title: "Find friends instantly",
                        description: "See which of your contacts are already on Ralley"
                    )

                    ContactBenefitRow(
                        icon: "envelope.fill",
                        title: "Invite others to rally",
                        description: "Easily invite friends who haven't joined yet"
                    )

                    ContactBenefitRow(
                        icon: "figure.run",
                        title: "Rally together",
                        description: "Start playing with people you know"
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // Action section
                VStack(spacing: 16) {
                    if accessGranted == true {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#2C4F40"))
                            Text("Contacts access granted!")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#2C4F40"))
                        }
                    } else if accessGranted == false {
                        VStack(spacing: 8) {
                            Text("Access was denied")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.orange)

                            Text("You can enable this later in Settings")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    } else {
                        Button(action: { requestAccess() }) {
                            HStack(spacing: 12) {
                                if isRequesting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                Text("Allow Access to Contacts")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#2C4F40"))
                            .cornerRadius(30)
                        }
                        .disabled(isRequesting)
                        .padding(.horizontal, 24)

                        Button(action: { skipContacts() }) {
                            Text("Not now")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding(.top, 20)
        }
        .onAppear {
            checkCurrentStatus()
        }
    }

    // MARK: - Actions

    private func checkCurrentStatus() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .authorized:
            accessGranted = true
        case .denied, .restricted:
            accessGranted = false
        default:
            accessGranted = nil
        }
    }

    private func requestAccess() {
        isRequesting = true

        Task {
            let granted = await controller.requestContactsAccess()

            await MainActor.run {
                isRequesting = false
                withAnimation {
                    accessGranted = granted
                }
            }
        }
    }

    private func skipContacts() {
        controller.skipContactsAccess()
        controller.goToNextStep()
    }

    private func saveAndContinue() {
        controller.goToNextStep()
    }
}

// MARK: - Contact Benefit Row

private struct ContactBenefitRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(Color(hex: "#2C4F40"))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
    }
}

struct ContactsAccessScreen_Previews: PreviewProvider {
    static var previews: some View {
        ContactsAccessScreen()
            .environmentObject(ClubRalleyOnboardingController())
    }
}
