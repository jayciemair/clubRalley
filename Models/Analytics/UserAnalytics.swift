//
//  UserAnalytics.swift
//  Checkpoint
//
//  Model for user analytics data from database
//

import Foundation

// MARK: - Database Response

struct UserAnalyticsResponse: Codable {
    let user_id: UUID
    let total_saved: Double
    let bets_avoided: Int
    let gambling_days_prevented: Int
    let current_streak_days: Int
    let longest_streak_days: Int
    let last_calculation_at: Date
    let created_at: Date
    let updated_at: Date
    let percentile_rank: Double?
    let percentile_calculated_at: Date?
    let quit_date: Date?
    let streak_started_at: Date?
}

// MARK: - Cached Analytics Model

struct CachedUserAnalytics: Codable {
    let totalSaved: Double
    let betsAvoided: Int
    let gamblingDaysPrevented: Int
    let currentStreakDays: Int
    let longestStreakDays: Int
    let cachedAt: Date  // When we cached this data
    let savingsPerSecond: Double  // Store the rate for local calculations
    let averageBetAmount: Double  // For calculating bets avoided
    let dailyBetCount: Int  // For calculating gambling days prevented
    let percentileRank: Double?  // User's percentile ranking
    let percentileCalculatedAt: Date?  // When percentile was last calculated
    let quitDate: Date?  // Target gambling-free date (90 days from start/last relapse)
    let streakStartedAt: Date?  // When current streak began (resets on relapse)

    init(from response: UserAnalyticsResponse, savingsPerSecond: Double, averageBetAmount: Double, dailyBetCount: Int) {
        self.totalSaved = response.total_saved
        self.betsAvoided = response.bets_avoided
        self.gamblingDaysPrevented = response.gambling_days_prevented
        self.currentStreakDays = response.current_streak_days
        self.longestStreakDays = response.longest_streak_days
        self.cachedAt = Date()
        self.savingsPerSecond = savingsPerSecond
        self.averageBetAmount = averageBetAmount
        self.dailyBetCount = dailyBetCount
        self.percentileRank = response.percentile_rank
        self.percentileCalculatedAt = response.percentile_calculated_at
        self.quitDate = response.quit_date
        self.streakStartedAt = response.streak_started_at
    }

    // Calculate current values from join date (not from cache - simpler and always correct)
    // If frozenAt is provided, uses frozen time instead of current time
    func currentValues(joinDate: Date, checkpointWindowTime: TimeInterval = 0, frozenAt: Date? = nil) -> (totalSaved: Double, betsAvoided: Int, gamblingDaysPrevented: Int) {
        // Use frozen time if provided, otherwise use current time
        let now = frozenAt ?? Date()

        // Calculate total time since joining
        let totalSeconds = now.timeIntervalSince(joinDate)

        // Subtract checkpoint window (time when blocking was OFF)
        let protectedSeconds = max(0, totalSeconds - checkpointWindowTime)

        // Calculate total saved
        let currentTotal = protectedSeconds * savingsPerSecond

        // Calculate bets avoided (integer)
        let currentBetsAvoided = averageBetAmount > 0 ? Int(currentTotal / averageBetAmount) : 0

        // Calculate gambling days prevented based on time protected, not bet count
        let dailySavings = savingsPerSecond * 86400 // seconds in a day
        let currentGamblingDays = dailySavings > 0 ? Int(currentTotal / dailySavings) : 0

        return (currentTotal, currentBetsAvoided, currentGamblingDays)
    }
}

// MARK: - UserDefaults Extension for Caching

extension UserDefaults {
    private static let analyticsKey = "cached_user_analytics"

    var cachedAnalytics: CachedUserAnalytics? {
        get {
            guard let data = data(forKey: Self.analyticsKey) else { return nil }
            return try? JSONDecoder().decode(CachedUserAnalytics.self, from: data)
        }
        set {
            if let newValue = newValue,
               let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: Self.analyticsKey)
            } else {
                removeObject(forKey: Self.analyticsKey)
            }
        }
    }
}