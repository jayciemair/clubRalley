//
//  RecoveryProgressService.swift
//  Checkpoint
//
//  Service for managing recovery progress persistence
//

import Foundation
import StoreKit

@MainActor
class RecoveryProgressService {

    // MARK: - Debug Configuration

    /// Set to true to unlock all recovery modules for debugging/testing
    /// Set to false for production to enforce sequential unlocking
    static let debugUnlockAllModules = false

    // MARK: - Trial Detection

    /// Check if user is currently in a free trial period (iOS 17.2+)
    private static func isInFreeTrial() async -> Bool {
        print("[debugSubscription] 🔍 Checking trial status...")

        for await verificationResult in Transaction.currentEntitlements {
            switch verificationResult {
            case .verified(let transaction):
                print("[debugSubscription] ✅ Found verified transaction: \(transaction.productID)")

                // iOS 17.2+ - Use the new offer.paymentMode API for reliable trial detection
                if #available(iOS 17.2, *) {
                    if let offer = transaction.offer {
                        print("[debugSubscription] 📦 iOS 17.2+ - Offer found: \(offer.id ?? "no ID")")
                        print("[debugSubscription] 💳 Payment mode: \(String(describing: offer.paymentMode))")

                        if offer.paymentMode == .freeTrial {
                            print("[debugSubscription] 🎟️ DETECTED: User is in FREE TRIAL (iOS 17.2+ API)")
                            return true
                        } else {
                            print("[debugSubscription] ❌ Not a free trial - paymentMode is not .freeTrial")
                        }
                    } else {
                        print("[debugSubscription] ⚠️ iOS 17.2+ but no offer on transaction")
                    }
                } else {
                    print("[debugSubscription] ⚠️ iOS < 17.2 - Using fallback offerType detection")

                    if transaction.offerType == .introductory {
                        print("[debugSubscription] 🎟️ DETECTED: User is in FREE TRIAL (offerType fallback)")
                        return true
                    } else {
                        print("[debugSubscription] ❌ offerType is not .introductory: \(String(describing: transaction.offerType))")
                    }
                }
            case .unverified:
                print("[debugSubscription] ⚠️ Unverified transaction - skipping")
                continue
            }
        }

