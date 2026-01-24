//
//  ReadyStateView.swift
//  Checkpoint
//
//  View for .ready app state
//  Part of MVVM refactor - extracted from ContentView
//

import SwiftUI

struct ReadyStateView: View {
    let onAuthenticatedAppear: () -> Void

    // MARK: - Daily Check-In State

    @StateObject private var checkInManager = DailyCheckInManager.shared
    @ObservedObject private var dashboardViewModel = DashboardViewModel.shared
    @State private var showDailyCheckIn = false
    @State private var showCheckInSuccessHUD = false

    var body: some View {
        MainTabView()
            .id("mainTabViewReady")
            .onAppear {
                onAuthenticatedAppear()

                // Check if daily check-in is needed (with slight delay for smooth transition)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if checkInManager.needsCheckIn() {
                        showDailyCheckIn = true
                    }
                }

                // Schedule/refresh check-in reminder notifications for the next 7 days
                checkInManager.scheduleCheckInReminders()
            }
            .fullScreenCover(isPresented: $showDailyCheckIn) {
                DailyCheckInView(
                    isPresented: $showDailyCheckIn,
                    showSuccessConfetti: $showCheckInSuccessHUD,
                    currentStreak: dashboardViewModel.currentStreak,
                    onRelapse: {
                        // Handle relapse - simplified
                        showDailyCheckIn = false
                    }
                )
                .interactiveDismissDisabled()
            }
            .checkInSuccessHUD(
                isShowing: $showCheckInSuccessHUD,
                dayNumber: dashboardViewModel.currentStreak + 1,
                checkInStreak: checkInManager.checkInStreak
            )
            .onReceive(NotificationCenter.default.publisher(for: .showDailyCheckIn)) { _ in
                // Debug trigger for daily check-in
                showDailyCheckIn = true
            }
    }
}
