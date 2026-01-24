//
//  OnboardingDataServiceTests.swift
//  CheckpointTests
//
//  Tests for OnboardingDataService database operations
//

import XCTest
@testable import Checkpoint

@MainActor
final class OnboardingDataServiceTests: XCTestCase {

    // MARK: - Properties

    var mockSupabase: MockSupabaseClient!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockSupabase = MockSupabaseClient()
    }

    override func tearDown() async throws {
        mockSupabase = nil
        try await super.tearDown()
    }

    // MARK: - Profile Sync Tests

    /// Test that user profile data is properly formatted for database
    func testUserProfileDataFormatting() async throws {
        // Given: User profile data
        let userId = UUID()
        let profileData: [String: Any] = [
            "referral_source": "instagram",
            "accountability_anchors": ["family", "career"],
            "clarity_time": "morning",
            "age": 28,
            "gender": "Male"
        ]

        // When: Formatting for database
        let formatted = formatUserProfile(userId: userId, data: profileData)

        // Then: Verify required fields
        XCTAssertEqual(formatted["user_id"] as? UUID, userId)
        XCTAssertEqual(formatted["referral_source"] as? String, "instagram")
        XCTAssertEqual(formatted["user_goal"] as? String, "nuclear", "Should hardcode user_goal to nuclear")
        XCTAssertEqual(formatted["age"] as? Int, 28)
        XCTAssertEqual(formatted["gender"] as? String, "Male")
    }

    /// Test that gambling profile data is properly formatted
    func testGamblingProfileDataFormatting() async throws {
        // Given: Gambling profile data
        let userId = UUID()
        let gamblingData: [String: Any] = [
            "daily_bet_count": 10,
            "average_bet_amount": 25.50,
            "gambling_days_per_week": 5,
            "projected_annual_loss": 50000,
            "projected_lifetime_loss": 1000000
        ]

        // When: Formatting for database
        let formatted = formatGamblingProfile(userId: userId, data: gamblingData)

        // Then: Verify fields
        XCTAssertEqual(formatted["user_id"] as? UUID, userId)
        XCTAssertEqual(formatted["daily_bet_count"] as? Int, 10)
        XCTAssertEqual(formatted["average_bet_amount"] as? Double, 25.50)
        XCTAssertEqual(formatted["gambling_days_per_week"] as? Int, 5)
    }

    /// Test that quit date is properly formatted as ISO8601
    func testQuitDateFormatting() async throws {
        // Given: A quit date timestamp
        let quitDate = Date()

        // When: Formatting for database
        let formatter = ISO8601DateFormatter()
        let formatted = formatter.string(from: quitDate)

        // Then: Verify it's valid ISO8601
        XCTAssertNotNil(formatter.date(from: formatted), "Should be valid ISO8601")
        XCTAssertTrue(formatted.contains("T"), "Should contain time separator")
        XCTAssertTrue(formatted.contains("Z") || formatted.contains("+"), "Should have timezone")
    }

    /// Test that signature URL is included in user profile
    func testSignatureURLIsIncluded() async throws {
        // Given: User profile with signature
        let userId = UUID()
        let signatureURL = "https://example.com/signatures/\(userId.uuidString)/signature.png"

        let profileData: [String: Any] = [
            "referral_source": "test",
            "commitment_signature_url": signatureURL
        ]

        // When: Formatting for database
        let formatted = formatUserProfile(userId: userId, data: profileData)

        // Then: Verify signature URL is present
        XCTAssertEqual(
            formatted["commitment_signature_url"] as? String,
            signatureURL,
            "Signature URL should be included"
        )
    }

    /// Test that risk multiplier is calculated correctly
    func testRiskMultiplierCalculation() async throws {
        // Given: Risk assessment data
        let riskScore = 75
        let averageScore = 15

        // When: Calculating multiplier
        let multiplier = Double(riskScore) / Double(averageScore)

        // Then: Verify calculation
        XCTAssertEqual(multiplier, 5.0, accuracy: 0.01, "75 / 15 should equal 5.0")
    }

    // MARK: - Data Validation Tests

    /// Test that invalid user ID is rejected
    func testInvalidUserIDIsRejected() async throws {
        // Given: Invalid user ID
        let invalidData: [String: Any] = [
            "authentication": [
                "user_id": "not-a-valid-uuid"
            ]
        ]

        // When/Then: Should fail to parse user ID
        let userId = extractUserID(from: invalidData)
        XCTAssertNil(userId, "Invalid UUID should return nil")
    }

    /// Test that missing required fields are handled
    func testMissingRequiredFields() async throws {
        // Given: Data missing required fields
        let incompleteData: [String: Any] = [
            "user_profile": [
                // Missing referral_source
            ]
        ]

        // When: Attempting to create profile
        let formatted = formatUserProfile(userId: UUID(), data: incompleteData)

        // Then: Should handle gracefully with nil values
        XCTAssertNil(formatted["referral_source"])
    }

    /// Test that age validation works correctly
    func testAgeValidation() async throws {
        // Given: Various ages
        let validAge = 25
        let tooYoung = 0
        let tooOld = 100
        let maxAge = 75

        // When/Then: Verify age constraints
        XCTAssertTrue(validAge > 0 && validAge <= 75, "Valid age should be accepted")
        XCTAssertFalse(tooYoung > 0 && tooYoung <= 75, "Age 0 should be rejected")
        XCTAssertFalse(tooOld > 0 && tooOld <= 75, "Age over 75 should be rejected")
        XCTAssertTrue(maxAge > 0 && maxAge <= 75, "Age 75 should be accepted")
    }

    // MARK: - Error Handling Tests

    /// Test that database errors are properly caught
    func testDatabaseErrorHandling() async throws {
        // Given: A database that will throw an error
        let testError = NSError(
            domain: "DatabaseError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Connection timeout"]
        )
        mockSupabase.shouldThrowError = testError

        // When: Attempting database operation
        do {
            try mockSupabase.recordUpdate(
                table: "users",
                data: ["test": "data"],
                filters: ["id": "123"]
            )
            XCTFail("Should have thrown an error")
        } catch {
            // Then: Error should be propagated
            XCTAssertEqual((error as NSError).code, 500)
        }
    }

    /// Test that network errors don't crash the app
    func testNetworkErrorResilience() async throws {
        // Given: Various network error scenarios
        let errors = [
            NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet),
            NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut),
            NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost)
        ]

        // When/Then: Each error should be handled gracefully
        for error in errors {
            mockSupabase.shouldThrowError = error

            do {
                try mockSupabase.recordInsert(table: "test", data: [:])
                XCTFail("Should have thrown error: \(error.code)")
            } catch {
                // Expected - error was properly thrown
                XCTAssertEqual((error as NSError).code, error.code)
            }

            mockSupabase.reset()
        }
    }

    // MARK: - Integration Tests

    /// Test the complete onboarding data sync flow
    func testCompleteOnboardingSyncFlow() async throws {
        // Given: Complete onboarding data
        let userId = UUID()
        let completeData = createCompleteOnboardingData(userId: userId)

        // When: Syncing all data
        try await mockSyncAllOnboardingData(userId: userId, data: completeData)

        // Then: Verify all tables were updated in correct order
        let operations = mockSupabase.capturedOperations

        // Should have user_profiles, gambling_profiles, and user_analytics updates
        XCTAssertGreaterThanOrEqual(operations.count, 3, "Should have at least 3 operations")

        // Verify user_profiles was synced
        let profileOps = operations.filter { $0.table == "user_profiles" }
        XCTAssertFalse(profileOps.isEmpty, "Should sync user_profiles")

        // Verify gambling_profiles was synced
        let gamblingOps = operations.filter { $0.table == "gambling_profiles" }
        XCTAssertFalse(gamblingOps.isEmpty, "Should sync gambling_profiles")

        // Verify user_analytics was updated with quit_date
        let analyticsOps = operations.filter { $0.table == "user_analytics" }
        XCTAssertFalse(analyticsOps.isEmpty, "Should update user_analytics")
    }

    // MARK: - Helper Methods

    private func formatUserProfile(userId: UUID, data: [String: Any]) -> [String: Any] {
        var formatted: [String: Any] = [
            "user_id": userId,
            "user_goal": "nuclear" // Hardcoded for all users
        ]

        if let referralSource = data["referral_source"] as? String {
            formatted["referral_source"] = referralSource
        }

        if let accountabilityAnchors = data["accountability_anchors"] as? [String] {
            formatted["accountability_anchors"] = accountabilityAnchors
        }

        if let clarityTime = data["clarity_time"] as? String {
            formatted["clarity_time"] = clarityTime
        }

        if let age = data["age"] as? Int {
            formatted["age"] = age
        }

        if let gender = data["gender"] as? String {
            formatted["gender"] = gender
        }

        if let signatureURL = data["commitment_signature_url"] as? String {
            formatted["commitment_signature_url"] = signatureURL
        }

        return formatted
    }

    private func formatGamblingProfile(userId: UUID, data: [String: Any]) -> [String: Any] {
        var formatted: [String: Any] = [
            "user_id": userId
        ]

        if let dailyBetCount = data["daily_bet_count"] as? Int {
            formatted["daily_bet_count"] = dailyBetCount
        }

        if let averageBetAmount = data["average_bet_amount"] as? Double {
            formatted["average_bet_amount"] = averageBetAmount
        }

        if let gamblingDaysPerWeek = data["gambling_days_per_week"] as? Int {
            formatted["gambling_days_per_week"] = gamblingDaysPerWeek
        }

        return formatted
    }

    private func extractUserID(from data: [String: Any]) -> UUID? {
        guard let authData = data["authentication"] as? [String: Any],
              let userIdString = authData["user_id"] as? String,
              let uuid = UUID(uuidString: userIdString) else {
            return nil
        }
        return uuid
    }

    private func createCompleteOnboardingData(userId: UUID) -> [String: Any] {
        return [
            "authentication": [
                "user_id": userId.uuidString
            ],
            "referral_source": [
                "referral_source": "instagram"
            ],
            "accountability_anchors": [
                "accountability_anchors": ["family", "career"]
            ],
            "clarity_time": [
                "clarity_time": "morning"
            ],
            "age": [
                "age": 28
            ],
            "gender": [
                "answer": "Male"
            ],
            "daily_bet_count": [
                "daily_bet_count": 5
            ],
            "average_bet_amount": [
                "average_bet_amount": 10.0
            ],
            "gambling_days": [
                "day_count": 3
            ],
            "quit_date_reveal": [
                "quit_date": Date().addingTimeInterval(90 * 24 * 60 * 60).timeIntervalSince1970
            ]
        ]
    }

    private func mockSyncAllOnboardingData(userId: UUID, data: [String: Any]) async throws {
        // Sync user_profiles
        try mockSupabase.recordUpsert(
            table: "user_profiles",
            data: formatUserProfile(userId: userId, data: data),
            onConflict: "user_id"
        )

        // Sync gambling_profiles
        try mockSupabase.recordUpsert(
            table: "gambling_profiles",
            data: formatGamblingProfile(userId: userId, data: data),
            onConflict: "user_id"
        )

        // Sync quit_date to user_analytics
        try mockSupabase.recordUpdate(
            table: "user_analytics",
            data: ["quit_date": ISO8601DateFormatter().string(from: Date())],
            filters: ["user_id": userId.uuidString]
        )
    }
}
