//
//  UserAnalyticsService.swift
//  Checkpoint
//
//  Service for fetching and updating user analytics
//

import Foundation
import Supabase

@MainActor
final class UserAnalyticsService {

    // MARK: - Singleton

    static let shared = UserAnalyticsService()

    // MARK: - Properties

    private let supabase = SupabaseClientManager.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Fetch analytics from database and cache locally
    @MainActor
    func fetchAndCacheAnalytics(for userId: UUID) async throws -> CachedUserAnalytics {
        // Fetch the analytics data (percentile is pre-calculated)
        let analytics: UserAnalyticsResponse = try await supabase.database
            .from("user_analytics_live")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        // Fetch gambling profile for rates
        let gamblingProfile: GamblingProfileResponse = try await supabase.database
            .from("gambling_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        // Create cached model
        let cached = CachedUserAnalytics(
            from: analytics,
            savingsPerSecond: gamblingProfile.savings_per_second ?? 0,
            averageBetAmount: gamblingProfile.average_bet_amount ?? 0,
            dailyBetCount: gamblingProfile.daily_bet_count ?? 0
        )

        // Cache it
        UserDefaults.standard.cachedAnalytics = cached

        return cached
    }

    /// Update analytics in database with current values
    @MainActor
    func updateAnalyticsInDatabase(
        userId: UUID,
        totalSaved: Double,
        betsAvoided: Int,
        gamblingDaysPrevented: Int
    ) async throws {
        struct AnalyticsUpdate: Encodable {
            let total_saved: Double
            let bets_avoided: Int
            let gambling_days_prevented: Int
            let last_calculation_at: String
        }

        let updates = AnalyticsUpdate(
            total_saved: totalSaved,
            bets_avoided: betsAvoided,
            gambling_days_prevented: gamblingDaysPrevented,
            last_calculation_at: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase.database
            .from("user_analytics")
            .update(updates)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    /// Get checkpoint window time for a user (nuclear-only: always 0)
    @MainActor
    func getCheckpointWindowTime(for userId: UUID) async throws -> TimeInterval {
        // Nuclear-only mode: No checkpoint unlocks exist
        return 0
    }

    /// Call server-side calculation function for accurate savings
    /// Uses event-sourced calculation for single source of truth
    @MainActor
    func calculateSavingsFromServer(for userId: UUID) async throws -> ServerSavingsCalculation {
        print("💰 [EVENT-SOURCING] ===== CALLING EVENT-BASED CALCULATION =====")
        print("💰 [EVENT-SOURCING] User ID: \(userId.uuidString)")

        struct RPCParams: Encodable {
            let p_user_id: String
        }

        let params = RPCParams(p_user_id: userId.uuidString)

        print("💰 [EVENT-SOURCING] Calling RPC: calculate_savings_from_events")
        let result: [ServerSavingsCalculation] = try await supabase.database
            .rpc("calculate_savings_from_events", params: params)
            .execute()
            .value

        guard let calculation = result.first else {
            print("❌ [EVENT-SOURCING] No calculation result returned from server!")
            throw AnalyticsServiceError.calculationFailed
        }

        print("💰 [EVENT-SOURCING] ===== EVENT-BASED CALCULATION RESULT =====")
        print("💰 [EVENT-SOURCING] total_saved: $\(calculation.total_saved)")
        print("💰 [EVENT-SOURCING] bets_avoided (lifetime): \(calculation.bets_avoided)")
        print("💰 [EVENT-SOURCING] gambling_days_prevented (lifetime): \(calculation.gambling_days_prevented)")
        print("💰 [EVENT-SOURCING] ==========================================")

        return calculation
    }

    /// Update gambling profile in database
    @MainActor
    func updateGamblingProfile(
        userId: UUID,
        averageBetAmount: Double,
        dailyBetCount: Int,
        gamblingDaysPerWeek: Int
    ) async throws {
        print("[debugUpdatedGamblingProfile] 🌐 Service: Starting Supabase update...")
        print("[debugUpdatedGamblingProfile] 🌐 Service: userId=\(userId), betAmount=\(averageBetAmount), betCount=\(dailyBetCount), daysPerWeek=\(gamblingDaysPerWeek)")

        // Calculate savings per second: (bet * bets_per_day * days_per_week) / seconds_per_week
        let savingsPerSecond = (averageBetAmount * Double(dailyBetCount) * Double(gamblingDaysPerWeek)) / 604800.0
        print("[debugUpdatedGamblingProfile] 🌐 Service: Calculated savingsPerSecond=\(savingsPerSecond)")

        struct GamblingProfileUpdate: Encodable {
            let average_bet_amount: Double
            let daily_bet_count: Int
            let gambling_days_per_week: Int
            let savings_per_second: Double
            let updated_at: String
        }

        let updates = GamblingProfileUpdate(
            average_bet_amount: averageBetAmount,
            daily_bet_count: dailyBetCount,
            gambling_days_per_week: gamblingDaysPerWeek,
            savings_per_second: savingsPerSecond,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        print("[debugUpdatedGamblingProfile] 🌐 Service: Executing Supabase update query...")
        try await supabase.database
            .from("gambling_profiles")
            .update(updates)
            .eq("user_id", value: userId.uuidString)
            .execute()
        print("[debugUpdatedGamblingProfile] 🌐 Service: Supabase update completed successfully")
    }

    /// Fetch all analytics data in a single comprehensive query
    @MainActor
    func fetchComprehensiveAnalytics(for userId: UUID) async throws -> ComprehensiveAnalyticsResponse {
        // Fetch all data concurrently (no RPC needed - percentile is pre-calculated)
        async let analyticsTask = supabase.database
            .from("user_analytics_live")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value as UserAnalyticsResponse

        async let gamblingProfileTask = supabase.database
            .from("gambling_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value as GamblingProfileResponse

        async let userProfileTask = supabase.database
            .from("user_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value as UserProfileDataResponse

        // Await all results (removed checkpoint attempts - nuclear-only mode)
        let (analytics, gamblingProfile, userProfile) = try await (
            analyticsTask,
            gamblingProfileTask,
            userProfileTask
        )

        // Nuclear-only mode: No checkpoint window time (no unlocks)
        let totalWindowTime: TimeInterval = 0
        let lastUnlock: Date? = nil

        // Get user join date from UserProfileService
        let userProfileDetails = try await UserProfileService.shared.fetchUserProfile(userId: userId)
        let joinDate = userProfileDetails?.createdAt ?? Date()

        // Cache all relevant data
        if let avgBet = gamblingProfile.average_bet_amount {
            UserDefaults.standard.set(avgBet, forKey: "average_bet_amount")
        }
        if let dailyBets = gamblingProfile.daily_bet_count {
            UserDefaults.standard.set(dailyBets, forKey: "daily_bet_count")
        }
        if let gamblingDays = gamblingProfile.gambling_days_per_week {
            UserDefaults.standard.set(gamblingDays, forKey: "gambling_days_per_week")
        }
        if let rate = gamblingProfile.savings_per_second {
            UserDefaults.standard.set(rate, forKey: "savings_per_second")
        }
        if let anchors = userProfile.accountability_anchors {
            UserDefaults.standard.set(anchors, forKey: "accountability_anchors")
        }
        UserDefaults.standard.set(joinDate, forKey: "user_join_date")

        // Create cached analytics
        let cached = CachedUserAnalytics(
            from: analytics,
            savingsPerSecond: gamblingProfile.savings_per_second ?? 0,
            averageBetAmount: gamblingProfile.average_bet_amount ?? 0,
            dailyBetCount: gamblingProfile.daily_bet_count ?? 0
        )
        UserDefaults.standard.cachedAnalytics = cached

        // Create comprehensive response
        return ComprehensiveAnalyticsResponse(
            analytics: analytics,
            gamblingProfile: gamblingProfile,
            userProfile: userProfile,
            accountabilityAnchors: userProfile.accountability_anchors ?? [],
            checkpointWindowTime: totalWindowTime,
            lastUnlockTime: lastUnlock,
            joinDate: joinDate,
            cachedAnalytics: cached
        )
    }

}

// MARK: - Response Models

struct PercentileResponse: Decodable {
    let percentile: Double
}

/// Response model for gambling profile data from database
struct GamblingProfileResponse: Decodable {
    let user_id: UUID
    let average_bet_amount: Double?
    let daily_bet_count: Int?
    let gambling_days_per_week: Int?
    let savings_per_second: Double?
    let projected_annual_loss: Double?
    let created_at: Date?
    let updated_at: Date?
}

// MARK: - Comprehensive Response Model

struct ComprehensiveAnalyticsResponse {
    let analytics: UserAnalyticsResponse
    let gamblingProfile: GamblingProfileResponse
    let userProfile: UserProfileDataResponse
    let accountabilityAnchors: [String]
    let checkpointWindowTime: TimeInterval
    let lastUnlockTime: Date?
    let joinDate: Date
    let cachedAnalytics: CachedUserAnalytics
}

// MARK: - Errors

enum AnalyticsServiceError: LocalizedError {
    case calculationFailed

    var errorDescription: String? {
        switch self {
        case .calculationFailed:
            return "Failed to calculate savings from server"
        }
    }
}