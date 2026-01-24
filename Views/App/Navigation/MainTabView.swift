//
//  MainTabView.swift
//  Checkpoint
//
//  Main tab bar component for the authenticated app experience
//

import SwiftUI

struct MainTabView: View {
    // MARK: - Properties
    @AppStorage("selectedTab") var selectedTab: Tab = .v3test
    @AppStorage("inRestrictionMode") private var inRestrictionMode = false
    @ObservedObject private var tierProgressManager = TierProgressManager.shared
    @StateObject private var appLifecycleManager = AppLifecycleManager.shared
    @StateObject private var settingsViewModel = SettingsViewModel.shared

    // MARK: - Body
    var body: some View {
        ZStack { // Overall container
            // Tab content group - Each tab wrapped in NavigationStack (industry standard)
            Group {
                GeometryReader { _ in // Re-add invisible GeometryReader to constrain content width
                    switch selectedTab {
                    case .v3test:
                        NavigationStack {
                            MainView()
                        }
                    case .analytics:
                        NavigationStack {
                            AnalyticsView()
                        }
                    case .settings:
                        NavigationStack {
                            SettingsView()
                        }
                    case .textSimulator:
                        NavigationStack {
                            TextSimulatorEntryView()
                        }
                    default:
                        EmptyView()
                    }
                }
            }

            // Custom tab bar overlay
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(.keyboard)
        .tierUnlockedHUD(
            isShowing: $tierProgressManager.showTierUnlockedHUD,
            tierName: tierProgressManager.unlockedTierName,
            daysNoContact: tierProgressManager.unlockedTierDays,
            quitDate: tierProgressManager.currentQuitDate ?? Date()
        )
        .ratingCelebrationHUD(
            isShowing: $settingsViewModel.showRatingCelebration,
            onRequestReview: {
                settingsViewModel.requestAppStoreReview()
            }
        )
        .onAppear {
            // Initialize app data on first launch
            Task {
                await appLifecycleManager.initializeOnLaunch()
            }
        }
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}