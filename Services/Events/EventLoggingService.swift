//
//  EventLoggingService.swift
//  Checkpoint
//
//  Service for logging user events to Supabase for event sourcing.
//  Phase 1: Start logging events (additive only, zero risk)
//

import Foundation
import Supabase

/// Service for logging user events to enable event sourcing
@MainActor
class EventLoggingService {

    // MARK: - Singleton

    static let shared = EventLoggingService()

    // MARK: - Properties

    private let supabase = SupabaseClientManager.shared.client

    // MARK: - Public Methods

    /// Log an event to Supabase database
    /// - Parameters:
    ///   - userId: The user performing the action
    ///   - type: The event type
    ///   - payload: Additional event data
    ///   - timestamp: Optional custom timestamp (defaults to now)
    func logEvent(
        userId: UUID,
        type: EventType,
        payload: [String: Any] = [:],
        timestamp: Date? = nil
    ) async {

        // Convert payload to Encodable format
        let encodablePayload = payload.compactMapValues { value -> String? in
            if let stringValue = value as? String {
                return stringValue
            } else if let boolValue = value as? Bool {
                return boolValue ? "true" : "false"
            } else if let numberValue = value as? CustomStringConvertible {
                return numberValue.description
            }
            return nil
        }

        struct UserEventInsert: Encodable {
            let user_id: String
            let event_type: String
            let payload: [String: String]
            let created_at: String?
        }

        let event = UserEventInsert(
            user_id: userId.uuidString,
            event_type: type.rawValue,
            payload: encodablePayload,
            created_at: timestamp.map { ISO8601DateFormatter().string(from: $0) }
        )

        do {
            try await supabase.from("user_events")
                .insert(event)
                .execute()

            print("📊 [EVENT] Logged: \(type.rawValue)")
        } catch {
            // Fail silently - event logging should never break the app
            print("⚠️ [EVENT] Failed to log \(type.rawValue): \(error.localizedDescription)")
        }
    }

    // MARK: - Convenience Methods

    /// Log journey started event (onboarding complete)
    func logJourneyStarted(userId: UUID, savingsRate: Double) async {
        await logEvent(
            userId: userId,
            type: .journeyStarted,
            payload: ["savings_rate": savingsRate]
        )
    }

    /// Log profile updated event (settings changed)
    func logProfileUpdated(
        userId: UUID,
        savingsRate: Double,
        dailyBets: Int,
        daysPerWeek: Int
    ) async {
        await logEvent(
            userId: userId,
            type: .profileUpdated,
            payload: [
                "savings_rate": savingsRate,
                "daily_bets": dailyBets,
                "days_per_week": daysPerWeek
            ]
        )
    }

    /// Log relapse event
    func logRelapse(userId: UUID, amountLost: Double) async {
        await logEvent(
            userId: userId,
            type: .relapse,
            payload: ["amount_lost": amountLost]
        )
    }

    /// Log tier unlocked event
    func logTierUnlocked(userId: UUID, tier: String, days: Int) async {
        await logEvent(
            userId: userId,
            type: .tierUnlocked,
            payload: ["tier": tier, "days": days]
        )
    }

    /// Log module completed event
    func logModuleCompleted(userId: UUID, unit: String, slug: String, title: String) async {
        await logEvent(
            userId: userId,
            type: .moduleCompleted,
            payload: ["unit": unit, "slug": slug, "title": title]
        )
    }

    /// Log urge logged event
    func logUrgeLogged(userId: UUID, outcome: String, interventions: [String]) async {
        await logEvent(
            userId: userId,
            type: .urgeLogged,
            payload: [
                "outcome": outcome,
                "interventions": interventions.joined(separator: ",")
            ]
        )
    }

    /// Log protection enabled event
    func logProtectionEnabled(userId: UUID, type protectionType: String) async {
        await logEvent(
            userId: userId,
            type: .protectionEnabled,
            payload: ["type": protectionType]
        )
    }

    /// Log protection disabled event
    func logProtectionDisabled(userId: UUID, type protectionType: String) async {
        await logEvent(
            userId: userId,
            type: .protectionDisabled,
            payload: ["type": protectionType]
        )
    }

    /// Log subscription started event
    func logSubscriptionStarted(userId: UUID, plan: String, productId: String) async {
        await logEvent(
            userId: userId,
            type: .subscriptionStarted,
            payload: ["plan": plan, "product_id": productId]
        )
    }

    /// Log subscription cancelled event
    func logSubscriptionCancelled(userId: UUID) async {
        await logEvent(
            userId: userId,
            type: .subscriptionCancelled,
            payload: [:]
        )
    }

    /// Log daily check-in event
    func logDailyCheckIn(userId: UUID, stayedClean: Bool) async {
        await logEvent(
            userId: userId,
            type: .dailyCheckIn,
            payload: ["stayed_clean": stayedClean]
        )
    }
}

// MARK: - Event Types

extension EventLoggingService {

    /// All supported event types
    enum EventType: String {
        // Journey events
        case journeyStarted = "journey_started"
        case profileUpdated = "profile_updated"
        case relapse = "relapse"

        // Progress events
        case tierUnlocked = "tier_unlocked"
        case moduleCompleted = "module_completed"
        case urgeLogged = "urge_logged"

        // Protection events
        case protectionEnabled = "protection_enabled"
        case protectionDisabled = "protection_disabled"

        // Subscription events
        case subscriptionStarted = "subscription_started"
        case subscriptionCancelled = "subscription_cancelled"

        // Engagement events
        case dailyCheckIn = "daily_checkin"
    }
}
