//
//  SettingsView.swift
//  Checkpoint
//
//  Main settings screen
//

import SwiftUI

// Import V3 test view (only for DEBUG builds)
#if DEBUG
// Note: FamilyPickerTestView is in FamilyControlsV3/FamilyPicker.swift
#endif

struct SettingsView: View {
    @ObservedObject private var viewModel = SettingsViewModel.shared
    @StateObject private var appearanceManager = AppearanceManager.shared
    @StateObject private var storeManager = StoreManager.shared
    @State private var isRestoringPurchases = false
    @State private var showRestoreAlert = false
    @State private var restoreAlertMessage = ""
    @State private var showLastContactDatePicker = false
    @State private var lastContactDate: Date = UserDefaults.standard.object(forKey: "no_contact_start_date") as? Date ?? Date()

    #if DEBUG
    @State private var showPaywallTesting = false
    #endif

    // Helper functions for appearance mode UI
    private func iconForMode(_ mode: AppearanceMode) -> String {
        switch mode {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }

    private func descriptionForMode(_ mode: AppearanceMode) -> String {
        switch mode {
        case .light:
            return "light mode for mochi & text him"
        case .dark:
            return "dark mode for mochi & text him"
        }
    }

    private var formattedLastContactDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: lastContactDate)
    }

    private func saveLastContactDate() {
        print("📅 [Settings] Saving last contact date: \(lastContactDate)")
        UserDefaults.standard.set(lastContactDate, forKey: "no_contact_start_date")

        // Refresh the dashboard to pick up the new date
        DashboardViewModel.shared.loadNoContactStartDate()
        print("📅 [Settings] Dashboard reloaded with new date")
    }

    var body: some View {
        ZStack {
            // Pink gradient background
            LinearGradient(
                colors: [
                    Color(hex: "#F8C8DC"),
                    Color(hex: "#F0A0C0"),
                    Color(hex: "#E890B8")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Universal header
//                    UniversalHeader()
//                        .padding(.top, 10) // Minimal padding from top

                // Scrollable content with title inside
                ScrollView {
                        VStack(spacing: AppTheme.Spacing.xl) {
                            // Settings title - now inside ScrollView so it scrolls
                            HStack {
                                Text("settings")
                                    .font(.custom("Satoshi-Bold", size: 34))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.top, 10) // Match Analytics spacing
                            .padding(.bottom, AppTheme.Spacing.md)
                            

                            // Support Us & Feedback Section
                            SettingsSection(title: "support us & feedback") {
                                VStack(spacing: AppTheme.Spacing.sm) {
                                    // I'm in a good mood - rating
                                    Button(action: {
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                        viewModel.showRatingRequestSheet = true
                                    }) {
                                        HStack {
                                            Image(systemName: "hand.thumbsup.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(Color(hex: "#E080C0"))
                                                .frame(width: 32, height: 32)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("i'm in a good mood")
                                                    .font(.custom("Satoshi-Regular", size: 17))
                                                    .foregroundColor(Color(hex: "#4A2040"))

                                                Text("leave a review and help others move on")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                                            }

                                            Spacer()
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 20)
                                        .background(Color.white.opacity(0.6))
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, 20)

                                    // Request Feature
                                    Button(action: {
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                        viewModel.showFeatureRequest = true
                                    }) {
                                        HStack {
                                            Image(systemName: "lightbulb.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(Color(hex: "#E080C0"))
                                                .frame(width: 32, height: 32)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("request feature")
                                                    .font(.custom("Satoshi-Regular", size: 17))
                                                    .foregroundColor(Color(hex: "#4A2040"))

                                                Text("share your ideas with us")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(Color(hex: "#6A3060").opacity(0.5))
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 20)
                                        .background(Color.white.opacity(0.6))
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, 20)
                                }
                            }

                            // Chat Appearance Section
                            SettingsSection(title: "chat appearance") {
                                VStack(spacing: 12) {
                                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                        Button(action: {
                                            let impact = UIImpactFeedbackGenerator(style: .light)
                                            impact.impactOccurred()
                                            appearanceManager.appearanceMode = mode
                                        }) {
                                            HStack {
                                                Image(systemName: iconForMode(mode))
                                                    .font(.system(size: 20))
                                                    .foregroundColor(Color(hex: "#E080C0"))
                                                    .frame(width: 32, height: 32)

                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(mode.rawValue.lowercased())
                                                        .font(.custom("Satoshi-Regular", size: 17))
                                                        .foregroundColor(Color(hex: "#4A2040"))

                                                    Text(descriptionForMode(mode).lowercased())
                                                        .font(.system(size: 14))
                                                        .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                                                }

                                                Spacer()

                                                if appearanceManager.appearanceMode == mode {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 20))
                                                        .foregroundColor(Color(hex: "#E080C0"))
                                                }
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 20)
                                            .background(Color.white.opacity(0.6))
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }

                            // Your Journey Section
                            SettingsSection(title: "your journey") {
                                Button(action: {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    showLastContactDatePicker = true
                                }) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 24))
                                            .foregroundColor(Color(hex: "#E080C0"))
                                            .frame(width: 32, height: 32)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("last contact date")
                                                .font(.custom("Satoshi-Regular", size: 17))
                                                .foregroundColor(Color(hex: "#4A2040"))

                                            Text(formattedLastContactDate)
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(hex: "#6A3060").opacity(0.5))
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(Color.white.opacity(0.6))
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, 20)
                            }

                            // Purchases Section
                            SettingsSection(title: "purchases") {
                                Button(action: {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    Task {
                                        isRestoringPurchases = true
                                        await storeManager.restorePurchases()
                                        isRestoringPurchases = false
                                        restoreAlertMessage = "purchases restored successfully"
                                        showRestoreAlert = true
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color(hex: "#E080C0"))
                                            .frame(width: 32, height: 32)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("restore purchases")
                                                .font(.custom("Satoshi-Regular", size: 17))
                                                .foregroundColor(Color(hex: "#4A2040"))

                                            Text("recover previous subscriptions")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(hex: "#6A3060").opacity(0.7))
                                        }

                                        Spacer()

                                        if isRestoringPurchases {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#E080C0")))
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(Color.white.opacity(0.6))
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(isRestoringPurchases)
                                .padding(.horizontal, 20)
                            }

                            SettingsSection(title: "legal & support") {
                                AccountSupportSection()
                            }

                            // Account Management - only for authenticated users
                            if viewModel.isAuthenticated {
                                SettingsSection(title: "account") {
                                    AccountManagementButton()
                                }
                            }

                            // DEBUG: Development Tools (commented out for production)
                            // #if DEBUG
                            // SettingsSection(title: "🔧 DEBUG") {
                            //     VStack(spacing: 12) {
                            //         Button(action: {
                            //             DailyCheckInManager.shared.debugTriggerCheckIn()
                            //         }) {
                            //             Text("Test Daily Check-In")
                            //         }
                            //     }
                            // }
                            // #endif

                            // Create Account Button - Only show for anonymous users
                            // TODO: Uncomment when ready to implement account creation for anonymous users
                            /*
                            if !viewModel.isAuthenticated {
                                Button(action: {
                                    // TODO: Navigate to sign up flow
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "person.badge.plus")
                                            .font(.system(size: 20))
                                        Text("Create Account")
                                            .font(.custom("Satoshi-Medium", size: 17))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.primary.opacity(0.2))
                                    .cornerRadius(AppTheme.Radius.small)
                                }
                                .padding(.horizontal, AppTheme.Spacing.lg)
                                .padding(.top, AppTheme.Spacing.xl)
                            }
                            */
                            
                            // App version
                            Text("app version: \(Bundle.main.appVersion) (build \(Bundle.main.buildNumber))")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.Colors.textSecondary.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.top, AppTheme.Spacing.xl)

                            // Bottom padding for tab bar
                            Color.clear
                                .frame(height: 100)
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $viewModel.showFeatureRequest) {
            FeatureRequestView(isPresented: $viewModel.showFeatureRequest)
        }
        .fullScreenCover(isPresented: $viewModel.showEditAccountabilityAnchors) {
            EditAccountabilityAnchorsView()
        }
        .fullScreenCover(isPresented: $viewModel.showEditRecoveryGoals) {
            EditRecoveryGoalsView()
        }
        .sheet(isPresented: $viewModel.showRatingRequestSheet) {
            RatingRequestSheet(
                isPresented: $viewModel.showRatingRequestSheet,
                onAccept: {
                    viewModel.showRatingCelebration = true
                }
            )
        }
        .alert("restore purchases", isPresented: $showRestoreAlert) {
            Button("ok", role: .cancel) {}
        } message: {
            Text(restoreAlertMessage)
        }
        .sheet(isPresented: $showLastContactDatePicker) {
            LastContactDatePickerSheet(
                selectedDate: $lastContactDate,
                isPresented: $showLastContactDatePicker,
                onSave: saveLastContactDate
            )
        }
        // #if DEBUG
        // .sheet(isPresented: $showPaywallTesting) {
        //     PaywallTestingView()
        // }
        // #endif
    }
}

// MARK: - Last Contact Date Picker Sheet

private struct LastContactDatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let onSave: () -> Void

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
            .navigationTitle("Last Contact Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onSave()
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

// MARK: - Bundle Extension

private extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }
}
