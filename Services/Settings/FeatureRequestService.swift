//
//  FeatureRequestService.swift
//  Checkpoint
//
//  Service for managing feature requests with Supabase
//

import Foundation
import Supabase

@MainActor
class FeatureRequestService: ObservableObject {
    static let shared = FeatureRequestService()

    @Published var userRequests: [FeatureRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = SupabaseClientManager.shared.client

    // Rate limiting: Max 5 requests per 10 minutes
    private let maxRequestsPer10Minutes = 5
    private let rateLimitWindow: TimeInterval = 10 * 60 // 10 minutes
    private let rateLimitKey = "featureRequests_timestamps"

    private init() {}

    // Submit a new feature request
    func submitFeatureRequest(description: String) async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        // Check rate limit
        try checkRateLimit()

        // Get current user ID
        let user = try await client.auth.user()
        let userId = user.id

        // Clean up the description
        let cleanedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate description
        guard !cleanedDescription.isEmpty else {
            throw NSError(domain: "FeatureRequestService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please describe your feature request"])
        }

        // Create the request object
        let request = FeatureRequest(
            id: nil,
            userId: userId,
            featureDescription: cleanedDescription,
            createdAt: nil,
            updatedAt: nil
        )

        // Insert into Supabase
        try await client
            .from("feature_requests")
            .insert(request)
            .execute()

        // Record submission timestamp for rate limiting
        recordSubmission()

        // Refresh the user's requests
        await fetchUserRequests()
    }

    // Fetch all feature requests for the current user
    func fetchUserRequests() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            // Get current user ID
            let user = try await client.auth.user()
            let userId = user.id

            // Fetch requests from Supabase
            let response = try await client
                .from("feature_requests")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()

            // Decode the response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            userRequests = try decoder.decode([FeatureRequest].self, from: response.data)

        } catch {
            errorMessage = "Failed to load your requests"
        }
    }

    // MARK: - Rate Limiting

    private func checkRateLimit() throws {
        let now = Date()
        var timestamps = getSubmissionTimestamps()

        // Filter to only timestamps within the rate limit window
        timestamps = timestamps.filter { now.timeIntervalSince($0) < rateLimitWindow }

        // Check if limit exceeded
        if timestamps.count >= maxRequestsPer10Minutes {
            throw NSError(
                domain: "FeatureRequestService",
                code: 429,
                userInfo: [NSLocalizedDescriptionKey: "You've submitted too many requests. Please wait a few minutes and try again."]
            )
        }
    }

    private func recordSubmission() {
        var timestamps = getSubmissionTimestamps()
        timestamps.append(Date())

        // Clean up old timestamps before saving
        let now = Date()
        timestamps = timestamps.filter { now.timeIntervalSince($0) < rateLimitWindow }

        UserDefaults.standard.set(timestamps.map { $0.timeIntervalSince1970 }, forKey: rateLimitKey)
    }

    private func getSubmissionTimestamps() -> [Date] {
        guard let intervals = UserDefaults.standard.array(forKey: rateLimitKey) as? [TimeInterval] else {
            return []
        }
        return intervals.map { Date(timeIntervalSince1970: $0) }
    }
}