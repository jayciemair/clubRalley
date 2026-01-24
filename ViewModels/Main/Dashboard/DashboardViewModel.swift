//
//  DashboardViewModel.swift
//  Checkpoint
//
//  Simplified ViewModel for dashboard that consumes DashboardDataService
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DashboardViewModel: ObservableObject {

    // MARK: - Singleton

    static let shared = DashboardViewModel()

    // MARK: - Dependencies

    private let dataService = DashboardDataService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published Properties (mirrors DashboardDataService)

    @Published var currentWeekRelapses: [Date] = []
    @Published var quitDate: Date?
    @Published var currentStreak: Int = 0
    @Published var streakStartedAt: Date?
    @Published var isLoading = false
    @Published var hasLoadedOnce = false

    // MARK: - Computed Properties

    var daysClean: Int {
        return currentStreak
    }

    var moneySaved: Double {
        // TODO: Calculate based on gambling profile
        return 0
    }

    // MARK: - Initialization

    private init() {
        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Mirror the data service state
        dataService.$currentWeekRelapses
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentWeekRelapses)

        dataService.$quitDate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newQuitDate in
                print("🔍 DEBUG [DashboardViewModel] quitDate updated: \(String(describing: newQuitDate))")
                self?.quitDate = newQuitDate
            }
            .store(in: &cancellables)

        dataService.$currentStreak
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newStreak in
                print("🔍 DEBUG [DashboardViewModel] currentStreak updated: \(newStreak)")
                self?.currentStreak = newStreak
            }
            .store(in: &cancellables)

        dataService.$streakStartedAt
            .receive(on: DispatchQueue.main)
            .assign(to: &$streakStartedAt)

        dataService.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        dataService.$hasLoadedOnce
            .receive(on: DispatchQueue.main)
            .assign(to: &$hasLoadedOnce)
    }

    // MARK: - Public Methods (delegating to service)

    /// Load dashboard data (delegates to service)
    func loadDashboardData() async {
        await dataService.loadDashboardData()
    }

    /// Force reload data
    func forceReload() async {
        await dataService.forceReload()
    }

    /// Reset streak (when user texted their ex)
    func resetStreak() async {
        let now = Date()
        UserDefaults.standard.set(now, forKey: "no_contact_start_date")
        streakStartedAt = now
        currentStreak = 0

        // Record this as a check-in where they contacted him (relapse)
        DailyCheckInManager.shared.recordCheckIn(stayedClean: false)

        print("[DashboardViewModel] ✅ Streak reset to \(now), recorded as contacted him")
    }

    /// Get no contact start date from UserDefaults
    func loadNoContactStartDate() {
        if let savedDate = UserDefaults.standard.object(forKey: "no_contact_start_date") as? Date {
            streakStartedAt = savedDate
        } else {
            // First time - set to now
            let now = Date()
            UserDefaults.standard.set(now, forKey: "no_contact_start_date")
            streakStartedAt = now
        }
    }

    // MARK: - Legacy Support (for compatibility)

    // These properties exist for backward compatibility but are no longer used
    @Published var joinDate: Date?
    @Published var isReloadingRelapses = false

    // MARK: - Tier Properties (REMOVED - Now handled by TierProgressManager)
    // The following properties have been moved to TierProgressManager:
    // - showTierUnlockedHUD
    // - unlockedTierName
    // - unlockedTierDays
    // These are now accessed via TierProgressManager.shared
}