        print("[debugSubscription] ❌ No trial detected - user is NOT in trial")
        return false
    }

    /// Get days since subscription started (for time-gated module unlocking)
    private static func daysSinceSubscriptionStart() async -> Int {
        print("[debugSubscription] 🔍 Calculating days since subscription...")

        for await verificationResult in Transaction.currentEntitlements {
            switch verificationResult {
            case .verified(let transaction):
                let calendar = Calendar.current
                let days = calendar.dateComponents([.day], from: transaction.purchaseDate, to: Date()).day ?? 0

                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short

                print("[debugSubscription] 📅 Subscription purchase date: \(dateFormatter.string(from: transaction.purchaseDate))")
                print("[debugSubscription] 📅 Current date: \(dateFormatter.string(from: Date()))")
                print("[debugSubscription] 📅 Days since subscription started: \(days)")

                return max(0, days)
            case .unverified:
                print("[debugSubscription] ⚠️ Unverified transaction - skipping")
                continue
            }
        }

        print("[debugSubscription] ❌ No entitlements found - returning 0 days")
        return 0
    }

    /// Get days remaining in free trial (returns nil if not in trial)
    static func daysRemainingInTrial() async -> Int? {
        for await verificationResult in Transaction.currentEntitlements {
            switch verificationResult {
            case .verified(let transaction):
                // iOS 17.2+ - Check for free trial using offer.paymentMode
                if #available(iOS 17.2, *) {
                    if let offer = transaction.offer,
                       offer.paymentMode == .freeTrial,
                       let expirationDate = transaction.expirationDate {
                        let calendar = Calendar.current
                        let days = calendar.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
                        return max(0, days)
                    }
                } else {
                    // Fallback for older iOS versions
                    if transaction.offerType == .introductory,
                       let expirationDate = transaction.expirationDate {
                        let calendar = Calendar.current
                        let days = calendar.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
                        return max(0, days)
                    }
                }
            case .unverified:
                continue
            }
        }
        return nil
    }

    // MARK: - Singleton

    static let shared = RecoveryProgressService()

    // MARK: - Dependencies

    private let authService = AuthenticationService.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Unit Structure

    /// Get the lesson counts per unit (used for calculating unit/position)
    private func getLessonCountsPerUnit() -> [Int] {
        return [
            Unit1Lessons.lessons.count,
            Unit2Lessons.lessons.count,
            Unit3Lessons.lessons.count,
            Unit4Lessons.lessons.count
        ]
    }

    /// Calculate which unit and position within unit for a given lesson index
    private func getUnitInfo(for index: Int) -> (unitNumber: Int, positionInUnit: Int) {
        let lessonCounts = getLessonCountsPerUnit()
        var cumulativeCount = 0

        for (unitIndex, count) in lessonCounts.enumerated() {
            if index < cumulativeCount + count {
                return (unitIndex + 1, index - cumulativeCount + 1)
            }
            cumulativeCount += count
        }

        // Fallback (should never reach here)
        return (4, index + 1)
    }

    /// Check if index is the first lesson of a unit
    private func isFirstLessonOfUnit(index: Int) -> Bool {
        let lessonCounts = getLessonCountsPerUnit()
        var cumulativeCount = 0

        for count in lessonCounts {
            if index == cumulativeCount {
                return true
            }
            cumulativeCount += count
        }

        return false
    }

    // MARK: - Public Methods

    /// Load completed modules from database and calculate unlock status
    func loadCompletions(for exercises: [Exercise]) async -> [Exercise] {
        print("[debugProgram] 📥 loadCompletions called")

        guard let userId = authService.currentSession?.userId else {
            print("[debugProgram] ⚠️ No user session, loading from cache")
            return await loadCompletionsFromCache(for: exercises)
        }

        do {
            let client = SupabaseClientManager.shared.client

            // Fetch user's account creation date
            print("[debugProgram] 🔍 Fetching user creation date for: \(userId)")
            struct UserData: Decodable {
                let created_at: String
            }

            let userData: [UserData] = try await client.from("users")
                .select("created_at")
                .eq("id", value: userId)
                .execute()
                .value

            print("[debugProgram] 📦 Received userData count: \(userData.count)")
            if let first = userData.first {
                print("[debugProgram] 📦 Raw created_at string: '\(first.created_at)'")
            } else {
                print("[debugProgram] ❌ userData is empty!")
            }

            // Calculate days since account creation
            var daysSinceCreation = 0
            if let createdAtString = userData.first?.created_at {
                // Configure ISO8601 formatter to handle fractional seconds
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                if let createdAt = formatter.date(from: createdAtString) {
                    let calendar = Calendar.current
                    let today = Date()
                    let days = calendar.dateComponents([.day], from: createdAt, to: today).day ?? 0
                    daysSinceCreation = max(0, days)

                    // Debug: Show exact dates
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    dateFormatter.timeStyle = .short
                    print("[debugProgram] 🗓️ User created at: \(dateFormatter.string(from: createdAt))")
                    print("[debugProgram] 🗓️ Today's date: \(dateFormatter.string(from: today))")
                    print("[debugProgram] 📅 Days since creation: \(daysSinceCreation)")

                    // Cache creation date for offline access
                    UserDefaults.standard.set(createdAt, forKey: "user_join_date")
                } else {
                    print("[debugProgram] ❌ Failed to parse created_at date!")
                    print("[debugProgram] ❌ Attempted to parse: '\(createdAtString)'")
                }
            }

            // Fetch completed modules from database
            print("[debugProgram] 🔍 Fetching completed modules for user: \(userId)")
            let response: [RecoveryProgress] = try await client.from("user_recovery_progress")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            // Extract completed module types
            let completedTypes = response.map { $0.moduleType }
            print("[debugProgram] 📋 Found completed modules: \(completedTypes)")

            // Mark exercises as completed AND set unlock status
            var updatedExercises = exercises

            // Check if user is in free trial
            let isInTrial = await Self.isInFreeTrial()
            let hasActiveSubscription = StoreManager.shared.hasActiveSubscription
            let daysSinceSubscription = await Self.daysSinceSubscriptionStart()

            // Debug: Print subscription status summary
            print("[debugSubscription] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("[debugSubscription] 📊 SUBSCRIPTION STATUS SUMMARY")
            print("[debugSubscription] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("[debugSubscription] 📊 Has Active Subscription: \(hasActiveSubscription)")
            print("[debugSubscription] 🎟️ Is In Trial: \(isInTrial)")
            print("[debugSubscription] 📅 Days Since Subscription: \(daysSinceSubscription)")
            print("[debugSubscription] 🔓 Access Level: \(isInTrial ? "Cap at Lesson 3 (Trial)" : "All Lessons (Paid)")")
            print("[debugSubscription] 🐛 Debug Mode: \(Self.debugUnlockAllModules)")
            print("[debugSubscription] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

            for (index, exercise) in exercises.enumerated() {
                var updated = updatedExercises[index]

                // Set completion status
                if completedTypes.contains(exercise.slug) {
                    updated.isCompleted = true
                    print("[debugProgram] ✅ Marking \(exercise.title) as completed")
                }

                // Determine which unit this module belongs to
                let unitInfo = getUnitInfo(for: index)
                let unitNumber = unitInfo.unitNumber
                let positionInUnit = unitInfo.positionInUnit

                // Check unlock eligibility
                let hasDebugMode = Self.debugUnlockAllModules
                let hasPaidSubscription = hasActiveSubscription && !isInTrial

                // Trial users: sequential unlock capped at first 3 lessons
                // Paid users: all units accessible with sequential unlock within each unit
                var isModuleUnlocked = false

                // Debug mode bypasses ALL unlock logic
                if hasDebugMode {
                    isModuleUnlocked = true
                } else if isInTrial {
                    // Trial: Sequential unlock with hard cap at Lesson 3
                    // Lesson 1: Always unlocked
                    // Lesson 2: Unlocked after completing Lesson 1
                    // Lesson 3: Unlocked after completing Lesson 2
                    // Lesson 4+: LOCKED (must convert to paid)
                    if index < 3 {
                        if index == 0 {
                            isModuleUnlocked = true
                        } else {
                            // Check if previous lesson is completed
                            let previousExercise = exercises[index - 1]
                            isModuleUnlocked = completedTypes.contains(previousExercise.slug)
                        }
                    }

                    print("[debugSubscription] 🎟️ Trial User: Lesson \(index + 1) - Cap at 3, sequential unlock → \(isModuleUnlocked ? "UNLOCKED" : "LOCKED")")
                } else if hasPaidSubscription {
                    // Paid: all units, sequential within each unit
                    if isFirstLessonOfUnit(index: index) {
                        isModuleUnlocked = true
                    } else {
                        let previousExercise = exercises[index - 1]
                        isModuleUnlocked = completedTypes.contains(previousExercise.slug)
                    }
                }

                updated.isLocked = !isModuleUnlocked

                let unlockReason = isModuleUnlocked ? "UNLOCKED" : "LOCKED"
                let accessType = isInTrial ? "TRIAL" : (hasPaidSubscription ? "PAID" : "NONE")
                let previousSlugCheck = index == 0 ? "N/A" : "\(completedTypes.contains(exercises[index - 1].slug))"
                print("[debugModuleCardAccess] Lesson \(index + 1) (Unit \(unitNumber), Pos \(positionInUnit)): access=\(accessType), prevComplete=\(previousSlugCheck) → \(unlockReason)")

                updatedExercises[index] = updated
            }

            // Cache completed modules locally for offline access
            UserDefaults.standard.set(completedTypes, forKey: "completed_recovery_modules_\(userId)")

            print("[debugProgram] ✅ Loaded \(completedTypes.count) completed modules")
            return updatedExercises

        } catch {
            print("[debugProgram] ❌ Error loading completions: \(error)")
            return await loadCompletionsFromCache(for: exercises)
        }
    }

    /// Save completion to database
    func saveCompletion(exercise: Exercise) async throws {
        guard let userId = authService.currentSession?.userId else {
            print("[debugProgram] ⚠️ No user session, skipping save")
            return
        }

        // Insert completion in database
        let client = SupabaseClientManager.shared.client
        let progress = RecoveryProgress(
            userId: userId,
            moduleType: exercise.slug
        )

        try await client.from("user_recovery_progress")
            .upsert(progress)
            .execute()

        // Update local cache
        var completedTypes = UserDefaults.standard.stringArray(forKey: "completed_recovery_modules_\(userId)") ?? []
        if !completedTypes.contains(exercise.slug) {
            completedTypes.append(exercise.slug)
            UserDefaults.standard.set(completedTypes, forKey: "completed_recovery_modules_\(userId)")
        }

        // Log module_completed event for event sourcing
        if let userUUID = UUID(uuidString: userId) {
            let unitInfo = getUnitInfo(for: completedTypes.count - 1)
            await EventLoggingService.shared.logModuleCompleted(
                userId: userUUID,
                unit: "unit_\(unitInfo.unitNumber)",
                slug: exercise.slug,
                title: exercise.title
            )
        }

        print("[debugProgram] ✅ Saved completion for \(exercise.title)")
    }

    // MARK: - Private Methods

    /// Load completions from local cache as fallback
    private func loadCompletionsFromCache(for exercises: [Exercise]) async -> [Exercise] {
        guard let userId = authService.currentSession?.userId else {
            print("[debugProgram] ⚠️ No user session for cache")
            return exercises
        }

        let completedTypes = UserDefaults.standard.stringArray(forKey: "completed_recovery_modules_\(userId)") ?? []

        // Calculate unlock status based on cached creation date
        let cachedCreatedAt = UserDefaults.standard.object(forKey: "user_join_date") as? Date
        var daysSinceCreation = 0

        if let createdAt = cachedCreatedAt {
            let calendar = Calendar.current
            let days = calendar.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
            daysSinceCreation = max(0, days)
            print("[debugProgram] 📅 [Cache] Account created \(daysSinceCreation) days ago")
        } else {
            print("[debugProgram] ⚠️ No cached creation date, unlocking all")
            daysSinceCreation = 30 // Unlock all if we don't know
        }

        // Create new array to force SwiftUI update
        var updatedExercises = exercises

        // Check if user is in free trial
        let isInTrial = await Self.isInFreeTrial()
        let hasActiveSubscription = StoreManager.shared.hasActiveSubscription
        let daysSinceSubscription = await Self.daysSinceSubscriptionStart()

        // Debug: Print subscription status summary
        print("[debugSubscription] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("[debugSubscription] 📊 [CACHE] SUBSCRIPTION STATUS SUMMARY")
        print("[debugSubscription] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("[debugSubscription] 📊 Has Active Subscription: \(hasActiveSubscription)")
        print("[debugSubscription] 🎟️ Is In Trial: \(isInTrial)")
        print("[debugSubscription] 📅 Days Since Subscription: \(daysSinceSubscription)")
        print("[debugSubscription] 🔓 Access Level: \(isInTrial ? "Cap at Lesson 3 (Trial)" : "All Lessons (Paid)")")
        print("[debugSubscription] 🐛 Debug Mode: \(Self.debugUnlockAllModules)")
        print("[debugSubscription] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        for (index, exercise) in exercises.enumerated() {
            var updated = updatedExercises[index]

            // Set completion status from cache
            if completedTypes.contains(exercise.slug) {
                updated.isCompleted = true
            }

            // Determine which unit this module belongs to
            let unitInfo = getUnitInfo(for: index)
            let unitNumber = unitInfo.unitNumber
            let positionInUnit = unitInfo.positionInUnit

            // Check unlock eligibility
            let hasDebugMode = Self.debugUnlockAllModules
            let hasPaidSubscription = hasActiveSubscription && !isInTrial

            // Trial users: sequential unlock capped at first 3 lessons
            // Paid users: all units accessible with sequential unlock
            var isModuleUnlocked = false

            // Debug mode bypasses ALL unlock logic
            if hasDebugMode {
                isModuleUnlocked = true
            } else if isInTrial {
                // Trial: Sequential unlock with hard cap at Lesson 3
                if index < 3 {
                    if index == 0 {
                        isModuleUnlocked = true
                    } else {
                        // Check if previous lesson is completed
                        let previousExercise = exercises[index - 1]
                        isModuleUnlocked = completedTypes.contains(previousExercise.slug)
                    }
                }

                print("[debugSubscription] 🎟️ [Cache] Trial User: Lesson \(index + 1) - Cap at 3, sequential unlock → \(isModuleUnlocked ? "UNLOCKED" : "LOCKED")")
            } else if hasPaidSubscription {
                // Paid: all units, sequential within each unit
                if isFirstLessonOfUnit(index: index) {
                    isModuleUnlocked = true
                } else {
                    let previousExercise = exercises[index - 1]
                    isModuleUnlocked = completedTypes.contains(previousExercise.slug)
                }
            }

            updated.isLocked = !isModuleUnlocked

            let unlockReason = isModuleUnlocked ? "UNLOCKED" : "LOCKED"
            let accessType = isInTrial ? "TRIAL" : (hasPaidSubscription ? "PAID" : "NONE")
            print("[debugModuleCardAccess] [Cache] Lesson \(index + 1) (Unit \(unitNumber), Pos \(positionInUnit)): access=\(accessType) → \(unlockReason)")

            updatedExercises[index] = updated
        }

        print("[debugProgram] 📦 Loaded \(completedTypes.count) completions from cache")
        return updatedExercises
    }
}
