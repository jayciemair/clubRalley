//
//  AppLifecycleManager.swift
//  Checkpoint
//
//  Coordinates app-level events and data refreshes
//

import Foundation
import SwiftUI
import Combine

/// Manages app lifecycle events and coordinates data updates
@MainActor
final class AppLifecycleManager: ObservableObject {

    // MARK: - Singleton

    static let shared = AppLifecycleManager()

    // MARK: - Dependencies

    private let dashboardDataService = DashboardDataService.shared
    private let tierProgressManager = TierProgressManager.shared
    private let authService = AuthenticationService.shared

    // MARK: - Properties

    private var cancellables = Set<AnyCancellable>()
    private var hasInitialized = false
    private var lastActiveTime: Date?

    // MARK: - Initialization

    private init() {
        setupNotificationObservers()
    }

    // MARK: - Public Methods

    /// Initialize app data on launch (call from MainTabView or AppCoordinator)
    func initializeOnLaunch() async {
        guard !hasInitialized else {
            return
        }

        // Update last_active_at in database
        await updateLastActiveTimestamp()

        // Load dashboard data first
        await dashboardDataService.loadDashboardData(force: true)

        // Signature is cached after onboarding completion - no need to fetch on every launch

        // Then check for tier unlocks (once per session)
        tierProgressManager.checkForTierUnlock()

        hasInitialized = true
        lastActiveTime = Date()
    }

    /// Handle app becoming active (returning from background)
    func handleAppBecameActive() async {
        // Update last_active_at in database
        await updateLastActiveTimestamp()

        // Reset tier session tracking (allows checking once per session)
        tierProgressManager.resetSessionTracking()

        // Check if we've entered a new day
        if dashboardDataService.hasEnteredNewDay() {
            await refreshForNewDay()
        } else if shouldRefreshOnActivation() {
            await dashboardDataService.loadDashboardData(silent: true)
        }

        lastActiveTime = Date()
    }

    /// Handle app going to background
    func handleAppWentToBackground() {
        lastActiveTime = Date()
    }

    /// Handle after onboarding completion
    func handleOnboardingComplete() async {
        print("[debugProtection] 🎓 AppLifecycleManager.handleOnboardingComplete() CALLED")

        // Force reload data to get fresh streak
        print("[debugProtection] 🎓 Reloading dashboard data...")
        await dashboardDataService.forceReload()

        // Load commitment signature (just created during onboarding)
        print("[debugProtection] 🎓 Loading commitment signature...")
        await CommitmentSignatureCache.shared.loadAndCacheSignature()

        // Force check tier to show Bronze
        print("[debugProtection] 🎓 Checking tier unlock...")
        tierProgressManager.checkForTierUnlock(force: true)

        print("[debugProtection] ✅ Onboarding post-completion tasks done")
    }

    /// Handle after relapse logged
    func handleRelapseLogged() async {
        // Reset tier tracking
        tierProgressManager.resetTierTracking()

        // Force reload dashboard data
        await dashboardDataService.forceReload()
    }

    /// Handle pull-to-refresh
    func handlePullToRefresh() async {
        // Force reload data
        await dashboardDataService.forceReload()

        // Check tier (force check even if done this session)
        tierProgressManager.checkForTierUnlock(force: true)
    }

    // MARK: - Private Methods

    /// Update last_active_at timestamp in database
    private func updateLastActiveTimestamp() async {
        guard case .authenticated(let session) = authService.authState,
              let userId = UUID(uuidString: session.userId) else {
            return
        }

        do {
            let supabase = SupabaseClientManager.shared

            struct LastActiveUpdate: Encodable {
                let last_active_at: Date
            }

            let update = LastActiveUpdate(last_active_at: Date())

            try await supabase.database
                .from("users")
                .update(update)
                .eq("id", value: userId.uuidString)
                .execute()
        } catch {
            // Silent failure - this is not critical
        }
    }

    private func setupNotificationObservers() {
        // Listen for app lifecycle events
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.handleAppBecameActive()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handleAppWentToBackground()
                }
            }
            .store(in: &cancellables)
    }

    private func shouldRefreshOnActivation() -> Bool {
        // Refresh if more than 5 minutes since last active
        guard let lastActive = lastActiveTime else { return true }
        return Date().timeIntervalSince(lastActive) > 300 // 5 minutes
    }

    private func refreshForNewDay() async {
        // Reload dashboard data
        await dashboardDataService.loadDashboardData(force: true, silent: true)

        // Check for tier unlock (user might have crossed a threshold)
        tierProgressManager.checkForTierUnlock(force: true)
    }

    // MARK: - Debug Methods

    #if DEBUG
    func debugTriggerRefresh() async {
        await dashboardDataService.forceReload()
        tierProgressManager.checkForTierUnlock(force: true)
    }
    #endif
}