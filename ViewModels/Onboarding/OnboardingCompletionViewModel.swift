//
//  OnboardingCompletionViewModel.swift
//  Checkpoint
//
//  Handles onboarding completion business logic
//  Separates View from Services (proper MVVM)
//

import Foundation
import SwiftUI

/// ViewModel that handles onboarding completion logic
/// This separates business logic from the View layer
@MainActor
final class OnboardingCompletionViewModel: ObservableObject {

    // MARK: - Dependencies

    private let userProfileService = UserProfileService.shared
    private let authService = AuthenticationService.shared
    private let errorLoggingService = ErrorLoggingService.shared
    private let appLifecycleManager = AppLifecycleManager.shared

    // MARK: - Public Methods

    /// Complete onboarding for the user
    /// - Parameters:
    ///   - collectedData: Data collected during onboarding flow
    ///   - flowMetadata: Optional metadata about the flow progress (for error logging)
    /// - Throws: Error if completion fails
    func completeOnboarding(
        collectedData: [String: Any],
        flowMetadata: [String: Any]? = nil
    ) async throws {
        print("[debugRefactorFlows] 🔷 OnboardingCompletionViewModel.completeOnboarding() CALLED")
        print("🔷 [COMPLETION-VM] Starting onboarding completion")
        print("[debugRefactorFlows] 🔷 Collected data keys: \(collectedData.keys.sorted())")

        // Extract user ID from collected data
        guard let authData = collectedData["authentication"] as? [String: Any],
              let userId = authData["user_id"] as? String,
              let userUUID = UUID(uuidString: userId) else {
            print("[debugRefactorFlows] ❌ FAILED to extract user ID!")
            print("[debugRefactorFlows] ❌ authData: \(collectedData["authentication"] ?? "nil")")
            print("❌ [COMPLETION-VM] Failed to extract user ID from collected data")
            let error = NSError(domain: "OnboardingCompletion", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid user ID in onboarding data"
            ])
            throw OnboardingError.unknown(error)
        }

        print("[debugRefactorFlows] 🔷 User ID extracted: \(userUUID.uuidString)")
        print("🔷 [COMPLETION-VM] User ID: \(userUUID.uuidString)")

        // 1. Onboarding is marked complete when user record is created (no UPDATE needed)
        print("[debugRefactorFlows] ✅ User already created with has_completed_onboarding=true")
        print("✅ [COMPLETION-VM] Database already has onboarding marked complete")

        // 2. Refresh onboarding status
        print("[debugRefactorFlows] 🔄 Calling authService.refreshOnboardingStatus()")
        print("🔄 [COMPLETION-VM] Refreshing onboarding status...")
        await authService.refreshOnboardingStatus()
        print("[debugRefactorFlows] ✅ authService.refreshOnboardingStatus() DONE")

        // 3. Log journey_started event for event sourcing
        if let savingsRate = extractSavingsRate(from: collectedData) {
            await EventLoggingService.shared.logJourneyStarted(
                userId: userUUID,
                savingsRate: savingsRate
            )
            print("📊 [COMPLETION-VM] Logged journey_started event")
        }

        // 4. Post-completion tasks moved to AFTER setup completes
        // (Setup is screens 45-50, so don't call handleOnboardingComplete yet)
        print("[debugRefactorFlows] ℹ️ Skipping post-completion tasks - will run after setup completes")

        print("[debugRefactorFlows] 🎉 ALL STEPS COMPLETE!")
        print("🎉 [COMPLETION-VM] Onboarding completion successful!")
    }

    // MARK: - Private Methods

    /// Extract savings rate from collected onboarding data
    private func extractSavingsRate(from data: [String: Any]) -> Double? {
        guard let betCountData = data["daily_bet_count"] as? [String: Any],
              let betAmountData = data["average_bet_amount"] as? [String: Any],
              let gamblingDaysData = data["gambling_days"] as? [String: Any],
              let dailyBets = betCountData["daily_bet_count"] as? Int,
              let avgBet = betAmountData["average_bet_amount"] as? Double,
              let daysPerWeek = gamblingDaysData["day_count"] as? Int else {
            return nil
        }

        // savings_per_second = (average_bet * daily_bets * days_per_week) / 604800
        let weeklyLoss = avgBet * Double(dailyBets) * Double(daysPerWeek)
        let savingsPerSecond = weeklyLoss / 604800.0  // seconds in a week
        return savingsPerSecond
    }
}
