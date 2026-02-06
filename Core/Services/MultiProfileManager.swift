//
//  MultiProfileManager.swift
//  Club Ralley
//
//  Manages multiple user profiles for account switching
//

import Foundation
import SwiftUI

/// Manages multiple saved user profiles for account switching
@MainActor
class MultiProfileManager: ObservableObject {

    // MARK: - Singleton

    static let shared = MultiProfileManager()

    // MARK: - Published Properties

    /// All saved profiles on this device
    @Published var savedProfiles: [MultiProfile] = []

    /// Currently active profile
    @Published var activeProfile: MultiProfile?

    /// Loading state
    @Published var isLoading = false

    /// Error state
    @Published var error: String?

    // MARK: - Storage Keys

    private let profilesKey = "clubRalley_savedProfiles"
    private let activeProfileIdKey = "clubRalley_activeProfileId"

    // MARK: - Initialization

    private init() {
        loadSavedProfiles()
    }

    // MARK: - Profile Management

    /// Load all saved profiles from storage
    func loadSavedProfiles() {
        guard let data = UserDefaults.standard.data(forKey: profilesKey) else {
            savedProfiles = []

            // Migration: Check for legacy single profile
            if let legacyProfile = SavedUserProfile.loadFromStorage() {
                let multiProfile = MultiProfile(from: legacyProfile)
                savedProfiles = [multiProfile]
                activeProfile = multiProfile
                saveAllProfiles()
                print("MultiProfileManager: Migrated legacy profile to multi-profile storage")
            }
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            savedProfiles = try decoder.decode([MultiProfile].self, from: data)

            // Load active profile
            if let activeId = UserDefaults.standard.string(forKey: activeProfileIdKey),
               let uuid = UUID(uuidString: activeId),
               let profile = savedProfiles.first(where: { $0.id == uuid }) {
                activeProfile = profile
            } else if let firstProfile = savedProfiles.first {
                activeProfile = firstProfile
            }

            print("MultiProfileManager: Loaded \(savedProfiles.count) profiles")
        } catch {
            print("MultiProfileManager: Failed to decode profiles: \(error)")
            savedProfiles = []
        }
    }

    /// Save all profiles to storage
    func saveAllProfiles() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(savedProfiles)
            UserDefaults.standard.set(data, forKey: profilesKey)

            if let activeId = activeProfile?.id {
                UserDefaults.standard.set(activeId.uuidString, forKey: activeProfileIdKey)
            }

