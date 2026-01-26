//
//  SupabaseManager.swift 
//  Club Ralley
//
//  Minimal stub for Supabase functionality
//

import Foundation
import SwiftUI

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: MockSupabaseUser?
    
    private init() {}
    
    // Stub methods to satisfy compilation
    func signInAsGracie() {
        // Mock sign in
        isAuthenticated = true
        currentUser = MockSupabaseUser(id: UUID(), email: "gracie@example.com")
        print("Mock sign in as Gracie")
    }
    
    func signOut() {
        isAuthenticated = false 
        currentUser = nil
        print("Mock sign out")
    }
    
    // Generic database methods (return empty for now)
    func query<T: Codable>(_ table: String) -> MockQueryBuilder<T> {
        return MockQueryBuilder<T>()
    }
    
    func insert<T: Codable>(_ data: T, into table: String) async throws {
        print("Mock insert into \(table)")
    }
    
    func update<T: Codable>(_ data: T, in table: String) async throws {
        print("Mock update in \(table)")
    }
    
    func delete(from table: String, where condition: String) async throws {
        print("Mock delete from \(table)")
    }
}

// Mock Supabase User type
struct MockSupabaseUser: Codable {
    let id: UUID
    let email: String
}

// Mock query builder
class MockQueryBuilder<T: Codable> {
    func select(_ columns: String = "*") -> Self { return self }
    func eq(_ column: String, value: Any) -> Self { return self }
    func single() async throws -> T? { return nil }
    func execute() async throws -> [T] { return [] }
}

// Mock error types
extension SupabaseManager {
    enum SupabaseError: LocalizedError {
        case notAuthenticated
        case userNotFound
        case networkError
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .notAuthenticated: return "Not authenticated"
            case .userNotFound: return "User not found"
            case .networkError: return "Network error"
            case .invalidData: return "Invalid data"
            }
        }
    }
}