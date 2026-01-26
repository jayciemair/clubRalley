//
//  ProfileService.swift
//  Club Ralley
//
//  Minimal stub for Profile service functionality
//

import Foundation

@MainActor
class ProfileService: ObservableObject {
    private let supabase = SupabaseManager.shared
    
    func loadCurrentUserProfile() async throws -> UserProfile? {
        // Return nil so ProfileViewModel uses its mock data
        return nil
    }
    
    func loadUserProfile(userID: UUID) async throws -> UserProfile? {
        // Return nil so ProfileViewModel uses its mock data
        return nil
    }
    
    func toggleFollow(userID: UUID) async throws -> Bool {
        // Simulate API call
        try await Task.sleep(nanoseconds: 200_000_000)
        return true
    }
}