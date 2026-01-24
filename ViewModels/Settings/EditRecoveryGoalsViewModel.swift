//
//  EditRecoveryGoalsViewModel.swift
//  Checkpoint
//
//  ViewModel for editing recovery goals
//

import SwiftUI
import Combine

// MARK: - Notification for goals updates

extension Notification.Name {
    static let recoveryGoalsDidUpdate = Notification.Name("recoveryGoalsDidUpdate")
}

@MainActor
class EditRecoveryGoalsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var selectedGoals: Set<String> = []
    @Published var customGoals: [String] = []
    @Published var newCustomGoal: String = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var saveSuccessful = false

    // MARK: - Available Goals (predefined)

    let availableGoals = [
        "Stop gambling completely",
        "Save money",
        "Repair relationships",
        "Reduce stress and anxiety",
        "Take back control of my life",
        "Be a better parent/partner",
        "Improve my mental health",
        "Build financial stability",
        "Get out of debt",
        "Be more present with family",
        "Sleep better at night",
        "Regain self-respect",
        "Stop lying to loved ones",
        "Have money for emergencies",
        "Feel in control again"
    ]

    // MARK: - Private Properties

    private let authService = AuthenticationService.shared
    private let supabase = SupabaseClientManager.shared
    private var originalSelectedGoals: Set<String> = []
    private var originalCustomGoals: [String] = []

    // MARK: - Computed Properties

    /// All goals combined (predefined selections + custom)
    var allGoals: [String] {
        Array(selectedGoals) + customGoals
    }

    /// Check if there are any changes from original
    var hasChanges: Bool {
        selectedGoals != originalSelectedGoals || customGoals != originalCustomGoals
    }

    /// Can save if there's at least one goal and changes were made
    var canSave: Bool {
        !allGoals.isEmpty && hasChanges && !isSaving
    }

    /// Can add a new custom goal
    var canAddCustomGoal: Bool {
        let trimmed = newCustomGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !customGoals.contains(trimmed)
    }

    // MARK: - Public Methods

    func toggleGoal(_ goal: String) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }

    func addCustomGoal() {
        let trimmed = newCustomGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !customGoals.contains(trimmed) else { return }
        customGoals.insert(trimmed, at: 0)  // Add to beginning so newest appears first
        newCustomGoal = ""
    }

    func removeCustomGoal(_ goal: String) {
        customGoals.removeAll { $0 == goal }
    }

    func loadCurrentGoals() {
        isLoading = true

        // Load from UserDefaults cache
        let savedGoals = UserDefaults.standard.array(forKey: "recovery_goals") as? [String] ?? []

        // Separate predefined goals from custom ones
        let predefinedSet = Set(availableGoals)
        var predefined: Set<String> = []
        var custom: [String] = []

        for goal in savedGoals {
            if predefinedSet.contains(goal) {
                predefined.insert(goal)
            } else {
                custom.append(goal)
            }
        }

        selectedGoals = predefined
        customGoals = custom
        originalSelectedGoals = predefined
        originalCustomGoals = custom

        isLoading = false
    }

    func saveGoals() async {
        guard let userIdString = authService.currentSession?.userId,
              let userId = UUID(uuidString: userIdString) else {
            errorMessage = "Unable to save. Please try again."
            showError = true
            return
        }

        let goalsToSave = allGoals

        isSaving = true

        do {
            // Update in Supabase
            try await updateGoalsInDatabase(userId: userId, goals: goalsToSave)

            // Update local cache
            UserDefaults.standard.set(goalsToSave, forKey: "recovery_goals")

            // Update original values
            originalSelectedGoals = selectedGoals
            originalCustomGoals = customGoals

            // Post notification so other views can refresh
            NotificationCenter.default.post(name: .recoveryGoalsDidUpdate, object: nil)

            saveSuccessful = true
            isSaving = false

        } catch {
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            showError = true
            isSaving = false
        }
    }

    // MARK: - Private Methods

    private func updateGoalsInDatabase(userId: UUID, goals: [String]) async throws {
        struct GoalsUpdate: Encodable {
            let recovery_goals: [String]
            let updated_at: String
        }

        let updates = GoalsUpdate(
            recovery_goals: goals,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase.database
            .from("user_profiles")
            .update(updates)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
}
