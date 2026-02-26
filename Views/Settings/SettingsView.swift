//
//  SettingsView.swift
//  Club Ralley
//
//  Main settings screen
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var viewModel = SettingsViewModel.shared
    @ObservedObject private var storeManager = StoreManager.shared
    @State private var isRestoringPurchases = false
    @State private var showRestoreAlert = false
    @State private var restoreAlertMessage = ""

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
                // Scrollable content with title inside
                ScrollView {
                        VStack(spacing: AppTheme.Spacing.xl) {
                            // Settings title
                            HStack {
                                Text("settings")
                                    .font(.custom("Satoshi-Bold", size: 34))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.top, 10)
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