            print("MultiProfileManager: Saved \(savedProfiles.count) profiles")
        } catch {
            print("MultiProfileManager: Failed to save profiles: \(error)")
        }
    }

    /// Add a new profile (after sign in/sign up)
    func addProfile(_ profile: SavedUserProfile, setAsActive: Bool = true) {
        let multiProfile = MultiProfile(from: profile)

        // Check if profile already exists
        if let index = savedProfiles.firstIndex(where: { $0.id == profile.id }) {
            // Update existing profile
            savedProfiles[index] = multiProfile
            print("MultiProfileManager: Updated existing profile: \(profile.email)")
        } else {
            // Add new profile
            savedProfiles.append(multiProfile)
            print("MultiProfileManager: Added new profile: \(profile.email)")
        }

        if setAsActive {
            activeProfile = multiProfile
        }

        saveAllProfiles()

        // Also save as legacy format for backward compatibility
        saveLegacyProfile(profile)
    }

    /// Switch to a different profile
    func switchToProfile(_ profile: MultiProfile) async throws {
        isLoading = true
        error = nil

        do {
            // Update last used timestamp
            if let index = savedProfiles.firstIndex(where: { $0.id == profile.id }) {
                savedProfiles[index].lastUsed = Date()
            }

            // Set as active
            activeProfile = profile
            saveAllProfiles()

            // Update SupabaseManager auth state
            let supabase = SupabaseManager.shared
            supabase.isAuthenticated = true
            supabase.currentUser = SupabaseUser(
                id: profile.id,
                email: profile.email,
                firstName: profile.firstName,
                lastName: profile.lastName
            )

            // Save as legacy format for other parts of the app
            let legacyProfile = profile.toSavedUserProfile()
            saveLegacyProfile(legacyProfile)

            // Post notification for UI updates
            NotificationCenter.default.post(
                name: NSNotification.Name("ProfileDidSwitch"),
                object: profile
            )

            print("MultiProfileManager: Switched to profile: \(profile.email)")
            isLoading = false

        } catch {
            self.error = "Failed to switch profile: \(error.localizedDescription)"
            isLoading = false
            throw error
        }
    }

    /// Remove a profile from saved profiles
    func removeProfile(_ profileId: UUID) {
        savedProfiles.removeAll { $0.id == profileId }

        // If we removed the active profile, switch to another
        if activeProfile?.id == profileId {
            activeProfile = savedProfiles.first
            if let newActive = activeProfile {
                Task {
                    try? await switchToProfile(newActive)
                }
            }
        }

        saveAllProfiles()
        print("MultiProfileManager: Removed profile \(profileId)")
    }

    /// Sign out from current profile (keeps in saved profiles but marks as inactive)
    func signOutCurrentProfile() {
        if let current = activeProfile,
           let index = savedProfiles.firstIndex(where: { $0.id == current.id }) {
            savedProfiles[index].isLoggedIn = false
        }

        // Clear legacy storage
        SavedUserProfile.clearStorage()
        UserDefaults.standard.removeObject(forKey: "hasCompletedClubRalleyOnboarding")

        // Clear Supabase auth state
        let supabase = SupabaseManager.shared
        supabase.isAuthenticated = false
        supabase.currentUser = nil

        activeProfile = nil
        saveAllProfiles()

        // Post notification for UI updates
        NotificationCenter.default.post(
            name: NSNotification.Name("UserDidLogout"),
            object: nil
        )

        print("MultiProfileManager: Signed out current profile")
    }

    /// Remove all saved profiles (full logout)
    func removeAllProfiles() {
        savedProfiles = []
        activeProfile = nil

        UserDefaults.standard.removeObject(forKey: profilesKey)
        UserDefaults.standard.removeObject(forKey: activeProfileIdKey)

        SavedUserProfile.clearStorage()
        UserDefaults.standard.removeObject(forKey: "hasCompletedClubRalleyOnboarding")

        let supabase = SupabaseManager.shared
        supabase.isAuthenticated = false
        supabase.currentUser = nil

        NotificationCenter.default.post(
            name: NSNotification.Name("UserDidLogout"),
            object: nil
        )

        print("MultiProfileManager: Removed all profiles")
    }

    /// Get profiles sorted by last used
    var sortedProfiles: [MultiProfile] {
        savedProfiles.sorted { $0.lastUsed > $1.lastUsed }
    }

    /// Check if a profile is the currently active one
    func isActiveProfile(_ profile: MultiProfile) -> Bool {
        return activeProfile?.id == profile.id
    }

    // MARK: - Private Helpers

    private func saveLegacyProfile(_ profile: SavedUserProfile) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(profile) {
            UserDefaults.standard.set(data, forKey: "currentUserProfile")
        }
    }
}

// MARK: - MultiProfile Model

/// Extended profile model for multi-account support
struct MultiProfile: Codable, Identifiable, Hashable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
    let username: String
    let phoneNumber: String
    let locationCity: String
    let locationState: String
    let profilePhotoURL: String?
    let selectedSports: [String]
    let createdAt: Date
    var bio: String?
    var instagramHandle: String?

    // Multi-profile specific fields
    var lastUsed: Date
    var isLoggedIn: Bool

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var displayLocation: String {
        if locationCity.isEmpty { return "" }
        return "\(locationCity), \(locationState)"
    }

    var initials: String {
        let first = firstName.first.map(String.init) ?? ""
        let last = lastName.first.map(String.init) ?? ""
        return "\(first)\(last)".uppercased()
    }

    // Initialize from SavedUserProfile
    init(from saved: SavedUserProfile) {
        self.id = saved.id
        self.email = saved.email
        self.firstName = saved.firstName
        self.lastName = saved.lastName
        self.username = saved.username
        self.phoneNumber = saved.phoneNumber
        self.locationCity = saved.locationCity
        self.locationState = saved.locationState
        self.profilePhotoURL = saved.profilePhotoURL
        self.selectedSports = saved.selectedSports
        self.createdAt = saved.createdAt
        self.bio = saved.bio
        self.instagramHandle = saved.instagramHandle
        self.lastUsed = Date()
        self.isLoggedIn = true
    }

    // Convert back to SavedUserProfile
    func toSavedUserProfile() -> SavedUserProfile {
        return SavedUserProfile(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            username: username,
            phoneNumber: phoneNumber,
            locationCity: locationCity,
            locationState: locationState,
            profilePhotoURL: profilePhotoURL,
            selectedSports: selectedSports,
            createdAt: createdAt,
            bio: bio,
            instagramHandle: instagramHandle
        )
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MultiProfile, rhs: MultiProfile) -> Bool {
        lhs.id == rhs.id
    }
}
