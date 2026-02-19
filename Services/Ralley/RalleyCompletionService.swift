//
//  RalleyCompletionService.swift
//  Club Ralley
//
//  Service for ralley completion: completing ralleys and generating auto-posts.
//

import Foundation
import SwiftUI

/**
 * RalleyCompletionService: Handles ralley completion and auto-post generation
 *
 * Purpose: Manages the completion flow for ralleys, including generating
 * auto-posts that tag attendees and share the ralley experience.
 */
// MARK: - Protocol

@MainActor
protocol RalleyCompletionServiceProtocol: ObservableObject {
    var isLoading: Bool { get }
    func completeRalley(_ ralleyId: UUID) async throws
    func getAttendees(_ ralleyId: UUID) async throws -> [RalleyAttendee]
    func generateCompletionPost(ralley: ClubRalley, attendees: [RalleyAttendee], visibility: PostVisibility) async throws -> ClubRalleyPost
    func saveCompletionPost(_ post: ClubRalleyPost) async throws -> ClubRalleyPost
    func optOutOfPost(ralleyId: UUID, userId: UUID) async throws
    func hasOptedOut(ralleyId: UUID, userId: UUID) async throws -> Bool
    func removeOptOut(ralleyId: UUID, userId: UUID) async throws
}

@MainActor
class RalleyCompletionService: ObservableObject, RalleyCompletionServiceProtocol {

    // MARK: - Dependencies

    /// Supabase client for database operations
    private let supabase = SupabaseManager.shared

    /// Participation service for getting attendees
    private let participationService: RalleyParticipationService

    // MARK: - Initialization

    init(participationService: RalleyParticipationService) {
        self.participationService = participationService
    }

    convenience init() {
        self.init(participationService: RalleyParticipationService())
    }

    // MARK: - Published Properties

    /// Loading state for UI spinners
    @Published var isLoading = false

    /// Last operation error for user feedback
    @Published var lastError: SupabaseManager.SupabaseError?

    // MARK: - Completion Operations

    /**
     * Mark a ralley as completed
     * @param ralleyId: Ralley ID to complete
     */
    func completeRalley(_ ralleyId: UUID) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        isLoading = true
        lastError = nil

