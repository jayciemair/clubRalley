//
//  OnboardingFlowController.swift
//  Dial
//
//  Created on 2025-07-21
//  Main orchestrator for the JSON-driven onboarding flow system
//

import SwiftUI
import Combine

/// Main controller that manages the onboarding flow state and navigation
@MainActor
class OnboardingFlowController: ObservableObject {
    
    // MARK: - Published Properties
    /// Current screen being displayed
    @Published var currentScreen: ScreenConfig?
    
    /// Progress through the onboarding flow (0.0 to 1.0)
    @Published var flowProgress: Double = 0.0
    
    /// Loading state for flow configuration
    @Published var isLoading = false
    
    /// Any error that occurred during flow loading or navigation
    @Published var error: OnboardingError?
    
    /// Whether the onboarding is complete
    @Published var isComplete = false
    
    /// Whether the user wants to exit the onboarding flow
    @Published var shouldExitFlow = false
    
    // MARK: - Private Properties
    /// The loaded flow configuration
    internal var flowConfiguration: FlowConfiguration?
    
    /// History of screens visited (for analytics and back navigation)
    var screenHistory: [String] = []
    
    /// Data collected during onboarding, keyed by screen ID
    private var collectedData: [String: Any] = [:]
    
    /// User defaults for persistence
    private let userDefaults = UserDefaults.standard
    
    /// Key for storing onboarding progress
    private let progressKey = "onboarding.progress"
    
    /// Key for storing collected data
    private let dataKey = "onboarding.collectedData"
    
    /// Current index in the screen array
    internal var currentScreenIndex: Int = 0
    
    /// State manager for persistence
    private let stateManager = OnboardingStateManager.shared
    
    // MARK: - Initialization
    init() {
        // Will check for saved progress after flow loads
        currentScreen = nil
    }
    
    // MARK: - Public Methods
    
    /// Load a specific flow configuration - DEPRECATED: Use startSimplifiedFlow instead
    /// - Parameter type: The type of flow to load
    @available(*, deprecated, message: "Use startSimplifiedFlow instead")
    func loadFlow(type: FlowType) async {
        // This method is deprecated - use startSimplifiedFlow instead
        startSimplifiedFlow(type: type)
    }

    /// Set the flow type and load it (synchronous wrapper for deletion prevention)
    /// Used to initiate flows from Settings or other UI contexts
    func setFlowType(_ type: FlowType) {
        startSimplifiedFlow(type: type)
    }

