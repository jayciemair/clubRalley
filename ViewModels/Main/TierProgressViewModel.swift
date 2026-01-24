//
//  TierProgressViewModel.swift
//  Checkpoint
//
//  ViewModel for managing tier progression and unlock logic
//

import Foundation
import SwiftUI

@MainActor
class TierProgressViewModel: ObservableObject {
    @Published var currentTier: StreakTier = .heartbreak
    @Published var nextTier: StreakTier?
    @Published var daysUntilNextTier: Int = 7
    @Published var quitDate: Date?
    @Published var currentStreak: Int = 0

    // Calculate current tier and next unlock info
    func updateTierInfo(streak: Int, quitDate: Date?) {
        self.currentStreak = streak
        self.quitDate = quitDate
        self.currentTier = StreakTier(fromStreak: streak)
        self.nextTier = currentTier.nextTier

        // Calculate days until next tier unlock
        if let nextTierDays = currentTier.daysToNextTier {
            daysUntilNextTier = nextTierDays - streak
        }
    }
}
