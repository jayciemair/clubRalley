//
//  DashboardDataService.swift
//  Checkpoint
//
//  Service for fetching and caching dashboard data with intelligent refresh logic
//

import Foundation
import SwiftUI

/// Service that manages dashboard data fetching and caching
@MainActor
final class DashboardDataService: ObservableObject {

    // MARK: - Singleton

    static let shared = DashboardDataService()

    // MARK: - Published Properties (for UI binding)

    @Published var currentWeekRelapses: [Date] = []
    @Published var quitDate: Date?
    @Published var currentStreak: Int = 0
    @Published var streakStartedAt: Date?
    @Published var isLoading = false
    @Published var hasLoadedOnce = false

    // MARK: - Cache Properties

    private var lastFetchTime: Date?
    private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes
    private var isFetchInProgress = false

    // MARK: - Dependencies

    private let authService = AuthenticationService.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Load dashboard data with intelligent caching
    /// - Parameters:
    ///   - force: Force refresh even if cache is fresh
    ///   - silent: Don't show loading indicator (for background refresh)
    func loadDashboardData(force: Bool = false, silent: Bool = false) async {
        // Check if we should use cache
        if !force && shouldUseCache() {
            return
        }

        // Prevent concurrent fetches
        guard !isFetchInProgress else {
            return
        }

        guard let userId = getCurrentUserId() else {
            return
        }

        isFetchInProgress = true

        if !silent {
            isLoading = true
        }

        // Fetch data in parallel for efficiency
        async let relapsesTask: Void = loadCurrentWeekRelapses(userId: userId)
        async let streakTask: Void = loadQuitDateAndStreak(userId: userId)

        // Wait for both to complete
        await relapsesTask
        await streakTask

        // Update cache timestamp
        lastFetchTime = Date()
        hasLoadedOnce = true
        isFetchInProgress = false

        if !silent {
            isLoading = false
        }

        // Notify TierProgressManager of updated streak
        TierProgressManager.shared.updateStreakData(streak: currentStreak, quitDate: quitDate)
    }

    /// Force reload data (e.g., after relapse logged)
    func forceReload() async {
        await loadDashboardData(force: true)
    }

    /// Clear cache and reset state
    func clearCache() {
        lastFetchTime = nil
        hasLoadedOnce = false
        currentWeekRelapses = []
        quitDate = nil
        currentStreak = 0
    }

    // MARK: - Private Methods

    private func shouldUseCache() -> Bool {
        guard hasLoadedOnce,
              let lastFetch = lastFetchTime else {
            return false
        }

        let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
        return timeSinceLastFetch < cacheExpirationInterval
    }

    private func getCurrentUserId() -> UUID? {
        if case .authenticated(let session) = authService.authState,
           let uuid = UUID(uuidString: session.userId) {
            return uuid
        }
        return nil
    }

    private func loadCurrentWeekRelapses(userId: UUID) async {
        do {
            let supabase = SupabaseClientManager.shared
            let calendar = Calendar.current

            // Get start and end of current week
            guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start,
                  let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
                return
            }

            struct JournalTimestamp: Decodable {
                let timestamp: Date
            }

            // Fetch relapse journal entries from current week
            let response: [JournalTimestamp] = try await supabase.database
                .from("journal_entries")
                .select("timestamp")
                .eq("user_id", value: userId.uuidString)
                .eq("entry_type", value: "relapse")
                .gte("timestamp", value: weekStart.ISO8601Format())
                .lt("timestamp", value: weekEnd.ISO8601Format())
                .execute()
                .value

            let timestamps = response.map { $0.timestamp }

            // Update on main thread
            await MainActor.run {
                currentWeekRelapses = timestamps
            }
        } catch {
            // Log error to Supabase
            await ErrorLoggingService.shared.logError(
                userId: userId,
                type: .analyticsSyncFailed,
                error: error,
                context: ["operation": "load_week_relapses"]
            )
        }
    }

    private func loadQuitDateAndStreak(userId: UUID) async {
        do {
            let supabase = SupabaseClientManager.shared

            struct QuitDateResponse: Decodable {
                let quit_date: Date?
                let current_streak_days: Int
                let streak_started_at: Date?
            }

            let response: QuitDateResponse = try await supabase.database
                .from("user_analytics_live")
                .select("quit_date, current_streak_days, streak_started_at")
                .eq("user_id", value: userId.uuidString)
                .single()
                .execute()
                .value

            await MainActor.run {
                quitDate = response.quit_date
                currentStreak = response.current_streak_days
                streakStartedAt = response.streak_started_at
                print("🔍 DEBUG [DashboardDataService] Loaded from DB - quitDate: \(String(describing: response.quit_date)), currentStreak: \(response.current_streak_days), streakStartedAt: \(String(describing: response.streak_started_at))")
            }
        } catch {
            // Log error to Supabase
            await ErrorLoggingService.shared.logError(
                userId: userId,
                type: .analyticsCalculationFailed,
                error: error,
                context: ["operation": "load_quit_date_streak"]
            )
        }
    }

    // MARK: - Day Change Detection

    /// Check if we've crossed into a new day since last fetch
    func hasEnteredNewDay() -> Bool {
        guard let lastFetch = lastFetchTime else { return true }

        let calendar = Calendar.current
        let lastFetchDay = calendar.startOfDay(for: lastFetch)
        let currentDay = calendar.startOfDay(for: Date())

        return currentDay > lastFetchDay
    }

    /// Refresh if it's a new day (for tier progression)
    func refreshIfNewDay() async {
        if hasEnteredNewDay() {
            await loadDashboardData(force: true, silent: true)
        }
    }
}