    /// Check for saved progress and restore if valid
    func checkForSavedProgress() {
        guard let flow = flowConfiguration else { return }

        if let savedProgress = stateManager.loadProgress(),
           savedProgress.flowId == flow.id,
           !savedProgress.isExpired {

            // Find the saved screen in current flow
            if let savedScreen = flow.screen(withId: savedProgress.currentScreenId) {
                // Restore to saved position
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentScreen = savedScreen
                    currentScreenIndex = savedProgress.currentScreenIndex
                    screenHistory = Array(savedProgress.completedScreenIds)
                    if !screenHistory.contains(savedScreen.id) {
                        screenHistory.append(savedScreen.id)
                    }
                }
                updateProgress()

                // Also restore collected data from this session
                if let savedData = userDefaults.data(forKey: dataKey),
                   let decoded = try? JSONSerialization.jsonObject(with: savedData) as? [String: Any] {
                    collectedData = decoded
                }
            }
        }
    }
    
    /// Navigate to the next screen in the flow
    func navigateNext() {
        guard let current = currentScreen,
              let flow = flowConfiguration else {
            return
        }

        // Save current screen to history before leaving
        if !screenHistory.contains(current.id) {
            screenHistory.append(current.id)
        }

        // Determine the next screen based on conditional logic
        var nextScreenId = current.nextScreen

        // Nuclear-only mode - no conditional navigation needed
        // All users follow the same path

        // Update index and save progress
        if let currentIndex = flow.screens.firstIndex(where: { $0.id == current.id }) {
            currentScreenIndex = currentIndex + 1
        }
        saveProgressToStateManager()

        // Find and navigate to next screen
        if let nextId = nextScreenId,
           let nextScreen = flow.screen(withId: nextId) {
            // Navigate to next screen (it will be added to history when we leave it)
            currentScreen = nextScreen

                    } else {
            // No next screen means flow is complete
            print("[debugRefactorFlows] 🎯 OnboardingFlowController.advance() - No next screen, calling completeOnboarding()")
            print("[debugRefactorFlows] 🎯 Current screen ID: \(currentScreen?.id ?? "nil")")
            print("[debugRefactorFlows] 🎯 Collected data keys: \(collectedData.keys.sorted())")
            completeOnboarding()
        }

        updateProgress()
    }
    
    /// Skip the current screen (if allowed)
    func skip() {
        guard let current = currentScreen,
              current.isSkippable,
              let flow = flowConfiguration else { return }
        
        // Track that this screen was skipped
        saveData(for: current.id, data: ["skipped": true])
        
        // Navigate to skip destination or next screen
        if let skipToId = current.skipToScreen,
           let skipToScreen = flow.screen(withId: skipToId) {
            currentScreen = skipToScreen
        } else {
            navigateNext()
        }
        
        updateProgress()
    }
    
    /// Navigate back to the previous screen or exit if at entry screen
    func navigateBack() {
        guard let flow = flowConfiguration,
              let currentId = currentScreen?.id else {
            return
        }

        // Remove current screen from history
        if let lastScreen = screenHistory.last, lastScreen == currentId {
            screenHistory.removeLast()
        }

        // Use screen history to find the actual previous screen (respects conditional navigation)
        if let previousScreenId = screenHistory.last,
           let previousScreen = flow.screen(withId: previousScreenId) {

            // Update index
            if let newIndex = flow.screens.firstIndex(where: { $0.id == previousScreen.id }) {
                currentScreenIndex = newIndex
            }

            self.currentScreen = previousScreen

            // Save the new position
            saveProgressToStateManager()
            updateProgress()
        } else {
            // No history - we're at the first screen, exit flow
            shouldExitFlow = true
        }
    }
    
    /// Save data collected from a specific screen
    /// - Parameters:
    ///   - screenId: The ID of the screen
    ///   - data: The data to save
    func saveData(for screenId: String, data: [String: Any]) {
        collectedData[screenId] = data
        
        // Persist to UserDefaults
        if let encoded = try? JSONSerialization.data(withJSONObject: collectedData) {
            userDefaults.set(encoded, forKey: dataKey)
        }
    }
    
    /// Retrieve saved data for a specific screen
    /// - Parameter screenId: The ID of the screen
    /// - Returns: The saved data, if any
    func getData(for screenId: String) -> [String: Any]? {
        return collectedData[screenId] as? [String: Any]
    }
    
    /// Get all collected data from the onboarding session
    /// - Returns: Dictionary containing all collected data from all screens
    func getAllCollectedData() -> [String: Any] {
        return collectedData
    }
    
    /// Navigate to a specific screen by ID
    func navigateToScreen(withId screenId: String) {
        guard let flow = flowConfiguration,
              let targetScreen = flow.screens.first(where: { $0.id == screenId }) else {
            return
        }
        
        // Don't navigate if already on target screen
        if currentScreen?.id == screenId {
            return
        }

        // Add current screen to history before leaving
        if let currentId = currentScreen?.id, !screenHistory.contains(currentId) {
            screenHistory.append(currentId)
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            currentScreen = targetScreen
        }
        updateProgress()
    }
    
    /// Reset all onboarding progress and data
    func resetOnboarding() {
        currentScreen = nil
        screenHistory.removeAll()
        collectedData.removeAll()
        flowProgress = 0.0
        isComplete = false
        shouldExitFlow = false
        
        // Clear from UserDefaults
        userDefaults.removeObject(forKey: progressKey)
        userDefaults.removeObject(forKey: "\(progressKey).currentScreen")
        userDefaults.removeObject(forKey: dataKey)
    }

    // MARK: - Private Methods
    // JSON loading methods removed - using direct code-based flow definition now
    
    /// Update the flow progress based on current screen
    internal func updateProgress() {
        guard let flow = flowConfiguration,
              let current = currentScreen else {
            flowProgress = 0.0
            return
        }
        
        flowProgress = flow.progress(for: current.id)
    }
    
    /// Save current progress to state manager
    internal func saveProgressToStateManager() {
        guard let current = currentScreen,
              let flow = flowConfiguration else { return }
        
        let progress = OnboardingProgress(
            flowId: flow.id,
            flowVersion: flow.version ?? "1.0.0",
            currentScreenId: current.id,
            currentScreenIndex: currentScreenIndex,
            completedScreenIds: Set(screenHistory)
        )
        
        stateManager.saveProgress(progress)
    }
    
    /// Save current progress to UserDefaults (legacy - now uses state manager)
    private func saveProgress() {
        saveProgressToStateManager()
    }
    

    /// Complete the onboarding flow
    internal func completeOnboarding() {
        print("[debugRefactorFlows] 🔥 OnboardingFlowController.completeOnboarding() CALLED")
        print("[debugRefactorFlows] 🔥 isComplete before: \(isComplete)")

        // Guard against double-completion
        guard !isComplete else {
            print("⚠️ [ONBOARDING] completeOnboarding() called but already complete - skipping")
            print("[debugRefactorFlows] ⚠️ Double-completion prevented!")
            return
        }

        print("[debugRefactorFlows] 🔥 Setting isComplete = true")
        print("[debugRefactorFlows] 🔥 Collected data: \(collectedData)")

        isComplete = true

        // Save completion status
        userDefaults.set(true, forKey: "onboarding.completed")
        userDefaults.set(Date(), forKey: "onboarding.completionDate")

        // Clear progress data (but keep collected data)
        userDefaults.removeObject(forKey: progressKey)
        userDefaults.removeObject(forKey: "\(progressKey).currentScreen")

        // Save onboarding data to Supabase
        Task {
            await saveOnboardingDataToSupabase()
        }

        // Post notification for other parts of the app
        NotificationCenter.default.post(
            name: .onboardingCompleted,
            object: nil,
            userInfo: ["data": collectedData]
        )
    }

    /// Save collected onboarding data to Supabase
    private func saveOnboardingDataToSupabase() async {
        do {
            guard let session = try await SupabaseClientManager.shared.getCurrentSession() else {
                print("⚠️ [ONBOARDING] No session found, cannot save onboarding data to Supabase")
                return
            }

            let userId = session.user.id
            print("📤 [ONBOARDING] Saving onboarding data to Supabase for user: \(userId)")

            // Extract individual fields from collected data
            let name = (collectedData["user_name"] as? [String: Any])?["name"] as? String
            let breakupTiming = (collectedData["breakup_timing"] as? [String: Any])?["timing"] as? String
            let whoEndedIt = (collectedData["who_ended_it"] as? [String: Any])?["selected"] as? String
            let checkinFrequency = (collectedData["checkin_frequency"] as? [String: Any])?["frequency"] as? Int

            // Parse array fields (stored as [String] arrays)
            var whatsHurting: [String]? = nil
            if let whatsHurtingData = collectedData["whats_hurting"] as? [String: Any],
               let array = whatsHurtingData["selected"] as? [String] {
                whatsHurting = array
            }

            var howCoping: [String]? = nil
            if let howCopingData = collectedData["how_coping"] as? [String: Any],
               let array = howCopingData["selected"] as? [String] {
                howCoping = array
            }

            var mainGoals: [String]? = nil
            if let mainGoalsData = collectedData["main_goals"] as? [String: Any],
               let array = mainGoalsData["selected"] as? [String] {
                mainGoals = array
            }

            let fields = OnboardingFieldsUpdate(
                name: name,
                breakup_timing: breakupTiming,
                who_ended_it: whoEndedIt,
                whats_hurting: whatsHurting,
                how_coping: howCoping,
                main_goals: mainGoals,
                checkin_frequency: checkinFrequency
            )

            try await UserProfileService.shared.saveOnboardingFields(userId: userId, fields: fields)
            print("✅ [ONBOARDING] Onboarding fields saved to Supabase")

        } catch {
            print("❌ [ONBOARDING] Failed to save onboarding data to Supabase: \(error.localizedDescription)")
        }
    }
}

// MARK: - Error Types
enum OnboardingError: LocalizedError, Equatable {
    case configNotFound(type: FlowType)
    case invalidConfiguration(underlying: Error)
    case emptyFlow
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .configNotFound(let type):
            return "Could not find onboarding configuration for flow type: \(type.rawValue)"
        case .invalidConfiguration(let error):
            return "Invalid onboarding configuration: \(error.localizedDescription)"
        case .emptyFlow:
            return "The onboarding flow contains no screens"
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Equatable
    static func == (lhs: OnboardingError, rhs: OnboardingError) -> Bool {
        switch (lhs, rhs) {
        case (.configNotFound(let lhsType), .configNotFound(let rhsType)):
            return lhsType == rhsType
        case (.emptyFlow, .emptyFlow):
            return true
        case (.invalidConfiguration(let lhsError), .invalidConfiguration(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let onboardingCompleted = Notification.Name("com.dial.onboarding.completed")
}