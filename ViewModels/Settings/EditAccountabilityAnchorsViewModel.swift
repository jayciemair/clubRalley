//
//  EditAccountabilityAnchorsViewModel.swift
//  Checkpoint
//
//  ViewModel for editing accountability anchors
//

import SwiftUI
import Combine

// MARK: - Notification for anchor updates

extension Notification.Name {
    static let accountabilityAnchorsDidUpdate = Notification.Name("accountabilityAnchorsDidUpdate")
}

@MainActor
class EditAccountabilityAnchorsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var anchors: [String] = ["", "", "", "", ""]
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var saveSuccessful = false

    // MARK: - Constants

    let maxAnchors = 5

    // MARK: - Private Properties

    private let authService = AuthenticationService.shared
    private let supabase = SupabaseClientManager.shared
    private var originalAnchors: [String] = []

    // MARK: - Computed Properties

    /// Get non-empty anchors
    var validAnchors: [String] {
        anchors.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
               .filter { !$0.isEmpty }
    }

    /// Check if there are any changes from original
    var hasChanges: Bool {
        let currentValid = validAnchors
        let originalValid = originalAnchors.filter { !$0.isEmpty }
        return currentValid != originalValid
    }

    /// Can save if there's at least one anchor and changes were made
    var canSave: Bool {
        !validAnchors.isEmpty && hasChanges && !isSaving
    }

    /// Count of filled anchors
    var filledCount: Int {
        validAnchors.count
    }

    // MARK: - Public Methods

    func loadCurrentAnchors() {
        isLoading = true
        print("[debugEditAnchors] 📖 Loading current anchors...")

        // Load from UserDefaults cache
        let savedAnchors = UserDefaults.standard.array(forKey: "accountability_anchors") as? [String] ?? []

        print("[debugEditAnchors] 📖 Loaded anchors: \(savedAnchors)")

        // Fill the anchors array (pad with empty strings to reach maxAnchors)
        var loadedAnchors = savedAnchors
        while loadedAnchors.count < maxAnchors {
            loadedAnchors.append("")
        }

        anchors = Array(loadedAnchors.prefix(maxAnchors))
        originalAnchors = savedAnchors

        print("[debugEditAnchors] 📖 Set UI anchors: \(anchors)")
        isLoading = false
    }

    func saveAnchors() async {
        print("[debugEditAnchors] 💾 Save requested...")

        guard let userIdString = authService.currentSession?.userId,
              let userId = UUID(uuidString: userIdString) else {
            print("[debugEditAnchors] ❌ Save failed - missing userId")
            errorMessage = "Unable to save. Please try again."
            showError = true
            return
        }

        let anchorsToSave = validAnchors
        print("[debugEditAnchors] 💾 Saving anchors: \(anchorsToSave)")

        isSaving = true

        do {
            // Update in Supabase
            try await updateAnchorsInDatabase(userId: userId, anchors: anchorsToSave)
            print("[debugEditAnchors] ✅ Supabase update successful")

            // Update local cache
            UserDefaults.standard.set(anchorsToSave, forKey: "accountability_anchors")
            print("[debugEditAnchors] ✅ UserDefaults updated")

            // Update original values
            originalAnchors = anchorsToSave

            // Update AnalyticsViewModel directly
            AnalyticsViewModel.shared.accountabilityAnchors = anchorsToSave

            // Post notification so other views can refresh
            NotificationCenter.default.post(name: .accountabilityAnchorsDidUpdate, object: nil)
            print("[debugEditAnchors] 📢 Posted accountabilityAnchorsDidUpdate notification")

            saveSuccessful = true
            isSaving = false

        } catch {
            print("[debugEditAnchors] ❌ Save failed with error: \(error.localizedDescription)")
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
            showError = true
            isSaving = false
        }
    }

    // MARK: - Private Methods

    private func updateAnchorsInDatabase(userId: UUID, anchors: [String]) async throws {
        struct AnchorsUpdate: Encodable {
            let accountability_anchors: [String]
            let updated_at: String
        }

        let updates = AnchorsUpdate(
            accountability_anchors: anchors,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        try await supabase.database
            .from("user_profiles")
            .update(updates)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
}
