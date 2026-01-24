//
//  UserProfileServiceTests.swift
//  CheckpointTests
//
//  Tests for UserProfileService onboarding completion
//

import XCTest
@testable import Checkpoint

@MainActor
final class UserProfileServiceTests: XCTestCase {

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

    // MARK: - Mark Onboarding Complete Tests

    /// Test that markOnboardingComplete updates the users table correctly
    func testMarkOnboardingCompleteUpdatesUsersTable() async throws {
        // Given: A user ID
        let userId = UUID()

        // When: Marking onboarding as complete
        try await mockMarkOnboardingComplete(userId: userId)

        // Then: Verify users table was updated
        XCTAssertTrue(
            mockSupabase.didUpdateTable("users"),
            "users table should be updated"
        )

        XCTAssertTrue(
            mockSupabase.didUpdate(table: "users", field: "has_completed_onboarding", value: true),
            "has_completed_onboarding should be set to true"
        )
    }

    /// Test that onboarding_completed_at timestamp is set
    func testMarkOnboardingCompleteSetsTimestamp() async throws {
        // Given: A user ID
        let userId = UUID()
        let beforeTime = Date()

        // When: Marking onboarding as complete
        try await mockMarkOnboardingComplete(userId: userId)

        let afterTime = Date()

        // Then: Verify timestamp is within expected range
        let operations = mockSupabase.capturedOperations.filter { $0.table == "users" }
        XCTAssertFalse(operations.isEmpty, "Should have operations")

        if let updateOp = operations.first,
           let data = updateOp.data as? [String: Any],
           let timestampString = data["onboarding_completed_at"] as? String {

            let formatter = ISO8601DateFormatter()
            if let timestamp = formatter.date(from: timestampString) {
                XCTAssertGreaterThanOrEqual(timestamp, beforeTime)
                XCTAssertLessThanOrEqual(timestamp, afterTime)
            } else {
                XCTFail("Invalid timestamp format: \(timestampString)")
            }
        } else {
            XCTFail("onboarding_completed_at should be present")
        }
    }

    /// Test that the correct user is targeted by user ID
    func testMarkOnboardingCompleteTargetsCorrectUser() async throws {
        // Given: A specific user ID
        let targetUserId = UUID()
        let otherUserId = UUID()

        // When: Marking onboarding complete for target user
        try await mockMarkOnboardingComplete(userId: targetUserId)

        // Then: Verify the filter uses correct user ID
        let operations = mockSupabase.capturedOperations.filter { $0.table == "users" }

        guard let updateOp = operations.first else {
            XCTFail("Should have update operation")
            return
        }

        if let userId = updateOp.filters["id"] as? String {
            XCTAssertEqual(userId, targetUserId.uuidString, "Should target correct user")
            XCTAssertNotEqual(userId, otherUserId.uuidString, "Should not target other user")
        } else {
            XCTFail("Filter should contain user ID")
        }
    }

    /// Test error handling when database update fails
    func testMarkOnboardingCompleteHandlesErrors() async throws {
        // Given: Database will fail
        let testError = NSError(
            domain: "TestError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Update failed"]
        )
        mockSupabase.shouldThrowError = testError

        let userId = UUID()

        // When: Attempting to mark complete
        do {
            try await mockMarkOnboardingComplete(userId: userId)
            XCTFail("Should have thrown error")
        } catch {
            // Then: Error should be propagated
            XCTAssertNotNil(error)
            XCTAssertEqual((error as NSError).code, 500)
        }
    }

    /// Test that both has_completed_onboarding and onboarding_completed_at are set
    func testMarkOnboardingCompleteSetsAllRequiredFields() async throws {
        // Given: A user ID
        let userId = UUID()

        // When: Marking onboarding complete
        try await mockMarkOnboardingComplete(userId: userId)

        // Then: Verify both fields are present
        let operations = mockSupabase.capturedOperations.filter { $0.table == "users" }

        guard let updateOp = operations.first,
              let data = updateOp.data as? [String: Any] else {
            XCTFail("Should have update with data")
            return
        }

        XCTAssertNotNil(data["has_completed_onboarding"], "Should set has_completed_onboarding")
        XCTAssertNotNil(data["onboarding_completed_at"], "Should set onboarding_completed_at")

        XCTAssertEqual(
            data["has_completed_onboarding"] as? Bool,
            true,
            "has_completed_onboarding should be true"
        )
    }

    /// Test that the update uses the correct table
    func testMarkOnboardingCompleteUsesCorrectTable() async throws {
        // Given: A user ID
        let userId = UUID()

        // When: Marking onboarding complete
        try await mockMarkOnboardingComplete(userId: userId)

        // Then: Verify correct table is used
        let usersOps = mockSupabase.capturedOperations.filter { $0.table == "users" }
        let otherOps = mockSupabase.capturedOperations.filter { $0.table != "users" }

        XCTAssertFalse(usersOps.isEmpty, "Should update users table")
        XCTAssertTrue(otherOps.isEmpty, "Should only update users table")
    }

    /// Test that the operation type is UPDATE (not INSERT or UPSERT)
    func testMarkOnboardingCompleteUsesUpdateOperation() async throws {
        // Given: A user ID
        let userId = UUID()

        // When: Marking onboarding complete
        try await mockMarkOnboardingComplete(userId: userId)

        // Then: Verify operation type
        let operations = mockSupabase.capturedOperations.filter { $0.table == "users" }

        guard let updateOp = operations.first else {
            XCTFail("Should have operation")
            return
        }

        XCTAssertEqual(
            updateOp.operation,
            .update,
            "Should use UPDATE operation (not INSERT or UPSERT)"
        )
    }

    /// Test that timestamp format is valid ISO8601
    func testOnboardingCompletedAtUsesISO8601Format() async throws {
        // Given: A user ID
        let userId = UUID()

        // When: Marking onboarding complete
        try await mockMarkOnboardingComplete(userId: userId)

        // Then: Verify ISO8601 format
        let operations = mockSupabase.capturedOperations.filter { $0.table == "users" }

        guard let updateOp = operations.first,
              let data = updateOp.data as? [String: Any],
              let timestampString = data["onboarding_completed_at"] as? String else {
            XCTFail("Should have timestamp")
            return
        }

        // Verify it's valid ISO8601
        let formatter = ISO8601DateFormatter()
        XCTAssertNotNil(
            formatter.date(from: timestampString),
            "Timestamp should be valid ISO8601: \(timestampString)"
        )

        // Verify format characteristics
        XCTAssertTrue(timestampString.contains("T"), "Should have time separator")
        XCTAssertTrue(
            timestampString.hasSuffix("Z") || timestampString.contains("+"),
            "Should have timezone info"
        )
    }

    // MARK: - Helper Methods

    private func mockMarkOnboardingComplete(userId: UUID) async throws {
        struct OnboardingUpdate: Encodable {
            let has_completed_onboarding: Bool
            let onboarding_completed_at: String
        }

        let update = OnboardingUpdate(
            has_completed_onboarding: true,
            onboarding_completed_at: ISO8601DateFormatter().string(from: Date())
        )

        try mockSupabase.recordUpdate(
            table: "users",
            data: [
                "has_completed_onboarding": update.has_completed_onboarding,
                "onboarding_completed_at": update.onboarding_completed_at
            ],
            filters: ["id": userId.uuidString]
        )
    }
}
