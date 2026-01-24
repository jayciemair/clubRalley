//
//  MockSupabaseClient.swift
//  CheckpointTests
//
//  Mock Supabase client for testing database operations
//

import Foundation
import Supabase

/// Mock Supabase client that captures database operations for testing
@MainActor
class MockSupabaseClient {

    // MARK: - Captured Operations

    struct DatabaseOperation {
        let table: String
        let operation: OperationType
        let data: Any?
        let filters: [String: Any]

        enum OperationType {
            case insert
            case update
            case upsert
            case select
        }
    }

    var capturedOperations: [DatabaseOperation] = []
    var shouldThrowError: Error?
    var mockResponses: [String: Any] = [:]

    // MARK: - Reset

    func reset() {
        capturedOperations = []
        shouldThrowError = nil
        mockResponses = [:]
    }

    // MARK: - Mock Database Operations

    func recordInsert(table: String, data: Any) throws {
        if let error = shouldThrowError {
            throw error
        }

        capturedOperations.append(DatabaseOperation(
            table: table,
            operation: .insert,
            data: data,
            filters: [:]
        ))
    }

    func recordUpdate(table: String, data: Any, filters: [String: Any]) throws {
        if let error = shouldThrowError {
            throw error
        }

        capturedOperations.append(DatabaseOperation(
            table: table,
            operation: .update,
            data: data,
            filters: filters
        ))
    }

    func recordUpsert(table: String, data: Any, onConflict: String) throws {
        if let error = shouldThrowError {
            throw error
        }

        capturedOperations.append(DatabaseOperation(
            table: table,
            operation: .upsert,
            data: data,
            filters: ["onConflict": onConflict]
        ))
    }

    // MARK: - Verification Helpers

    func didUpdate(table: String, field: String, value: Any) -> Bool {
        return capturedOperations.contains { operation in
            guard operation.table == table, operation.operation == .update else {
                return false
            }

            // Check if the data contains the field with the expected value
            if let dict = operation.data as? [String: Any],
               let actualValue = dict[field] {
                return "\(actualValue)" == "\(value)"
            }

            return false
        }
    }

    func didUpdateTable(_ table: String) -> Bool {
        return capturedOperations.contains { $0.table == table && $0.operation == .update }
    }

    func operationCount(for table: String) -> Int {
        return capturedOperations.filter { $0.table == table }.count
    }
}
