//
//  OnboardingProgressModel.swift
//  Dial
//
//  Data model for persisting onboarding progress
//

import Foundation

/// Model representing the current state of onboarding progress
struct OnboardingProgress: Codable {
    // MARK: - Core Properties
    
    /// The flow type being followed (e.g., "defaultFlow")
    let flowId: String
    
    /// Version of the flow configuration
    let flowVersion: String
    
    /// ID of the current screen
    let currentScreenId: String
    
    /// Index in the flow array for quick lookup
    let currentScreenIndex: Int
    
    /// IDs of screens that have been completed
    let completedScreenIds: Set<String>
    
    // MARK: - Metadata
    
    /// When this progress was last updated
    let lastUpdated: Date
    
    /// Unique session identifier for analytics
    let sessionId: UUID
    
    /// When the onboarding session started
    let sessionStartDate: Date
    
    // MARK: - User Data
    
    /// Any data collected during onboarding (stored as JSON)
    let collectedData: [String: Data]
    
    // MARK: - Initialization
    
    init(
        flowId: String,
        flowVersion: String,
        currentScreenId: String,
        currentScreenIndex: Int,
        completedScreenIds: Set<String> = [],
        lastUpdated: Date = Date(),
        sessionId: UUID = UUID(),
        sessionStartDate: Date = Date(),
        collectedData: [String: Data] = [:]
    ) {
        self.flowId = flowId
        self.flowVersion = flowVersion
        self.currentScreenId = currentScreenId
        self.currentScreenIndex = currentScreenIndex
        self.completedScreenIds = completedScreenIds
        self.lastUpdated = lastUpdated
        self.sessionId = sessionId
        self.sessionStartDate = sessionStartDate
        self.collectedData = collectedData
    }
    
    // MARK: - Validation
    
    /// Check if this progress is still valid (not expired)
    /// Default expiration is 24 hours
    var isExpired: Bool {
        let expirationInterval: TimeInterval = 24 * 60 * 60 // 24 hours
        return Date().timeIntervalSince(lastUpdated) > expirationInterval
    }
    
    /// Check if a specific screen has been completed
    func hasCompleted(screenId: String) -> Bool {
        return completedScreenIds.contains(screenId)
    }
    
    // MARK: - Mutation
    
    /// Create a new progress with updated position
    func updatingPosition(
        to screenId: String,
        at index: Int,
        markingCompleted previousScreenId: String? = nil
    ) -> OnboardingProgress {
        var newCompletedIds = completedScreenIds
        if let previousId = previousScreenId {
            newCompletedIds.insert(previousId)
        }
        
        return OnboardingProgress(
            flowId: flowId,
            flowVersion: flowVersion,
            currentScreenId: screenId,
            currentScreenIndex: index,
            completedScreenIds: newCompletedIds,
            lastUpdated: Date(),
            sessionId: sessionId,
            sessionStartDate: sessionStartDate,
            collectedData: collectedData
        )
    }
    
    /// Create a new progress with additional collected data
    func addingData(key: String, data: Data) -> OnboardingProgress {
        var newData = collectedData
        newData[key] = data
        
        return OnboardingProgress(
            flowId: flowId,
            flowVersion: flowVersion,
            currentScreenId: currentScreenId,
            currentScreenIndex: currentScreenIndex,
            completedScreenIds: completedScreenIds,
            lastUpdated: Date(),
            sessionId: sessionId,
            sessionStartDate: sessionStartDate,
            collectedData: newData
        )
    }
}