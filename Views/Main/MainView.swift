//
//  MainView.swift
//  Checkpoint
//
//  Created: September 26, 2025
//  Purpose: Main view for the checkpoint tab
//
//  Main architecture - Displays checkpoint status and blocking state
//

import SwiftUI
import SuperwallKit

/// Main view for the checkpoint tab
/// Displays blocking status and checkpoint verification options
struct MainView: View {

    // MARK: - Properties

    @StateObject private var goalManager = UserGoalManager.shared
    @StateObject private var authService = AuthenticationService.shared
    @ObservedObject private var dashboardViewModel = DashboardViewModel.shared
    @State private var showCheckyChat = false
    @State private var showRelapseEncouragement = false
    @AppStorage("selectedTab") private var selectedTab: MainTab = .home


    // MARK: - Body

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

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerView

                    // Main content
                    protectedView

                    // Add padding at bottom for content to not be hidden by tab bar
                    Color.clear
                        .frame(height: 120)
                }
            }
            .scrollIndicators(.hidden)
        }
        .fullScreenCover(isPresented: $showCheckyChat) {
            NavigationView {
                MochiChatView()
            }
        }
        .fullScreenCover(isPresented: $showRelapseEncouragement) {
            RelapseEncouragementView(isPresented: $showRelapseEncouragement)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            dashboardViewModel.loadNoContactStartDate()
        }
    }

    // MARK: - View Components

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("club ralley.")
                    .font(.custom("Satoshi-Bold", size: 34))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, 10)
        }
    }

    // MARK: - Protected State (Green - Thumbs Up)
    private var protectedView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Weekly streak calendar (progress tracker) - first for quick status check
            WeeklyStreakCalendar(
                relapseTimestamps: dashboardViewModel.currentWeekRelapses,
                isReloading: dashboardViewModel.isLoading,
                streakStartDate: dashboardViewModel.streakStartedAt,
                hasLoadedOnce: dashboardViewModel.hasLoadedOnce
            )
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.top, AppTheme.Spacing.md)

            // AI Chat button - Talk to Mochi (Hero Card)
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                showCheckyChat = true
            }) {
                VStack(spacing: 16) {
                    // Large Mochi image as hero
                    Image("Mochi")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)

                    // Text content centered
                    Text("talk to mochi")
                        .font(.custom("Satoshi-Bold", size: 24))
                        .foregroundColor(Color(hex: "#4A2040"))

                    // CTA pill
                    HStack(spacing: 6) {
                        Text("vent")
                            .font(.custom("Satoshi-Bold", size: 14))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(hex: "#E080C0"),
                                Color(hex: "#D070B0")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .padding(.horizontal, 24)
                .background(Color.white.opacity(0.7))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                )
                .shadow(color: Color(hex: "#E080C0").opacity(0.15), radius: 20, x: 0, y: 8)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)

            // No contact timer - shows days/hours since last contact
            NoContactTimerView(
                startDate: dashboardViewModel.streakStartedAt ?? Date(),
                onReset: {
                    Task {
                        await dashboardViewModel.resetStreak()
                        showRelapseEncouragement = true
                    }
                }
            )
            .padding(.horizontal, AppTheme.Spacing.lg)

        }
        .padding(.top, AppTheme.Spacing.md)
    }

}

// MARK: - Preview

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
