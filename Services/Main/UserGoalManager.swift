//
//  UserGoalManager.swift
//  Checkpoint
//
//  Manages user's protection goal (NUCLEAR-ONLY mode)
//  All users now get complete 24/7 protection with no unlock capability
//

import Foundation
import Combine

enum UserGoal: String {
    case nuclear = "nuclear"  // Complete 24/7 protection (only option now)

    // Legacy for backwards compatibility with existing user data
    case soberOnly = "sober_only"  // Deprecated - migrated to nuclear
}

@MainActor
class UserGoalManager: ObservableObject {

    // MARK: - Singleton

    static let shared = UserGoalManager()

    // MARK: - Published State

    /// Current user goal (always nuclear for new users)
    @Published private(set) var currentGoal: UserGoal = .nuclear

    /// Whether user can pass checkpoints to unlock (always false in nuclear-only mode)
    var canPassCheckpoint: Bool {
        false  // No checkpoints in nuclear-only mode
    }

    /// Whether user is in nuclear mode (always true)
    var isNuclearMode: Bool {
        true  // All users are nuclear now
    }

    // MARK: - UserDefaults Key

    private let userGoalKey = "user_goal"

    // MARK: - Initialization

    private init() {
        loadGoal()
    }

    // MARK: - Public Methods

    /// Load goal from UserDefaults (migrates legacy sober_only to nuclear)
    func loadGoal() {
        if let goalString = UserDefaults.standard.string(forKey: userGoalKey),
           let goal = UserGoal(rawValue: goalString) {
            // Migrate legacy sober_only users to nuclear
            if goal == .soberOnly {
                currentGoal = .nuclear
                UserDefaults.standard.set(UserGoal.nuclear.rawValue, forKey: userGoalKey)
            } else {
                currentGoal = goal
            }
        } else {
            // Default to nuclear for new users
            currentGoal = .nuclear
            UserDefaults.standard.set(UserGoal.nuclear.rawValue, forKey: userGoalKey)
        }
    }

    /// Save goal to UserDefaults (always saves nuclear now)
    func saveGoal(_ goal: UserGoal) {
        // Force nuclear mode regardless of what's passed
        currentGoal = .nuclear
        UserDefaults.standard.set(UserGoal.nuclear.rawValue, forKey: userGoalKey)
    }

    /// Clear goal (for testing or account deletion)
    func clearGoal() {
        currentGoal = .nuclear  // Reset to nuclear instead of nil
        UserDefaults.standard.set(UserGoal.nuclear.rawValue, forKey: userGoalKey)
    }
}
