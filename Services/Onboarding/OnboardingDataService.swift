//
//  OnboardingDataService.swift
//  Get Over Him
//
//  Simplified onboarding data service (lean version)
//

import Foundation
import os.log

/// Service for syncing onboarding data to Supabase
final class OnboardingDataService {

    // MARK: - Singleton

    static let shared = OnboardingDataService()

    // MARK: - Properties

    private let logger = os.Logger(subsystem: "com.getoverhim", category: "OnboardingDataSync")

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Sync onboarding data - simplified for lean schema
    func syncOnboardingData(userId: UUID, collectedData: [String: Any]) async throws {
        logger.info("📤 Onboarding data sync called for user: \(userId.uuidString)")

        // For now, we don't sync onboarding data to separate tables
        // User record is created on auth, chat messages stored when user chats
        // Onboarding answers can be stored in users.onboarding_data if needed later

        logger.info("✅ Onboarding sync complete (lean mode - no separate profile tables)")
    }
}
