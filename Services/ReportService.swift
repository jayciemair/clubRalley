//
//  ReportService.swift
//  Club Ralley
//
//  Service for reporting posts, users, and other content
//

import Foundation

/// Types of content that can be reported
enum ReportedType: String, Codable {
    case post = "post"
    case user = "user"
    case ralley = "ralley"
    case comment = "comment"
}

/// Reasons for reporting content
enum ReportReason: String, CaseIterable {
    case spam = "Spam or misleading"
    case harassment = "Harassment or bullying"
    case hateSpeech = "Hate speech or discrimination"
    case violence = "Violence or dangerous behavior"
    case inappropriate = "Inappropriate content"
    case impersonation = "Impersonation"
    case other = "Other"

    var description: String { rawValue }
}

/// Database model for reports
struct DatabaseReport: Codable {
    var id: UUID?
    let reporter_id: UUID
    let reported_type: String
    let reported_id: UUID
    let reason: String
    let additional_context: String?
    var status: String?
    var created_at: Date?

    init(
        reporter_id: UUID,
        reported_type: ReportedType,
        reported_id: UUID,
        reason: String,
        additional_context: String? = nil
    ) {
        self.id = nil
        self.reporter_id = reporter_id
        self.reported_type = reported_type.rawValue
        self.reported_id = reported_id
        self.reason = reason
        self.additional_context = additional_context
        self.status = nil
        self.created_at = nil
    }
}

/// Service for managing reports
@MainActor
class ReportService: ObservableObject {

    // MARK: - Dependencies

    private let supabase = SupabaseManager.shared

    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Report Submission

    /// Report a post
    /// - Parameters:
    ///   - postId: The ID of the post to report
    ///   - reason: The reason for reporting
    ///   - additionalContext: Optional additional context
    func reportPost(_ postId: UUID, reason: ReportReason, additionalContext: String? = nil) async throws {
        try await submitReport(
            type: .post,
            id: postId,
            reason: reason,
            additionalContext: additionalContext
        )
    }

    /// Report a user
    /// - Parameters:
    ///   - userId: The ID of the user to report
    ///   - reason: The reason for reporting
    ///   - additionalContext: Optional additional context
    func reportUser(_ userId: UUID, reason: ReportReason, additionalContext: String? = nil) async throws {
        try await submitReport(
            type: .user,
            id: userId,
            reason: reason,
            additionalContext: additionalContext
        )
    }

    /// Report a ralley
    /// - Parameters:
    ///   - ralleyId: The ID of the ralley to report
    ///   - reason: The reason for reporting
    ///   - additionalContext: Optional additional context
    func reportRalley(_ ralleyId: UUID, reason: ReportReason, additionalContext: String? = nil) async throws {
        try await submitReport(
            type: .ralley,
            id: ralleyId,
            reason: reason,
            additionalContext: additionalContext
        )
    }

    /// Report a comment
    /// - Parameters:
    ///   - commentId: The ID of the comment to report
    ///   - reason: The reason for reporting
    ///   - additionalContext: Optional additional context
    func reportComment(_ commentId: UUID, reason: ReportReason, additionalContext: String? = nil) async throws {
        try await submitReport(
            type: .comment,
            id: commentId,
            reason: reason,
            additionalContext: additionalContext
        )
    }

    // MARK: - Private Methods

    private func submitReport(
        type: ReportedType,
        id: UUID,
        reason: ReportReason,
        additionalContext: String?
    ) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        error = nil

        do {
            let report = DatabaseReport(
                reporter_id: currentUser.id,
                reported_type: type,
                reported_id: id,
                reason: reason.rawValue,
                additional_context: additionalContext
            )

            try await supabase.insert(report, into: "reports")
            print("✅ ReportService: Report submitted - Type: \(type.rawValue), ID: \(id), Reason: \(reason.rawValue)")
            isLoading = false
        } catch {
            isLoading = false
            self.error = error
            print("❌ ReportService: Failed to submit report: \(error)")
            throw error
        }
    }

    // MARK: - Check Existing Reports

    /// Check if the current user has already reported this content
    func hasReported(type: ReportedType, id: UUID) async -> Bool {
        guard let currentUser = supabase.currentUser else { return false }

        do {
            let reports: [DatabaseReport] = try await supabase.query("reports")
                .select("id")
                .eq("reporter_id", value: currentUser.id)
                .eq("reported_type", value: type.rawValue)
                .eq("reported_id", value: id)
                .execute()

            return !reports.isEmpty
        } catch {
            print("❌ ReportService: Failed to check existing report: \(error)")
            return false
        }
    }
}
