//
//  WebsiteBlockService.swift
//  Checkpoint
//
//  Service for managing website block requests with Supabase
//

import Foundation
import Supabase

@MainActor
class WebsiteBlockService: ObservableObject {
    static let shared = WebsiteBlockService()

    @Published var userRequests: [WebsiteBlockRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = SupabaseClientManager.shared.client

    // Rate limiting: Max 10 requests per 5 minutes
    private let maxRequestsPer5Minutes = 10
    private let rateLimitWindow: TimeInterval = 5 * 60 // 5 minutes
    private let rateLimitKey = "websiteBlockRequests_timestamps"

    private init() {}

    // Submit a new website block request
    func submitBlockRequest(domain: String) async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        // Check rate limit
        try checkRateLimit()

        // Get current user ID
        let user = try await client.auth.user()
        let userId = user.id

        // Clean up the domain (remove https://, www., trailing slashes)
        let cleanedDomain = cleanDomain(domain)

        // Validate domain format
        guard isValidDomain(cleanedDomain) else {
            throw NSError(domain: "WebsiteBlockService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid domain format"])
        }

        // Create the request object
        let request = WebsiteBlockRequest(
            id: nil,
            userId: userId,
            domain: cleanedDomain,
            status: "pending",
            reviewedBy: nil,
            reviewNotes: nil,
            createdAt: nil,
            updatedAt: nil
        )

        // Insert into Supabase
        try await client
            .from("website_block_requests")
            .insert(request)
            .execute()

        // Record submission timestamp for rate limiting
        recordSubmission()

        // Refresh the user's requests
        await fetchUserRequests()
    }

    // Fetch all block requests for the current user
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
                .from("website_block_requests")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()

            // Decode the response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            userRequests = try decoder.decode([WebsiteBlockRequest].self, from: response.data)

        } catch {
            errorMessage = "Failed to load your requests"
        }
    }

    // Helper to clean up domain input
    private func cleanDomain(_ domain: String) -> String {
        var cleaned = domain.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove protocol
        if cleaned.hasPrefix("https://") {
            cleaned = String(cleaned.dropFirst(8))
        } else if cleaned.hasPrefix("http://") {
            cleaned = String(cleaned.dropFirst(7))
        }

        // Remove www.
        if cleaned.hasPrefix("www.") {
            cleaned = String(cleaned.dropFirst(4))
        }

        // Remove trailing slash
        if cleaned.hasSuffix("/") {
            cleaned = String(cleaned.dropLast())
        }

        // Remove any path after the domain
        if let firstSlashIndex = cleaned.firstIndex(of: "/") {
            cleaned = String(cleaned[..<firstSlashIndex])
        }

        return cleaned
    }

    // Basic domain validation
    private func isValidDomain(_ domain: String) -> Bool {
        // Check if empty
        if domain.isEmpty {
            return false
        }

        // Check for spaces
        if domain.contains(" ") {
            return false
        }

        // Check for at least one dot
        if !domain.contains(".") {
            return false
        }

        // Basic regex check for domain format
        let domainRegex = "^([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$"
        let domainPredicate = NSPredicate(format: "SELF MATCHES %@", domainRegex)
        return domainPredicate.evaluate(with: domain)
    }

    // MARK: - Rate Limiting

    private func checkRateLimit() throws {
        let now = Date()
        var timestamps = getSubmissionTimestamps()

        // Filter to only timestamps within the rate limit window
        timestamps = timestamps.filter { now.timeIntervalSince($0) < rateLimitWindow }

        // Check if limit exceeded
        if timestamps.count >= maxRequestsPer5Minutes {
            throw NSError(
                domain: "WebsiteBlockService",
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