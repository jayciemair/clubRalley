//
//  PowerUpProfileService.swift
//  Club Ralley
//
//  Service for saving and loading Power Up Profile data
//  Uses JSONB columns in users table (lean schema)
//

import Foundation

@MainActor
class PowerUpProfileService {

    // MARK: - Dependencies

    private let supabase = SupabaseManager.shared

    // MARK: - Load Existing Data

    /// Load existing profile data from users JSONB columns
    func loadExistingProfileData() async throws -> PowerUpProfileData {
        print("🔵 helloWORLD POWERUP loadExistingProfileData START")
        print("🔵 helloWORLD POWERUP - isAuthenticated: \(supabase.isAuthenticated)")
        print("🔵 helloWORLD POWERUP - currentUser: \(supabase.currentUser?.id.uuidString ?? "nil")")

        guard supabase.isAuthenticated, let userId = supabase.currentUser?.id else {
            print("🔴 helloWORLD POWERUP loadExistingProfileData - NOT AUTHENTICATED")
            throw PowerUpProfileError.notAuthenticated
        }

        print("🔵 helloWORLD POWERUP - Loading for userId: \(userId)")

        var data = PowerUpProfileData()

        // Load user profile with JSONB columns
        do {
            print("🔵 helloWORLD POWERUP - Calling loadUserProfile...")
            if let profile = try await loadUserProfile(userId: userId) {
                print("🟢 helloWORLD POWERUP - Loaded profile successfully")
                print("🔵 helloWORLD POWERUP - bio: \(profile.bio ?? "nil")")
                print("🔵 helloWORLD POWERUP - instagram: \(profile.instagram_handle ?? "nil")")
                print("🔵 helloWORLD POWERUP - sports count: \(profile.sports?.count ?? 0)")

                data.instagramHandle = profile.instagram_handle ?? ""
                data.bio = profile.bio ?? ""
                data.profilePhotoURL = profile.profile_photo_url

                // Load sports from JSONB
                data.sportsWithSkills = parseSportsFromJson(profile.sports)
                print("🔵 helloWORLD POWERUP - Parsed \(data.sportsWithSkills.count) sports")

                // Load availability from JSONB
                let avail = parseAvailabilityFromJson(profile.availability)
                data.selectedDays = avail.days
                data.timePreference = avail.timePreference
                print("🔵 helloWORLD POWERUP - Parsed \(data.selectedDays.count) available days")

                // Load preferences from JSONB
                let prefs = parsePreferencesFromJson(profile.preferences)
                data.maxDistance = prefs.maxDistance
                data.wouldDoHappyHour = prefs.wouldDoHappyHour
                data.workoutBrands = prefs.workoutBrands
                data.workoutClasses = prefs.workoutClasses
                data.hometown = prefs.hometown
                data.favoriteProTeam = prefs.favoriteTeam
                print("🔵 helloWORLD POWERUP - Parsed preferences: maxDistance=\(prefs.maxDistance)")
            } else {
                print("🔴 helloWORLD POWERUP - loadUserProfile returned nil")
            }
        } catch {
            print("🔴 helloWORLD POWERUP loadUserProfile FAILED: \(error)")
        }

        print("🟢 helloWORLD POWERUP loadExistingProfileData END")
        return data
    }

    // MARK: - Save All Data

    /// Save all Power Up Profile data to users JSONB columns
    func saveProfileData(_ data: PowerUpProfileData) async throws {
        print("🔵 helloWORLD POWERUP saveProfileData START")
        print("🔵 helloWORLD POWERUP - isAuthenticated: \(supabase.isAuthenticated)")
        print("🔵 helloWORLD POWERUP - currentUser: \(supabase.currentUser?.id.uuidString ?? "nil")")

        guard supabase.isAuthenticated, let userId = supabase.currentUser?.id else {
            print("🔴 helloWORLD POWERUP saveProfileData - NOT AUTHENTICATED")
            throw PowerUpProfileError.notAuthenticated
        }

        print("🔵 helloWORLD POWERUP - Saving for userId: \(userId)")
        print("🔵 helloWORLD POWERUP - bio: \(data.bio.prefix(30))...")
        print("🔵 helloWORLD POWERUP - instagram: \(data.instagramHandle)")
        print("🔵 helloWORLD POWERUP - sports count: \(data.sportsWithSkills.count)")
        print("🔵 helloWORLD POWERUP - selected days: \(data.effectiveSelectedDays)")

        // Build sports array
        let sportsArray = data.sportsWithSkills.map { sport in
            SportEntryUpdate(
                name: sport.sport.name,
                skill: sport.skillLevel.rawValue
            )
        }
        print("🔵 helloWORLD POWERUP - Built \(sportsArray.count) sports entries")

        // Build availability array
        let availArray = data.effectiveSelectedDays.map { day in
            AvailabilityEntryUpdate(
                day: day,
                time: data.timePreference.rawValue
            )
        }
        print("🔵 helloWORLD POWERUP - Built \(availArray.count) availability entries")

        // Build preferences
        let prefs = PreferencesDataUpdate(
            max_distance: data.maxDistance,
            would_do_happy_hour: data.wouldDoHappyHour ?? false,
            workout_brands: data.workoutBrands,
            workout_classes: data.workoutClasses,
            hometown: data.hometown,
            favorite_team: data.favoriteProTeam
        )
        print("🔵 helloWORLD POWERUP - Built preferences: maxDistance=\(prefs.max_distance)")

        // Update users with all JSONB data
        let update = ClubUserProfileUpdate(
            bio: data.bio.isEmpty ? nil : data.bio,
            instagram_handle: data.instagramHandle.isEmpty ? nil : data.instagramHandle,
            profile_photo_url: data.profilePhotoURL,
            sports: sportsArray.isEmpty ? nil : sportsArray,
            availability: availArray.isEmpty ? nil : availArray,
            preferences: prefs
        )

        print("🔵 helloWORLD POWERUP - Calling supabase.update...")
        do {
            try await supabase.update(update, in: "club_users", where: "id = '\(userId)'")
            print("🟢 helloWORLD POWERUP saveProfileData SUCCESS")
        } catch {
            print("🔴 helloWORLD POWERUP saveProfileData FAILED: \(error)")
            throw error
        }
    }