        do {
            try await supabase.update(
                table: "ralleys",
                set: ["status": "completed", "completed_at": ISO8601DateFormatter().string(from: Date())],
                where: "id = '\(ralleyId)'"
            )

            print("RalleyCompletionService: Ralley \(ralleyId) marked as completed")
            isLoading = false

        } catch {
            isLoading = false
            print("RalleyCompletionService: Complete ralley failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    /**
     * Get all attendees for a ralley
     * @param ralleyId: Ralley ID
     * @returns: Array of attendees
     */
    func getAttendees(_ ralleyId: UUID) async throws -> [RalleyAttendee] {
        return try await participationService.getAttendees(ralleyId: ralleyId)
    }

    /**
     * Generate a completion post for a ralley
     * @param ralley: The completed ralley
     * @param attendees: List of attendees to tag
     * @param visibility: Post visibility setting
     * @returns: Generated post ready to be saved
     */
    func generateCompletionPost(
        ralley: ClubRalley,
        attendees: [RalleyAttendee],
        visibility: PostVisibility = .everyone
    ) async throws -> ClubRalleyPost {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        // Build post content
        let content = generatePostContent(ralley: ralley, attendees: attendees)

        // Get tagged user IDs (excluding users who opted out)
        var taggedUserIds: [UUID] = []
        for attendee in attendees {
            let optedOut = try await hasOptedOut(ralleyId: ralley.id, userId: attendee.id)
            if !optedOut {
                taggedUserIds.append(attendee.id)
            }
        }

        return ClubRalleyPost(
            id: UUID(),
            authorName: currentUser.displayName,
            authorUsername: "@\(currentUser.email.components(separatedBy: "@").first ?? "user")",
            authorPhotoURL: "",
            authorId: currentUser.id,
            title: "Completed: \(ralley.title)",
            content: content,
            images: [],
            timestamp: Date(),
            postType: .ralleyCompletion,
            visibility: visibility,
            relatedRalleyId: ralley.id,
            taggedUserIds: taggedUserIds,
            likes: 0,
            comments: 0,
            shares: 0,
            isLiked: false
        )
    }

    /**
     * Save a completion post to the database
     * @param post: The completion post to save
     * @returns: Saved post
     */
    func saveCompletionPost(_ post: ClubRalleyPost) async throws -> ClubRalleyPost {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        lastError = nil

        do {
            let dbPost = DatabasePost(
                user_id: currentUser.id,
                content: formatPostContent(post),
                post_type: PostType.ralleyCompletion.rawValue,
                likes_count: 0,
                comments_count: 0,
                visibility: post.visibility.rawValue,
                ralley_id: post.relatedRalleyId,
                tagged_user_ids: post.taggedUserIds.isEmpty ? nil : post.taggedUserIds,
                link_url: nil,
                shares_count: 0
            )

            try await supabase.insert(dbPost, into: "posts")

            print("RalleyCompletionService: Completion post saved")
            isLoading = false
            return post

        } catch {
            isLoading = false
            print("RalleyCompletionService: Save completion post failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Opt-Out Operations

    /**
     * Opt out of being tagged in a ralley completion post
     * @param ralleyId: Ralley ID
     * @param userId: User ID opting out
     */
    func optOutOfPost(ralleyId: UUID, userId: UUID) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        do {
            let optOut = DatabaseRalleyPostOptOut(
                ralley_id: ralleyId,
                user_id: userId
            )

            try await supabase.insert(optOut, into: "ralley_post_opt_outs")
            print("RalleyCompletionService: User \(userId) opted out of post for ralley \(ralleyId)")

        } catch {
            print("RalleyCompletionService: Opt out failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    /**
     * Check if a user has opted out of being tagged
     * @param ralleyId: Ralley ID
     * @param userId: User ID to check
     * @returns: True if user has opted out
     */
    func hasOptedOut(ralleyId: UUID, userId: UUID) async throws -> Bool {
        do {
            let optOuts: [DatabaseRalleyPostOptOut] = try await supabase.query("ralley_post_opt_outs")
                .select("*")
                .eq("ralley_id", value: ralleyId)
                .eq("user_id", value: userId)
                .execute()

            return !optOuts.isEmpty
        } catch {
            return false
        }
    }

    /**
     * Remove opt-out (allow being tagged again)
     * @param ralleyId: Ralley ID
     * @param userId: User ID
     */
    func removeOptOut(ralleyId: UUID, userId: UUID) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        do {
            try await supabase.delete(
                from: "ralley_post_opt_outs",
                where: "ralley_id = '\(ralleyId)' AND user_id = '\(userId)'"
            )
            print("RalleyCompletionService: Opt-out removed for user \(userId)")

        } catch {
            print("RalleyCompletionService: Remove opt-out failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Helper Methods

    /**
     * Generate post content for completion post
     */
    private func generatePostContent(ralley: ClubRalley, attendees: [RalleyAttendee]) -> String {
        var content = "Just wrapped up an awesome \(ralley.sport.lowercased()) session at \(ralley.location.name)!"

        if attendees.count > 1 {
            let otherCount = attendees.count - 1
            if otherCount == 1 {
                content += " Great playing with 1 other athlete!"
            } else {
                content += " Great playing with \(otherCount) other athletes!"
            }
        }

        content += "\n\n#ClubRalley #\(ralley.sport.replacingOccurrences(of: " ", with: ""))"

        return content
    }

    /**
     * Format post content with title
     */
    private func formatPostContent(_ post: ClubRalleyPost) -> String {
        if let title = post.title, !title.isEmpty {
            return "\(title)\n\n\(post.content)"
        }
        return post.content
    }
}
