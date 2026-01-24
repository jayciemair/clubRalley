//
//  OnboardingStateManager.swift
//  Dial
//
//  Manages persistence of onboarding progress
//

import Foundation
import os.log

/// Manages saving, loading, and validating onboarding progress
final class OnboardingStateManager {
    
    // MARK: - Singleton
    
    static let shared = OnboardingStateManager()
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private let progressKey = "com.dial.onboarding.progress"
    private let logger = Logger(subsystem: "com.dial", category: "OnboardingState")
    
    /// Current flow version - should match flow JSON
    private let currentFlowVersion = "1.0.0"
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Save the current onboarding progress
    func saveProgress(_ progress: OnboardingProgress) {
        logger.info("Saving onboarding progress at screen: \(progress.currentScreenId)")
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(progress)
            userDefaults.set(data, forKey: progressKey)
            userDefaults.synchronize() // Force synchronization for immediate persistence
            
            logger.info("Successfully saved onboarding progress")
        } catch {
            logger.error("Failed to save onboarding progress: \(error.localizedDescription)")
        }
    }
    
    /// Load saved onboarding progress
    func loadProgress() -> OnboardingProgress? {
        guard let data = userDefaults.data(forKey: progressKey) else {
            logger.info("No saved onboarding progress found")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let progress = try decoder.decode(OnboardingProgress.self, from: data)
            
            // Validate the loaded progress
            if let validatedProgress = validateProgress(progress) {
                logger.info("Loaded valid onboarding progress from screen: \(validatedProgress.currentScreenId)")
                return validatedProgress
            } else {
                logger.warning("Loaded progress was invalid, clearing...")
                clearProgress()
                return nil
            }
        } catch {
            logger.error("Failed to decode onboarding progress: \(error.localizedDescription)")
            clearProgress()
            return nil
        }
    }
    
    /// Clear all saved progress
    func clearProgress() {
        logger.info("Clearing onboarding progress")
        userDefaults.removeObject(forKey: progressKey)
        userDefaults.synchronize()
    }
    
    /// Check if we should resume onboarding
    func shouldResumeOnboarding() -> Bool {
        guard let progress = loadProgress() else { return false }
        
        // Don't resume if progress is expired
        if progress.isExpired {
            logger.info("Onboarding progress expired, starting fresh")
            clearProgress()
            return false
        }
        
        // Don't resume if we're at the very beginning
        if progress.currentScreenIndex == 0 {
            return false
        }
        
        return true
    }
    
    /// Create initial progress for a new onboarding session
    func createInitialProgress(
        flowId: String,
        flowVersion: String,
        firstScreenId: String
    ) -> OnboardingProgress {
        return OnboardingProgress(
            flowId: flowId,
            flowVersion: flowVersion,
            currentScreenId: firstScreenId,
            currentScreenIndex: 0
        )
    }
    
    // MARK: - Private Methods
    
    /// Validate that saved progress is still valid
    private func validateProgress(_ progress: OnboardingProgress) -> OnboardingProgress? {
        // Check if expired
        if progress.isExpired {
            logger.warning("Progress is expired (older than 24 hours)")
            return nil
        }
        
        // Check version compatibility
        if !isVersionCompatible(progress.flowVersion) {
            logger.warning("Progress version \(progress.flowVersion, privacy: .public) incompatible with current \(self.currentFlowVersion, privacy: .public)")
            return nil
        }
        
        // Additional validation can be added here
        // e.g., check if the screen still exists in current flow
        
        return progress
    }
    
    /// Check if a saved flow version is compatible with current version
    private func isVersionCompatible(_ savedVersion: String) -> Bool {
        // Simple version check - can be made more sophisticated
        // For now, require exact match for major version
        let savedMajor = savedVersion.split(separator: ".").first
        let currentMajor = currentFlowVersion.split(separator: ".").first
        
        return savedMajor == currentMajor
    }
    
    // MARK: - Migration Support
    
    /// Migrate progress from an older version if needed
    func migrateProgressIfNeeded(from oldVersion: String, to newVersion: String) {
        // Implementation for future version migrations
        // This would handle changes in flow structure between versions
        logger.info("Migration check from \(oldVersion) to \(newVersion, privacy: .public)")
        
        // Example migration logic:
        // if oldVersion == "1.0.0" && newVersion == "1.1.0" {
        //     // Perform specific migration steps
        // }
    }
    
    // MARK: - Debug Support
    
    #if DEBUG
    /// Print current saved progress for debugging
    func debugPrintProgress() {
        if let progress = loadProgress() {
        } else {
        }
    }
    #endif
}