    // MARK: - Private Load Methods

    private func loadUserProfile(userId: UUID) async throws -> ClubUserWithJsonb? {
        try await supabase.query("club_users")
            .select("*")
            .eq("id", value: userId)
            .single()
    }

    // MARK: - JSON Parsing Helpers

    private func parseSportsFromJson(_ sports: [SportEntry]?) -> [SportWithSkill] {
        guard let sports = sports else { return [] }

        return sports.compactMap { entry -> SportWithSkill? in
            let skillLevel = PowerUpSkillLevel(rawValue: entry.skill ?? "competitor") ?? .competitor

            let sport = Sport(
                id: UUID(),
                name: entry.name,
                category: .recreational,
                iconName: "sportscourt",
                isPopular: true
            )
            return SportWithSkill(id: UUID(), sport: sport, skillLevel: skillLevel)
        }
    }

    private func parseAvailabilityFromJson(_ avail: [AvailabilityEntry]?) -> (days: Set<Int>, timePreference: TimePreference) {
        guard let avail = avail, !avail.isEmpty else {
            return (Set(), .anytime)
        }

        var days = Set<Int>()
        var timePreference: TimePreference = .anytime

        for item in avail {
            days.insert(item.day)
            timePreference = TimePreference(rawValue: item.time) ?? .anytime
        }

        return (days, timePreference)
    }

    private func parsePreferencesFromJson(_ prefs: PreferencesData?) -> (maxDistance: Int, wouldDoHappyHour: Bool?, workoutBrands: [String], workoutClasses: [String], hometown: String, favoriteTeam: String) {
        guard let prefs = prefs else {
            return (25, nil, [], [], "", "")
        }

        return (
            prefs.max_distance ?? 25,
            prefs.would_do_happy_hour,
            prefs.workout_brands ?? [],
            prefs.workout_classes ?? [],
            prefs.hometown ?? "",
            prefs.favorite_team ?? ""
        )
    }
}

// MARK: - Database Models

/// Struct for loading user profile with JSONB columns
struct ClubUserWithJsonb: Codable {
    let id: UUID
    let email: String
    let first_name: String?
    let last_name: String?
    let username: String
    let profile_photo_url: String?
    let bio: String?
    let city: String?
    let state: String?
    let instagram_handle: String?
    let sports: [SportEntry]?
    let availability: [AvailabilityEntry]?
    let preferences: PreferencesData?
}

/// Helper struct for sports JSONB
struct SportEntry: Codable {
    let name: String
    let skill: String?
}

/// Helper struct for availability JSONB
struct AvailabilityEntry: Codable {
    let day: Int
    let time: String
}

/// Helper struct for preferences JSONB
struct PreferencesData: Codable {
    let max_distance: Int?
    let would_do_happy_hour: Bool?
    let workout_brands: [String]?
    let workout_classes: [String]?
    let hometown: String?
    let favorite_team: String?
}

/// Encodable struct for sport entries
struct SportEntryUpdate: Encodable {
    let name: String
    let skill: String
}

/// Encodable struct for availability entries
struct AvailabilityEntryUpdate: Encodable {
    let day: Int
    let time: String
}

/// Encodable struct for preferences
struct PreferencesDataUpdate: Encodable {
    let max_distance: Int
    let would_do_happy_hour: Bool
    let workout_brands: [String]
    let workout_classes: [String]
    let hometown: String
    let favorite_team: String
}

struct ClubUserProfileUpdate: Encodable {
    let bio: String?
    let instagram_handle: String?
    let profile_photo_url: String?
    let sports: [SportEntryUpdate]?
    let availability: [AvailabilityEntryUpdate]?
    let preferences: PreferencesDataUpdate?
}

// MARK: - Errors

enum PowerUpProfileError: LocalizedError {
    case notAuthenticated
    case loadFailed(String)
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to update your profile"
        case .loadFailed(let message):
            return "Failed to load profile data: \(message)"
        case .saveFailed(let message):
            return "Failed to save profile data: \(message)"
        }
    }
}
