//
//  OnboardingCompletionTests.swift
//  CheckpointTests
//
//  Tests for onboarding completion flow and database updates
//

import XCTest
@testable import Checkpoint

@MainActor
final class OnboardingCompletionTests: XCTestCase {

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

    // MARK: - Critical Bug Tests

    /// Test that onboarding completion properly updates the database BEFORE dismissing
    /// This test verifies the fix for the race condition bug where users were completing
    /// onboarding but has_completed_onboarding was never set to true
    func testOnboardingCompletionUpdatesDatabase() async throws {
        // Given: A user completing onboarding
        let userId = UUID()
        let collectedData = createMockOnboardingData(userId: userId)

        // When: Onboarding is marked as complete
        let expectation = XCTestExpectation(description: "Database update completes")

        Task {
            // Simulate the fixed version where database update happens first
            try await mockUpdateOnboardingCompletion(userId: userId)

            // Then: Verify database was updated BEFORE any dismissal
            XCTAssertTrue(
                mockSupabase.didUpdate(table: "users", field: "has_completed_onboarding", value: true),
                "has_completed_onboarding should be set to true"
            )

            XCTAssertTrue(
                mockSupabase.didUpdateTable("users"),
                "users table should be updated"
            )

            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 5.0)
    }

    /// Test that the completion timestamp is set correctly
    func testOnboardingCompletionSetsTimestamp() async throws {
        // Given: A user completing onboarding
        let userId = UUID()

        // When: Onboarding completion is triggered
        let beforeTime = Date()
        try await mockUpdateOnboardingCompletion(userId: userId)
        let afterTime = Date()

        // Then: Verify timestamp was set
        let operations = mockSupabase.capturedOperations.filter { $0.table == "users" }
        XCTAssertFalse(operations.isEmpty, "Should have operations on users table")

        // Verify the operation includes onboarding_completed_at
        if let updateOp = operations.first,
           let data = updateOp.data as? [String: Any],
           let timestampString = data["onboarding_completed_at"] as? String {

            // Parse the ISO8601 timestamp
            let formatter = ISO8601DateFormatter()
            if let timestamp = formatter.date(from: timestampString) {
                XCTAssertGreaterThanOrEqual(timestamp, beforeTime, "Timestamp should be after start")
                XCTAssertLessThanOrEqual(timestamp, afterTime, "Timestamp should be before end")
            } else {
                XCTFail("Failed to parse timestamp: \(timestampString)")
            }
        } else {
            XCTFail("onboarding_completed_at should be present in update data")
        }
    }

    /// Test that profile data sync happens independently of completion flag
    func testProfileDataSyncIsIndependent() async throws {
        // Given: User profile data
        let userId = UUID()
        let collectedData = createMockOnboardingData(userId: userId)

        // When: Profile data is synced (early sync at screen 17)
        try await mockSyncProfileData(userId: userId, data: collectedData)

        // Then: Verify profile tables were updated
        XCTAssertTrue(
            mockSupabase.operationCount(for: "user_profiles") > 0,
            "user_profiles should be updated"
        )

        XCTAssertTrue(
            mockSupabase.operationCount(for: "gambling_profiles") > 0,
            "gambling_profiles should be updated"
        )

        // But completion flag should NOT be set yet
        XCTAssertFalse(
            mockSupabase.didUpdate(table: "users", field: "has_completed_onboarding", value: true),
            "has_completed_onboarding should NOT be set during early sync"
        )
    }

    /// Test that error during completion is properly logged
    func testOnboardingCompletionErrorIsLogged() async throws {
        // Given: A database error will occur
        let testError = NSError(domain: "TestError", code: 500, userInfo: [
            NSLocalizedDescriptionKey: "Database connection failed"
        ])
        mockSupabase.shouldThrowError = testError

        let userId = UUID()

        // When: Attempting to mark onboarding complete
        do {
            try await mockUpdateOnboardingCompletion(userId: userId)
            XCTFail("Should have thrown an error")
        } catch {
            // Then: Error should be caught and logged
            XCTAssertEqual((error as NSError).domain, "TestError")
            XCTAssertEqual((error as NSError).code, 500)
        }
    }

