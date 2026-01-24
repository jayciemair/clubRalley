//
//  AnalyticsViewModel.swift
//  Checkpoint
//
//  ViewModel for managing analytics data and business logic
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AnalyticsViewModel: ObservableObject {

    // MARK: - Singleton

    static let shared = AnalyticsViewModel()

    // MARK: - Published Properties

    @Published var displayedAmount: Double = UserDefaults.standard.double(forKey: "last_displayed_amount")
    @Published var displayedBetsAvoided: Int = 0
    @Published var displayedGamblingDaysPrevented: Int = 0
    @Published var daysActive: Int = 0
    @Published var dailySavings: Double = 0.0
    @Published var userPercentile: String = "—"

    @Published var accountabilityAnchors: [String] = []
    @Published var gamblingFreeStartDate: Date?  // Now loaded from streak_started_at
    @Published var isLoadingGamblingFreeTime = false

    @Published var cachedAnalytics: CachedUserAnalytics?
    @Published var isLoading = true

    @Published var projectedAnnualLoss: Double = 0

    // Quit date tracking
    @Published var quitDate: Date?
    @Published var currentStreak: Int = 0

    // Eligibility state (for frozen banner display)
    @Published var isEligible = true

    // Track if we've loaded from server at least once this session
    private var hasLoadedFromServer = false

    // Track if view is visible for deferred animations
    private var isViewVisible = false

    // Store pending amount update for animation when view becomes visible
    private var pendingAmountUpdate: Double?

    // MARK: - Private Properties

    private var userJoinDate: Date?
    private var totalCheckpointWindowTime: TimeInterval = 0
    private var savingsPerSecond: Double = 0
    private var averageBetAmount: Double = 0
    private var dailyBetCount: Int = 0
    private var gamblingDaysPerWeek: Int = 0

    private var timer: Timer?
    private var syncTimer: Timer?
    private var lastSyncTime = Date()
    private var debugCounter = 0

    private let authService = AuthenticationService.shared
    private let analyticsService = UserAnalyticsService.shared
    private var cancellables = Set<AnyCancellable>()

    // Persistent frozen time (survives view lifecycle)
    private var frozenCalculationTime: Date? {
        get {
            let interval = UserDefaults.standard.double(forKey: "analytics_frozen_time")
            return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: "analytics_frozen_time")
            } else {
                UserDefaults.standard.removeObject(forKey: "analytics_frozen_time")
            }
        }
    }

    // MARK: - Computed Properties

    var formattedSavingsAmount: String {
        if displayedAmount < 10 {
            return String(format: "$%.2f", displayedAmount)
        } else if displayedAmount < 100 {
            return String(format: "$%.2f", displayedAmount)
        } else if displayedAmount < 1000 {
            return String(format: "$%.0f", displayedAmount)
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
            formatter.groupingSeparator = ","
            formatter.usesGroupingSeparator = true

            if let formatted = formatter.string(from: NSNumber(value: displayedAmount)) {
                return "$\(formatted)"
            } else {
                return String(format: "$%.0f", displayedAmount)
            }
        }
    }

    var formattedDailySavings: String {
        if dailySavings == 0 {
            return "$0"
        } else if dailySavings < 100 {
            return String(format: "$%.0f", dailySavings)
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
            formatter.groupingSeparator = ","
            formatter.usesGroupingSeparator = true

            if let formatted = formatter.string(from: NSNumber(value: dailySavings)) {
                return "$\(formatted)"
            } else {
                return String(format: "$%.0f", dailySavings)
            }
        }
    }

    var formattedProjectedAnnualLoss: String {
        print("🎯 DEBUG: formattedProjectedAnnualLoss called with value: \(projectedAnnualLoss)")
        if projectedAnnualLoss == 0 {
            print("⚠️ DEBUG: Returning $0 because projectedAnnualLoss is 0")
            return "$0"
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            formatter.minimumFractionDigits = 0
            formatter.groupingSeparator = ","
            formatter.usesGroupingSeparator = true

            if let formatted = formatter.string(from: NSNumber(value: projectedAnnualLoss)) {
                print("✅ DEBUG: Formatted as: \(formatted)")
                return "$\(formatted)"
            } else {
                print("⚠️ DEBUG: Formatter failed, using fallback")
                return String(format: "$%.0f", projectedAnnualLoss)
            }
        }
    }

    // MARK: - Initialization

    private init() {
        loadCachedData()
        setupEligibilityObserver()
        setupBackgroundObserver()
        observeEligibilityForView()
    }

    deinit {
        timer?.invalidate()
        syncTimer?.invalidate()
        cancellables.forEach { $0.cancel() }
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public Methods

    func onAppear() {
        isViewVisible = true

        // Check if there's a pending amount update to animate
        if let pendingAmount = pendingAmountUpdate {
            print("[debugNewUpdate] 🎬 View appeared with pending amount update: $\(pendingAmount)")
            animateToNewAmount(pendingAmount)
            pendingAmountUpdate = nil
        }

        // Check if cache seems stale (mismatched streak vs database)
        let cachedStreak = cachedAnalytics?.currentStreakDays ?? -1

        // ALWAYS load from server on first view of this session
        if !hasLoadedFromServer {
            Task {
                await loadAllAnalyticsData()
                hasLoadedFromServer = true
                startTimer()
            }
        } else if cachedAnalytics == nil || gamblingFreeStartDate == nil || cachedStreak != currentStreak {
            // Reload if cache is missing or mismatched
            Task {
                await loadAllAnalyticsData()
                startTimer()
            }
        } else {
            // Just start the timer with cached data
            startTimer()
        }
    }

    func onDisappear() {
        isViewVisible = false
        // Keep timer running in background - savings accumulate even when not viewing tab
        // Timer will continue to increment displayedAmount so it's accurate when user returns
    }

    // MARK: - Amount Animation

    /// Animate the displayed amount from current value to new value
    private func animateToNewAmount(_ newAmount: Double) {
        let oldAmount = displayedAmount
        let difference = newAmount - oldAmount

        print("[debugNewUpdate] 🎬 Animating from $\(oldAmount) to $\(newAmount) (diff: $\(difference))")

        // Don't animate tiny differences
        guard abs(difference) > 1 else {
            displayedAmount = newAmount
            UserDefaults.standard.set(newAmount, forKey: "last_displayed_amount")
            return
        }

        // Stop the regular timer during animation
        stopTimer()

        let animationDuration: Double = 1.5
        let startTime = Date()
        let steps = 60 // 60 FPS

        // Create animation timer
        Timer.scheduledTimer(withTimeInterval: animationDuration / Double(steps), repeats: true) { [weak self] animTimer in
            guard let self = self else {
                animTimer.invalidate()
                return
            }

            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / animationDuration, 1.0)

            // Ease-out cubic for smooth deceleration
            let easedProgress = 1 - pow(1 - progress, 3)

            self.displayedAmount = oldAmount + (difference * easedProgress)

            if progress >= 1.0 {
                animTimer.invalidate()
                self.displayedAmount = newAmount
                UserDefaults.standard.set(newAmount, forKey: "last_displayed_amount")
                print("[debugNewUpdate] ✅ Animation complete, final amount: $\(newAmount)")

                // Restart the regular increment timer
                self.startTimer()
            }
        }
    }

    // MARK: - Eligibility Observer

    /// Observe eligibility for view display (frozen banner)
    private func observeEligibilityForView() {
        // Always eligible now that protection service is removed
        isEligible = true
    }

    private func setupEligibilityObserver() {
        // No longer observing protection state - always eligible
    }

    // MARK: - Data Loading

    private func loadCachedData() {
        // Load from UserDefaults cache immediately
        cachedAnalytics = UserDefaults.standard.cachedAnalytics
        accountabilityAnchors = UserDefaults.standard.array(forKey: "accountability_anchors") as? [String] ?? []
        userJoinDate = UserDefaults.standard.object(forKey: "user_join_date") as? Date

        // Load quit date, streak, and gambling-free start from cached analytics (database-backed)
        if let cached = cachedAnalytics {
            quitDate = cached.quitDate
            currentStreak = cached.currentStreakDays
            gamblingFreeStartDate = cached.streakStartedAt
        }

        // Load checkpoint window time from cache to prevent calculation jump
        let cachedWindowTime = UserDefaults.standard.double(forKey: "total_checkpoint_window_time")
        if cachedWindowTime > 0 {
            totalCheckpointWindowTime = cachedWindowTime
        }

        if let value = UserDefaults.standard.object(forKey: "daily_bet_count") as? Int, value > 0 {
            dailyBetCount = value
        }
        if let value = UserDefaults.standard.object(forKey: "gambling_days_per_week") as? Int, value > 0 {
            gamblingDaysPerWeek = value
        }
        if UserDefaults.standard.double(forKey: "average_bet_amount") > 0 {
            averageBetAmount = UserDefaults.standard.double(forKey: "average_bet_amount")
        }
        if UserDefaults.standard.double(forKey: "savings_per_second") > 0 {
            savingsPerSecond = UserDefaults.standard.double(forKey: "savings_per_second")
        }

        // Load cached percentile immediately if available
        if let cached = cachedAnalytics,
           let percentileRank = cached.percentileRank {
            let percentage = Int(percentileRank)
            if percentage >= 99 {
                userPercentile = "Top 1%"
            } else if percentage <= 0 {
                userPercentile = "—"
            } else {
                userPercentile = "Top \(100 - percentage)%"
            }
        }

        if let joinDate = userJoinDate {
            daysActive = Calendar.current.dateComponents([.day], from: joinDate, to: Date()).day ?? 0
        }

        // Calculate daily savings from cached data
        if dailyBetCount > 0 && averageBetAmount > 0 && gamblingDaysPerWeek > 0 {
            dailySavings = Double(dailyBetCount) * averageBetAmount * Double(gamblingDaysPerWeek) / 7.0
        }
    }

    func loadAllAnalyticsData() async {
        guard let session = authService.currentSession,
              let userId = UUID(uuidString: session.userId) else {
            isLoading = false
            return
        }

        do {
            // Fetch all data in one comprehensive query
            let response = try await analyticsService.fetchComprehensiveAnalytics(for: userId)

            // Update all properties from response
            cachedAnalytics = response.cachedAnalytics
            totalCheckpointWindowTime = response.checkpointWindowTime
            accountabilityAnchors = response.accountabilityAnchors
            userJoinDate = response.joinDate

            // Update quit date, streak, and gambling-free start from cached analytics
            quitDate = response.cachedAnalytics.quitDate
            currentStreak = response.cachedAnalytics.currentStreakDays
            gamblingFreeStartDate = response.cachedAnalytics.streakStartedAt

            // Cache critical values to UserDefaults for next app open
            UserDefaults.standard.set(response.checkpointWindowTime, forKey: "total_checkpoint_window_time")
            UserDefaults.standard.set(response.joinDate, forKey: "user_join_date")

            // Update gambling profile data
            if let avgBet = response.gamblingProfile.average_bet_amount {
                averageBetAmount = avgBet
            }
            if let dailyBets = response.gamblingProfile.daily_bet_count {
                dailyBetCount = dailyBets
            }
            if let gamblingDays = response.gamblingProfile.gambling_days_per_week {
                gamblingDaysPerWeek = gamblingDays
            }
            if let rate = response.gamblingProfile.savings_per_second {
                savingsPerSecond = rate
            }
            if let projectedLoss = response.gamblingProfile.projected_annual_loss {
                projectedAnnualLoss = projectedLoss
                print("🎯 DEBUG: Loaded projected_annual_loss from DB: \(projectedLoss)")
            } else {
                print("⚠️ DEBUG: projected_annual_loss is nil in database response")
            }

            // Calculate daily savings
            if dailyBetCount > 0 && averageBetAmount > 0 && gamblingDaysPerWeek > 0 {
                dailySavings = Double(dailyBetCount) * averageBetAmount * Double(gamblingDaysPerWeek) / 7.0
            }

            // Load user percentile
            Task {
                await loadUserPercentile(totalSaved: response.cachedAnalytics.totalSaved)
            }

            // gambling_free_start_date is now loaded from streak_started_at (line 284)
            // No need to calculate from checkpoint unlocks anymore
            isLoadingGamblingFreeTime = false

            // Fetch accurate values from server calculation FIRST
            await refreshFromServer()

            // Update other display values (daysActive)
            if let joinDate = userJoinDate {
                let now = frozenCalculationTime ?? Date()
                daysActive = Calendar.current.dateComponents([.day], from: joinDate, to: now).day ?? 0
            }

            isLoading = false

        } catch {
            isLoading = false
        }
    }

    private func loadGamblingFreeStartDate() async {
        guard let session = authService.currentSession,
              let userId = UUID(uuidString: session.userId) else {
            if gamblingFreeStartDate == nil {
                gamblingFreeStartDate = Date()
            }
            isLoadingGamblingFreeTime = false
            return
        }

        do {
            // Nuclear-only mode: No checkpoint unlocks exist
            // Gambling-free time starts from account creation
            let userProfile = try await UserProfileService.shared.fetchUserProfile(userId: userId)
            let freshDate: Date
            if let createdAt = userProfile?.createdAt {
                freshDate = createdAt
            } else {
                freshDate = Date()
            }

            gamblingFreeStartDate = freshDate
            UserDefaults.standard.set(freshDate, forKey: "gambling_free_start_date")
            isLoadingGamblingFreeTime = false

        } catch {
            if gamblingFreeStartDate == nil {
                gamblingFreeStartDate = Date()
            }
            isLoadingGamblingFreeTime = false
        }
    }

    // MARK: - Background Observer

    /// Setup observer to save state when app goes to background
    private func setupBackgroundObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }

            // Save current displayed amount to cache
            UserDefaults.standard.set(self.displayedAmount, forKey: "last_displayed_amount")

            // Also save the full cached analytics if available
            if let cached = self.cachedAnalytics {
                UserDefaults.standard.cachedAnalytics = cached
            }
        }
    }

    // MARK: - Timer Management

    private func startTimer() {
        // Server value is already set by refreshFromServer()
        // Timer just increments from that value

        // Don't start if timer is already running
        guard timer == nil else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }

                let increment = self.savingsPerSecond * 0.1
                self.displayedAmount += increment

                // Log every 10 seconds
                self.debugCounter += 1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Server Refresh Management
    // Note: Local calculation removed - server is single source of truth (event sourcing)

    private func refreshFromServer() async {
        guard let session = authService.currentSession,
              let userId = UUID(uuidString: session.userId) else {
            return
        }

        do {
            print("[debugNewUpdate] 💰 About to call calculateSavingsFromServer for user: \(userId)")
            let result = try await analyticsService.calculateSavingsFromServer(for: userId)

            print("[debugNewUpdate] 💰 [SERVER] total_saved: $\(result.total_saved), bets_avoided: \(result.bets_avoided)")

            // Update bets avoided and days prevented immediately (no animation needed)
            displayedBetsAvoided = result.bets_avoided
            displayedGamblingDaysPrevented = result.gambling_days_prevented

            // Check if the amount has changed significantly
            let amountDifference = abs(result.total_saved - displayedAmount)
            let hasSignificantChange = amountDifference > 1.0

            print("[debugNewUpdate] 📊 Current: $\(displayedAmount), New: $\(result.total_saved), Diff: $\(amountDifference)")
            print("[debugNewUpdate] 👁 View visible: \(isViewVisible), Significant change: \(hasSignificantChange)")

            if hasSignificantChange {
                if isViewVisible {
                    // View is visible - animate the change now
                    print("[debugNewUpdate] 🎬 View visible, animating immediately")
                    animateToNewAmount(result.total_saved)
                } else {
                    // View is not visible - store for later animation
                    // DON'T update UserDefaults yet - we want the animation to start from old value
                    print("[debugNewUpdate] 📦 View not visible, storing pending update: $\(result.total_saved)")
                    pendingAmountUpdate = result.total_saved
                }
            } else {
                // Small change - just update directly (no animation needed)
                displayedAmount = result.total_saved
                UserDefaults.standard.set(result.total_saved, forKey: "last_displayed_amount")
            }

            print("[debugNewUpdate] ✅ Refresh complete")
        } catch {
            print("[debugNewUpdate] ❌ Error calculating savings: \(error)")
        }
    }

    // MARK: - Percentile Calculation

    private func loadUserPercentile(totalSaved: Double) async {
        // Check if we have cached percentile first
        if let cached = cachedAnalytics,
           let percentileRank = cached.percentileRank {
            // Use cached percentile (it's already a percentage, e.g., 95.5 means top 95.5%)
            let percentage = Int(percentileRank)
            if percentage >= 99 {
                userPercentile = "Top 1%"
            } else if percentage <= 0 {
                userPercentile = "—"
            } else {
                userPercentile = "Top \(100 - percentage)%"
            }
        } else {
            // No cached percentile available
            userPercentile = "—"
        }
    }

    // MARK: - Time Calculation

    func timeComponents(from startDate: Date?, to endDate: Date = Date()) -> (months: Int, days: Int, hours: Int, minutes: Int, seconds: Int) {
        guard let startDate = startDate else {
            return (months: 0, days: 0, hours: 0, minutes: 0, seconds: 0)
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day, .hour, .minute, .second], from: startDate, to: endDate)

        return (
            months: components.month ?? 0,
            days: components.day ?? 0,
            hours: components.hour ?? 0,
            minutes: components.minute ?? 0,
            seconds: components.second ?? 0
        )
    }
}