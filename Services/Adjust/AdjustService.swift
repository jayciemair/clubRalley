//
//  AdjustService.swift
//  Checkpoint
//
//  Service for tracking attribution events with Adjust
//  TEMPORARILY DISABLED
//

import Foundation
// import AdjustSdk  // Temporarily disabled

final class AdjustService {

    // MARK: - Singleton

    static let shared = AdjustService()

    private init() {}

    // MARK: - Stub Methods (Adjust temporarily disabled)

    func trackSubscriptionStarted(productId: String, isFreeTrial: Bool, revenue: Double? = nil, currency: String = "USD") {
        // Adjust disabled - no-op
    }

    func trackTrialStarted(productId: String) {
        // Adjust disabled - no-op
    }

    func trackTrialConverted(productId: String) {
        // Adjust disabled - no-op
    }
}

