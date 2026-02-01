//
//  BirthdayScreen.swift
//  Club Ralley
//
//  Onboarding screen for birthday selection
//

import SwiftUI

struct BirthdayScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController

    @State private var birthday: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var hasSelectedDate = false

    // Date range: 13 years old minimum, 120 years max
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let maxDate = calendar.date(byAdding: .year, value: -13, to: Date()) ?? Date()
        let minDate = calendar.date(byAdding: .year, value: -120, to: Date()) ?? Date()
        return minDate...maxDate
    }

    var body: some View {
        ClubRalleyScrollableLayout(
            canGoBack: controller.canGoBack,
            onBack: { controller.goToPreviousStep() },
            onContinue: { saveAndContinue() },
            continueEnabled: hasSelectedDate && controller.isValidAge
        ) {
            VStack(spacing: 32) {
                ClubRalleyOnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: controller.currentStep.subtitle
                )

                // Birthday display
                VStack(spacing: 16) {
                    // Age display
                    if hasSelectedDate, let age = controller.age {
                        HStack(spacing: 8) {
                            Image(systemName: "birthday.cake.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "#2C4F40"))

                            Text("You'll be \(age) years old")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#2C4F40").opacity(0.1))
                        .cornerRadius(12)
                    }

                    // Date picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select your birthday")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        DatePicker(
                            "",
                            selection: $birthday,
                            in: dateRange,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .onChange(of: birthday) { _, newValue in
                            hasSelectedDate = true
                            controller.updateBirthday(newValue)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                // Age requirement note
                VStack(spacing: 8) {
                    if hasSelectedDate && !controller.isValidAge {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("You must be at least 13 years old to use Club Ralley")
                                .font(.system(size: 13))
                                .foregroundColor(.orange)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text("Your birthday is private and won't be shown publicly")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
        }
        .onAppear {
            if let existingBirthday = controller.onboardingData.profile.birthday {
                birthday = existingBirthday
                hasSelectedDate = true
            }
        }
    }

    // MARK: - Actions

    private func saveAndContinue() {
        controller.updateBirthday(birthday)
        controller.goToNextStep()
    }
}
