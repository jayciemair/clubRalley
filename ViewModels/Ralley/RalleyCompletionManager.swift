//
//  RalleyCompletionManager.swift
//  Club Ralley
//
//  ViewModel for managing ralley completion and auto-post generation.
//  Monitors ralleys and auto-triggers completion flow when they end.
//

import Foundation
import SwiftUI
import Combine

/**
 * RalleyCompletionManager: ViewModel for ralley completion operations
 *
 * Purpose: Manages the completion flow for ralleys, including
 * monitoring completed ralleys and generating auto-posts.
 *
 * Features:
 *   - Auto-monitors ralleys and triggers completion when end time passes
 *   - Only triggers for ralleys where current user is captain
 *   - Generates auto-post with all attendees tagged
 *   - Allows captain to customize visibility and tags before posting
 */
@MainActor
class RalleyCompletionManager: ObservableObject {

    // MARK: - Published Properties

    /// Currently completing ralley (for sheet presentation)
    @Published var completingRalley: ClubRalley?

    /// Attendees for the completing ralley
    @Published var attendees: [RalleyAttendee] = []

    /// Whether the completion sheet should be shown
    @Published var showingCompletionSheet = false

    /// Whether the recap sheet should be shown (after completion)
    @Published var showingRecapSheet = false

    /// Generated post for preview
    @Published var generatedPost: ClubRalleyPost?

    /// Selected visibility for the completion post
    @Published var selectedVisibility: PostVisibility = .everyone

    /// Tagged user IDs (users can be untagged)
    @Published var taggedUserIds: Set<UUID> = []

    /// Whether captain wants to opt out of auto-post
    @Published var optOutOfPost = false

    /// Loading state
    @Published var isLoading = false

    /// Error state
    @Published var error: Error?

    /// Ralleys that have ended and are pending completion (captain only)
    @Published var pendingCompletionRalleys: [ClubRalley] = []

    // MARK: - Dependencies

    /// Service layer for completion operations
    private let completionService: RalleyCompletionService

    /// Reference to parent RalleyManager
    private weak var ralleyManager: RalleyManager?

    /// Supabase manager for current user
    private let supabase = SupabaseManager.shared

    // MARK: - Monitoring State

    /// Timer for monitoring ended ralleys
    private var monitoringTimer: Timer?

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    /// IDs of ralleys that have already been processed (to avoid showing sheet multiple times)
    private var processedRalleyIds: Set<UUID> = []

    /// Whether monitoring is active
    private var isMonitoring = false

    // MARK: - Initialization

    init(ralleyManager: RalleyManager, completionService: RalleyCompletionService? = nil) {
        self.ralleyManager = ralleyManager
        self.completionService = completionService ?? ServiceContainer.shared.ralleyCompletionService
        loadProcessedRalleyIds()
    }

    // MARK: - Auto-Monitoring

    /**
     * Start monitoring for ended ralleys
     * Called when the app becomes active or user opens ralley-related views
     */
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        print("RalleyCompletionManager: Starting ended ralley monitoring")

        // Check immediately
        Task {
            await checkForEndedRalleys()
        }