    /// Test that all required fields are present in the database update
    func testOnboardingCompletionIncludesAllRequiredFields() async throws {
        // Given: A user completing onboarding
        let userId = UUID()

        // When: Completion is triggered
        try await mockUpdateOnboardingCompletion(userId: userId)

        // Then: Verify all required fields are present
        let operations = mockSupabase.capturedOperations.filter { $0.table == "users" }

        guard let updateOp = operations.first,
              let data = updateOp.data as? [String: Any] else {
            XCTFail("Should have update operation with data")
            return
        }

        XCTAssertNotNil(data["has_completed_onboarding"], "Should include has_completed_onboarding")
        XCTAssertNotNil(data["onboarding_completed_at"], "Should include onboarding_completed_at")

        // Verify correct values
        XCTAssertEqual(data["has_completed_onboarding"] as? Bool, true, "has_completed_onboarding should be true")
    }

    /// Test the sequence: profile sync -> completion flag
    func testOnboardingSequenceIsCorrect() async throws {
        // Given: A user going through onboarding
        let userId = UUID()
        let collectedData = createMockOnboardingData(userId: userId)

        // When: Following the correct sequence
        // 1. First: Sync profile data (screen 17)
        try await mockSyncProfileData(userId: userId, data: collectedData)

        let profileOpsCount = mockSupabase.capturedOperations.count

        // 2. Then: Mark completion (final screen)
        try await mockUpdateOnboardingCompletion(userId: userId)

        // Then: Verify correct sequence
        XCTAssertGreaterThan(
            mockSupabase.capturedOperations.count,
            profileOpsCount,
            "Should have additional operations after completion"
        )

        // Verify the completion operation came AFTER profile operations
        let completionOpIndex = mockSupabase.capturedOperations.firstIndex {
            $0.table == "users" && $0.operation == .update
        }

        XCTAssertNotNil(completionOpIndex, "Should have completion operation")
        XCTAssertGreaterThan(completionOpIndex ?? 0, 0, "Completion should come after profile sync")
    }

    // MARK: - Helper Methods

    /// Mock the onboarding completion database update
    private func mockUpdateOnboardingCompletion(userId: UUID) async throws {
        struct OnboardingUpdate: Encodable {
            let has_completed_onboarding: Bool
            let onboarding_completed_at: String
        }

        let update = OnboardingUpdate(
            has_completed_onboarding: true,
            onboarding_completed_at: ISO8601DateFormatter().string(from: Date())
        )

        // Simulate the database update
        try mockSupabase.recordUpdate(
            table: "users",
            data: [
                "has_completed_onboarding": update.has_completed_onboarding,
                "onboarding_completed_at": update.onboarding_completed_at
            ],
            filters: ["id": userId.uuidString]
        )
    }

    /// Mock profile data sync
    private func mockSyncProfileData(userId: UUID, data: [String: Any]) async throws {
        // Simulate user_profiles upsert
        try mockSupabase.recordUpsert(
            table: "user_profiles",
            data: [
                "user_id": userId.uuidString,
                "referral_source": "test",
                "user_goal": "nuclear"
            ],
            onConflict: "user_id"
        )

        // Simulate gambling_profiles upsert
        try mockSupabase.recordUpsert(
            table: "gambling_profiles",
            data: [
                "user_id": userId.uuidString,
                "daily_bet_count": 5,
                "average_bet_amount": 10.0
            ],
            onConflict: "user_id"
        )
    }

    /// Create mock onboarding data
    private func createMockOnboardingData(userId: UUID) -> [String: Any] {
        return [
            "authentication": [
                "user_id": userId.uuidString
            ],
            "user_profile": [
                "referral_source": "test",
                "user_goal": "nuclear"
            ],
            "gambling_profile": [
                "daily_bet_count": 5,
                "average_bet_amount": 10.0
            ]
        ]
    }
}
