//
//  UserProfileService.swift
//  Get Over Him
//
//  Manages user profile data in Supabase (lean version)
//

import Foundation
import Supabase
import os.log

/// User profile model matching the Supabase users table
struct SupabaseUserProfile: Codable {
    let id: UUID
    let name: String?
    let createdAt: Date?
    let breakupTiming: String?
    let whoEndedIt: String?
    let whatsHurting: [String]?
    let howCoping: [String]?
    let mainGoals: [String]?
    let checkinFrequency: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
        case breakupTiming = "breakup_timing"
        case whoEndedIt = "who_ended_it"
        case whatsHurting = "whats_hurting"
        case howCoping = "how_coping"
        case mainGoals = "main_goals"
        case checkinFrequency = "checkin_frequency"
    }

    // For compatibility with old code expecting hasCompletedOnboarding
    var hasCompletedOnboarding: Bool {
        return true // If user exists in table, they've completed onboarding
    }
}

/// Onboarding data to save to users table
struct OnboardingFieldsUpdate: Encodable {
    let name: String?
    let breakup_timing: String?
    let who_ended_it: String?
    let whats_hurting: [String]?
    let how_coping: [String]?
    let main_goals: [String]?
    let checkin_frequency: Int?
}

/// Manages user profile operations with Supabase
final class UserProfileService {

    // MARK: - Singleton

    static let shared = UserProfileService()

    // MARK: - Properties

    private let supabase = SupabaseClientManager.shared
    private let logger = os.Logger(subsystem: "com.getoverhim", category: "UserProfile")

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Fetch user profile from Supabase
    func fetchUserProfile(userId: UUID) async throws -> SupabaseUserProfile? {
        logger.info("📥 Fetching user profile for: \(userId.uuidString)")

        do {
            let response: SupabaseUserProfile? = try await supabase.database
                .from("users")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value

            logger.info("✅ User profile fetched")
            return response
        } catch {
            let errorMessage = error.localizedDescription.lowercased()
            if errorMessage.contains("cannot coerce") || errorMessage.contains("single") {
                logger.info("⚠️ No user profile found - user doesn't exist yet")
                return nil
            }
            logger.error("❌ Failed to fetch user profile: \(error.localizedDescription)")
            throw error
        }
    }

    /// Create a new user profile in Supabase
    func createUserProfile(userId: UUID, email: String?, hasCompletedOnboarding: Bool) async throws -> SupabaseUserProfile {
        logger.info("📝 Creating user profile for: \(userId.uuidString)")

        struct NewUserInsert: Encodable {
            let id: String
            let name: String?
        }

        let newUser = NewUserInsert(
            id: userId.uuidString,
            name: nil
        )

        do {
            let response: SupabaseUserProfile = try await supabase.database
                .from("users")
                .insert(newUser)
                .select()
                .single()
                .execute()
                .value

            logger.info("✅ User profile created successfully")
            return response
        } catch {
            logger.error("❌ Failed to create user profile: \(error.localizedDescription)")
            throw error
        }
    }

    /// Get or create user profile
    func getOrCreateUserProfile(userId: UUID, email: String?, hasCompletedOnboarding: Bool) async throws -> SupabaseUserProfile {
        logger.info("🔍 Getting or creating user profile for: \(userId.uuidString)")

        if let existingProfile = try await fetchUserProfile(userId: userId) {
            logger.info("📦 Found existing profile")
            return existingProfile
        }

        logger.info("🆕 Profile not found, creating new one")
        return try await createUserProfile(userId: userId, email: email, hasCompletedOnboarding: hasCompletedOnboarding)
    }

    /// Check if user has completed onboarding (user exists = completed)
    func hasCompletedOnboarding(userId: UUID) async throws -> Bool {
        logger.info("🔍 Checking onboarding status for: \(userId.uuidString)")

        let profile = try await fetchUserProfile(userId: userId)
        let completed = profile != nil
        logger.info("📊 Onboarding status: \(completed ? "complete" : "incomplete")")
        return completed
    }

    /// Update user name
    func updateName(userId: UUID, name: String) async throws {
        logger.info("📝 Updating name for: \(userId.uuidString)")

        struct NameUpdate: Encodable {
            let name: String
        }

        try await supabase.database
            .from("users")
            .update(NameUpdate(name: name))
            .eq("id", value: userId.uuidString)
            .execute()

        logger.info("✅ Name updated successfully")
    }

    /// Save onboarding fields to individual columns
    func saveOnboardingFields(userId: UUID, fields: OnboardingFieldsUpdate) async throws {
        logger.info("📝 Saving onboarding fields for: \(userId.uuidString)")

        try await supabase.database
            .from("users")
            .update(fields)
            .eq("id", value: userId.uuidString)
            .execute()

        logger.info("✅ Onboarding fields saved")
    }

    #if DEBUG
    func deleteUserProfile(userId: UUID) async throws {
        logger.warning("🗑️ [DEBUG] Deleting user profile: \(userId.uuidString)")
        try await supabase.database
            .from("users")
            .delete()
            .eq("id", value: userId.uuidString)
            .execute()
        logger.info("✅ [DEBUG] User profile deleted")
    }
    #endif
}
