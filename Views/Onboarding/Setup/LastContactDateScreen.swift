//
//  LastContactDateScreen.swift
//  Club Ralley
//
//  Allows user to set when they last contacted him
//

import SwiftUI

struct LastContactDateScreen: View {
    @EnvironmentObject var flowController: OnboardingFlowController
    @State private var lastContactDate: Date = Date()
    @State private var showDatePicker = false

    var body: some View {
        ZStack {
            OnboardingGradientBackground(style: .roseGlow, animated: true)

            OnboardingScrollableLayout(
                showBackButton: true,
                showContinueButton: true,
                backgroundColor: .clear
            ) {
                VStack(spacing: AppTheme.Spacing.xl) {
                    Spacer()
                        .frame(height: 40)

                    // Title
                    Text("when did you last\ncontact him?")
                        .font(.custom("Satoshi-Bold", size: 32))
                        .foregroundColor(Color(hex: "#4A2040"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("this starts your no-contact timer")
                        .font(.custom("Satoshi-Medium", size: 16))
                        .foregroundColor(Color(hex: "#6A3060").opacity(0.8))

                    Spacer()
                        .frame(height: 20)

                    // Date display button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        showDatePicker = true
                    }) {
                        VStack(spacing: 8) {
                            Text(formattedDate)
                                .font(.custom("Satoshi-Black", size: 28))
                                .foregroundColor(Color(hex: "#4A2040"))

                            Text("tap to change")
                                .font(.custom("Satoshi-Regular", size: 14))
                                .foregroundColor(Color(hex: "#6A3060").opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "#E080C0").opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    Spacer()
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
            } continueAction: {
                // Save the date
                flowController.saveData(for: "last_contact_date", data: [
                    "date": lastContactDate.timeIntervalSince1970,
                    "timestamp": Date().timeIntervalSince1970
                ])

                // Also save to UserDefaults for immediate use
                UserDefaults.standard.set(lastContactDate, forKey: "streak_started_at")

                // Save to database
                Task {
                    await saveToDatabase()
                }

                flowController.navigateNext()
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                selectedDate: $lastContactDate,
                isPresented: $showDatePicker
            )
        }
        .onAppear {
            // Pre-populate from breakup_timing if available
            if let timingData = flowController.getData(for: "breakup_timing"),
               let timing = timingData["timing"] as? String {
                lastContactDate = dateFromTiming(timing)
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: lastContactDate)
    }

    private func dateFromTiming(_ timing: String) -> Date {
        let calendar = Calendar.current
        switch timing {
        case "just_happened":
            return calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        case "still_fresh":
            return calendar.date(byAdding: .day, value: -21, to: Date()) ?? Date()
        case "a_little_while":
            return calendar.date(byAdding: .day, value: -60, to: Date()) ?? Date()
        case "longer":
            return calendar.date(byAdding: .day, value: -120, to: Date()) ?? Date()
        default:
            return Date()
        }
    }

    private func saveToDatabase() async {
        guard let userId = AuthenticationService.shared.currentSession?.userId else { return }

        do {
            try await SupabaseClientManager.shared.database
                .from("user_analytics_live")
                .update(["streak_started_at": ISO8601DateFormatter().string(from: lastContactDate)])
                .eq("user_id", value: userId)
                .execute()
        } catch {
            print("Failed to save streak_started_at: \(error)")
        }
    }
}

// MARK: - Date Picker Sheet

private struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Last Contact",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()

                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct LastContactDateScreen_Previews: PreviewProvider {
    static var previews: some View {
        LastContactDateScreen()
            .environmentObject(OnboardingFlowController())
    }
}
