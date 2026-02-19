//
//  EditProfileViewModel.swift
//  Club Ralley
//
//  ViewModel for editing user profile — handles validation and saving
//

import Foundation
import SwiftUI

@MainActor
class EditProfileViewModel: ObservableObject {
    @Published var isSaving = false
    @Published var saveError: String?
    @Published var usernameError: String?
    @Published var bioError: String?
    @Published var nameError: String?
    @Published var currentPhotoURL: String?

    private let supabase = SupabaseManager.shared

    /// Maximum bio length
    static let maxBioLength = 150

    /// Validate all fields and return true if valid
    func validateFields(firstName: String, lastName: String, username: String, bio: String) -> Bool {
        var isValid = true

        // Reset errors
        nameError = nil
        usernameError = nil
        bioError = nil

        // Validate name
        if firstName.trimmingCharacters(in: .whitespaces).isEmpty {
            nameError = "First name is required"
            isValid = false
        } else if lastName.trimmingCharacters(in: .whitespaces).isEmpty {
            nameError = "Last name is required"
            isValid = false
        }

        // Validate username
        let usernameValidation = validateUsername(username)
        if let error = usernameValidation {
            usernameError = error
            isValid = false
        }

        // Validate bio length
        if bio.count > Self.maxBioLength {
            bioError = "Bio must be \(Self.maxBioLength) characters or less"
            isValid = false
        }

        return isValid
    }

    /// Validate username format
    func validateUsername(_ username: String) -> String? {
        let trimmed = username.trimmingCharacters(in: .whitespaces)

        if trimmed.count < 3 {
            return "Username must be at least 3 characters"
        }

        if trimmed.count > 30 {
            return "Username must be 30 characters or less"
        }

        // Only allow alphanumeric and underscores
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        if trimmed.unicodeScalars.contains(where: { !allowedCharacters.contains($0) }) {
            return "Username can only contain letters, numbers, and underscores"
        }

        return nil
    }

    // New profile fields
    @Published var isPrivateAccount: Bool = false
    @Published var playedCollegeSport: Bool = false
    @Published var collegeSport: String = ""
    @Published var collegeSchool: String = ""
    @Published var collegeDivision: CollegeDivision = .club
    @Published var collegeYears: String = ""
    @Published var collegePosition: String = ""