        // Set up timer to check every 60 seconds
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkForEndedRalleys()
            }
        }
    }

    /**
     * Stop monitoring for ended ralleys
     * Called when leaving ralley views or app goes to background
     */
    func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        print("RalleyCompletionManager: Stopped ended ralley monitoring")
    }

    /**
     * Check for ralleys that have ended and need completion
     * Only processes ralleys where the current user is the captain
     */
    private func checkForEndedRalleys() async {
        guard let ralleyManager = ralleyManager,
              let currentUser = supabase.currentUser else { return }

        let now = Date()

        // Find ralleys where:
        // 1. Current user is the captain (organizer)
        // 2. End time has passed
        // 3. Not already processed
        // 4. Not already completed (would have a completion post)
        let endedRalleys = ralleyManager.ralleys.filter { ralley in
            let isCaption = ralley.organizer.id == currentUser.id
            let hasEnded = ralley.endTime <= now
            let notProcessed = !processedRalleyIds.contains(ralley.id)
            return isCaption && hasEnded && notProcessed
        }

        if !endedRalleys.isEmpty {
            print("RalleyCompletionManager: Found \(endedRalleys.count) ended ralleys for captain")
            pendingCompletionRalleys = endedRalleys

            // Auto-trigger completion sheet for the first ended ralley
            if let firstEnded = endedRalleys.first, !showingCompletionSheet {
                await startCompletion(for: firstEnded)
            }
        }
    }

    /**
     * Mark a ralley as processed (won't trigger completion sheet again)
     */
    func markAsProcessed(_ ralleyId: UUID) {
        processedRalleyIds.insert(ralleyId)
        pendingCompletionRalleys.removeAll { $0.id == ralleyId }
        saveProcessedRalleyIds()
    }

    /**
     * Load processed ralley IDs from persistent storage
     */
    private func loadProcessedRalleyIds() {
        if let data = UserDefaults.standard.data(forKey: "processedRalleyIds"),
           let ids = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            processedRalleyIds = ids
        }
    }

    /**
     * Save processed ralley IDs to persistent storage
     */
    private func saveProcessedRalleyIds() {
        if let data = try? JSONEncoder().encode(processedRalleyIds) {
            UserDefaults.standard.set(data, forKey: "processedRalleyIds")
        }
    }

    /**
     * Clear old processed IDs (older than 30 days)
     * Called periodically to prevent unbounded growth
     */
    func cleanupOldProcessedIds() {
        // In a full implementation, we'd track timestamps
        // For now, just cap the size
        if processedRalleyIds.count > 100 {
            // Keep only the most recent 50
            processedRalleyIds = Set(Array(processedRalleyIds).suffix(50))
            saveProcessedRalleyIds()
        }
    }

    // MARK: - Completion Flow

    /**
     * Start the completion flow for a ralley
     * Called when a captain wants to mark a ralley as completed
     * Also called automatically when monitoring detects an ended ralley
     */
    func startCompletion(for ralley: ClubRalley) async {
        // Don't show if already showing a completion sheet
        guard !showingCompletionSheet else {
            print("RalleyCompletionManager: Completion sheet already showing, queuing ralley")
            return
        }

        isLoading = true
        completingRalley = ralley

        do {
            // Load attendees
            attendees = try await completionService.getAttendees(ralley.id)

            // Check for opt-outs and filter them from default tags
            var defaultTaggedIds = Set(attendees.map { $0.id })
            for attendee in attendees {
                let hasOptedOut = try await completionService.hasOptedOut(
                    ralleyId: ralley.id,
                    userId: attendee.id
                )
                if hasOptedOut {
                    defaultTaggedIds.remove(attendee.id)
                }
            }
            taggedUserIds = defaultTaggedIds

            // Generate preview post
            generatedPost = try await completionService.generateCompletionPost(
                ralley: ralley,
                attendees: attendees,
                visibility: selectedVisibility
            )

            isLoading = false
            showingCompletionSheet = true

        } catch {
            isLoading = false
            self.error = error
            // Mark as processed even on error to avoid repeated attempts
            markAsProcessed(ralley.id)
            print("RalleyCompletionManager: Failed to start completion flow: \(error)")
        }
    }

    /**
     * Toggle whether a user is tagged in the completion post
     */
    func toggleTagged(userId: UUID) {
        if taggedUserIds.contains(userId) {
            taggedUserIds.remove(userId)
        } else {
            taggedUserIds.insert(userId)
        }

        // Update generated post
        generatedPost?.taggedUserIds = Array(taggedUserIds)
    }

    /**
     * Update visibility selection
     */
    func updateVisibility(_ visibility: PostVisibility) {
        selectedVisibility = visibility
        generatedPost?.visibility = visibility
    }

    /**
     * Complete the ralley and optionally share the post
     */
    func completeAndShare() async {
        guard let ralley = completingRalley else { return }

        isLoading = true

        do {
            // Mark ralley as completed
            try await completionService.completeRalley(ralley.id)

            // Save the completion post if not opted out
            if !optOutOfPost, var post = generatedPost {
                post.visibility = selectedVisibility
                post.taggedUserIds = Array(taggedUserIds)

                _ = try await completionService.saveCompletionPost(post)
                print("RalleyCompletionManager: Completion post shared")
            }

            // Update local ralley state
            if let ralleyManager = ralleyManager,
               let index = ralleyManager.indexOfRalley(ralley.id) {
                // Could mark as completed in local state
            }

            isLoading = false

            // Show the recap sheet so the captain can add a photo/message
            showingRecapSheet = true

        } catch {
            isLoading = false
            self.error = error
            print("RalleyCompletionManager: Failed to complete ralley: \(error)")
        }
    }

    /**
     * Dismiss the recap sheet and clean up
     */
    func dismissRecapSheet() {
        showingRecapSheet = false
        dismissSheet()
    }

    /**
     * Skip sharing the post but still complete the ralley
     */
    func skipAndComplete() async {
        guard let ralley = completingRalley else { return }

        isLoading = true

        do {
            // Mark ralley as completed without creating a post
            try await completionService.completeRalley(ralley.id)

            isLoading = false
            dismissSheet()

        } catch {
            isLoading = false
            self.error = error
            print("RalleyCompletionManager: Failed to skip and complete: \(error)")
        }
    }

    /**
     * Dismiss the completion sheet and reset state
     * Automatically checks for more pending ralleys
     */
    func dismissSheet() {
        // Mark current ralley as processed
        if let ralleyId = completingRalley?.id {
            markAsProcessed(ralleyId)
        }

        showingCompletionSheet = false
        showingRecapSheet = false
        completingRalley = nil
        attendees = []
        generatedPost = nil
        taggedUserIds = []
        optOutOfPost = false
        selectedVisibility = .everyone

        // Check if there are more pending ralleys to process
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            if let nextRalley = pendingCompletionRalleys.first {
                await startCompletion(for: nextRalley)
            }
        }
    }

    // MARK: - Opt-Out Operations

    /**
     * Opt current user out of being tagged in a ralley's completion post
     */
    func optOutOfRalleyPost(ralleyId: UUID) async {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id else { return }

        do {
            try await completionService.optOutOfPost(ralleyId: ralleyId, userId: currentUserId)
            print("RalleyCompletionManager: Opted out of ralley post")
        } catch {
            self.error = error
            print("RalleyCompletionManager: Failed to opt out: \(error)")
        }
    }

    /**
     * Check if current user has opted out of a ralley's completion post
     */
    func hasOptedOut(ralleyId: UUID) async -> Bool {
        guard let currentUserId = SupabaseManager.shared.currentUser?.id else { return false }

        do {
            return try await completionService.hasOptedOut(ralleyId: ralleyId, userId: currentUserId)
        } catch {
            return false
        }
    }

    // MARK: - Clear State

    func clearError() {
        error = nil
    }
}
