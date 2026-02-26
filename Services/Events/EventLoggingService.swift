//
//  EventLoggingService.swift
//  Club Ralley
//
//  Service for logging user events to Supabase for event sourcing.
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
    func logEvent(
        userId: UUID,
        type: EventType,
        payload: [String: Any] = [:],
        timestamp: Date? = nil
    ) async {

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
        } catch {
            // Fail silently - event logging should never break the app
        }
    }

    // MARK: - Convenience Methods

    func logJourneyStarted(userId: UUID, savingsRate: Double) async {
        await logEvent(userId: userId, type: .journeyStarted, payload: ["savings_rate": savingsRate])
    }

    func logProfileUpdated(userId: UUID, savingsRate: Double, dailyBets: Int, daysPerWeek: Int) async {
        await logEvent(userId: userId, type: .profileUpdated, payload: [
            "savings_rate": savingsRate, "daily_bets": dailyBets, "days_per_week": daysPerWeek
        ])
    }

    func logSubscriptionStarted(userId: UUID, plan: String, productId: String) async {
        await logEvent(userId: userId, type: .subscriptionStarted, payload: ["plan": plan, "product_id": productId])
    }

    func logSubscriptionCancelled(userId: UUID) async {
        await logEvent(userId: userId, type: .subscriptionCancelled, payload: [:])
    }
}

// MARK: - Event Types

extension EventLoggingService {

    enum EventType: String {
        case journeyStarted = "journey_started"
        case profileUpdated = "profile_updated"
        case subscriptionStarted = "subscription_started"
        case subscriptionCancelled = "subscription_cancelled"
    }
}