    func saveProfile(
        firstName: String,
        lastName: String,
        username: String,
        bio: String,
        city: String,
        state: String,
        instagramHandle: String,
        profilePhotoURL: String?,
        isPrivateAccount: Bool = false,
        playedCollegeSport: Bool = false,
        collegeSport: String = "",
        collegeSchool: String = "",
        collegeDivision: CollegeDivision = .club,
        collegeYears: String = "",
        collegePosition: String = ""
    ) async -> Bool {
        print("VIEWMODEL saveProfile START")
        print("VIEWMODEL - firstName: \(firstName), lastName: \(lastName)")
        print("VIEWMODEL - username: \(username)")
        print("VIEWMODEL - bio: \(bio.prefix(50))...")
        print("VIEWMODEL - city: \(city), state: \(state)")
        print("VIEWMODEL - instagramHandle: \(instagramHandle)")
        print("VIEWMODEL - profilePhotoURL: \(profilePhotoURL ?? "nil")")
        print("VIEWMODEL - isPrivateAccount: \(isPrivateAccount)")
        print("VIEWMODEL - playedCollegeSport: \(playedCollegeSport)")

        isSaving = true
        saveError = nil

        defer {
            isSaving = false
            print("VIEWMODEL saveProfile END - isSaving set to false")
        }

        // Validate all fields
        guard validateFields(firstName: firstName, lastName: lastName, username: username, bio: bio) else {
            print("VIEWMODEL - Validation failed")
            return false
        }

        // Update local storage
        print("VIEWMODEL - Updating local storage...")
        if let profile = SavedUserProfile.loadFromStorage() {
            print("VIEWMODEL - Found existing profile in local storage")
            let updatedProfile = SavedUserProfile(
                id: profile.id,
                email: profile.email,
                firstName: firstName,
                lastName: lastName,
                username: username,
                phoneNumber: profile.phoneNumber,
                locationCity: city,
                locationState: state,
                profilePhotoURL: profilePhotoURL,
                selectedSports: profile.selectedSports,
                createdAt: profile.createdAt,
                bio: bio.isEmpty ? nil : bio,
                instagramHandle: instagramHandle.isEmpty ? nil : instagramHandle,
                isPrivateAccount: isPrivateAccount,
                playedCollegeSport: playedCollegeSport,
                collegeAthleteInfo: playedCollegeSport ? SavedCollegeAthleteInfo(
                    sport: collegeSport,
                    school: collegeSchool,
                    division: collegeDivision.rawValue,
                    yearsPlayed: collegeYears.isEmpty ? nil : collegeYears,
                    position: collegePosition.isEmpty ? nil : collegePosition
                ) : nil
            )

            // Save to UserDefaults
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(updatedProfile) {
                UserDefaults.standard.set(data, forKey: "currentUserProfile")
                print("VIEWMODEL - Saved to UserDefaults successfully")
            } else {
                print("VIEWMODEL - Failed to encode profile for UserDefaults")
            }
        } else {
            print("VIEWMODEL - No existing profile in local storage")
        }

        // Update Supabase (if connected)
        print("VIEWMODEL - Checking Supabase connection...")
        print("VIEWMODEL - supabase.isAuthenticated: \(supabase.isAuthenticated)")
        print("VIEWMODEL - supabase.currentUser: \(supabase.currentUser?.id.uuidString ?? "nil")")
        print("VIEWMODEL - supabase.currentUser email: \(supabase.currentUser?.email ?? "nil")")

        // Also check saved profile for userId
        var userIdForSupabase: UUID? = SupabaseManager.shared.currentUser?.id
        if let savedProfile = SavedUserProfile.loadFromStorage() {
            print("VIEWMODEL - SavedProfile userId: \(savedProfile.id)")
            print("VIEWMODEL - SavedProfile email: \(savedProfile.email)")
            // Use saved profile's ID as fallback if Supabase currentUser is nil
            if userIdForSupabase == nil {
                userIdForSupabase = savedProfile.id
                print("VIEWMODEL - Using SavedProfile userId as fallback")
            }
        } else {
            print("VIEWMODEL - No SavedProfile found!")
        }

        if let userId = userIdForSupabase {
            print("VIEWMODEL - Updating Supabase for userId: \(userId)")
            do {
                let update = DatabaseUserProfileUpdate(
                    first_name: firstName,
                    last_name: lastName,
                    username: username,
                    bio: bio.isEmpty ? nil : bio,
                    city: city.isEmpty ? nil : city,
                    state: state.isEmpty ? nil : state,
                    instagram_handle: instagramHandle.isEmpty ? nil : instagramHandle,
                    profile_photo_url: profilePhotoURL
                )

                print("VIEWMODEL - Calling supabase.update...")
                try await supabase.update(update, in: "club_users", where: "id = '\(userId)'")
                print("VIEWMODEL - Supabase update SUCCESS")
            } catch {
                print("VIEWMODEL - Supabase update FAILED: \(error)")
                // Don't fail - local update succeeded
            }
        } else {
            print("VIEWMODEL - No userId available for Supabase update")
        }

        // Update SupabaseManager current user
        if let currentUser = supabase.currentUser {
            print("VIEWMODEL - Updating SupabaseManager.currentUser")
            supabase.currentUser = SupabaseUser(
                id: currentUser.id,
                email: currentUser.email,
                firstName: firstName,
                lastName: lastName
            )
            print("VIEWMODEL - SupabaseManager.currentUser updated")
        }

        print("VIEWMODEL saveProfile returning TRUE")
        return true
    }
}

// MARK: - Helper struct for loading from Supabase

struct ClubUserProfileData: Codable {
    let bio: String?
    let instagram_handle: String?
}
