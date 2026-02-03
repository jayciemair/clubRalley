//
//  PowerUpProfileService.swift
//  Club Ralley
//
//  Service for saving and loading Power Up Profile data
//

import Foundation

@MainActor
class PowerUpProfileService {

    // MARK: - Dependencies

    private let supabase = SupabaseManager.shared

    // MARK: - Load Existing Data

    /// Load existing profile data to pre-populate the wizard
    func loadExistingProfileData() async throws -> PowerUpProfileData {
        guard supabase.isAuthenticated, let userId = supabase.currentUser?.id else {
            throw PowerUpProfileError.notAuthenticated
        }

        var data = PowerUpProfileData()

        // Load user profile (bio, instagram, photo)
        if let profile = try? await loadUserProfile(userId: userId) {
            data.instagramHandle = profile.instagram_handle ?? ""
            data.bio = profile.bio ?? ""
            data.profilePhotoURL = profile.profile_photo_url
        }

        // Load user sports with skill levels
        data.sportsWithSkills = await loadUserSports(userId: userId)

        // Load user interests
        if let interests = try? await loadUserInterests(userId: userId) {
            data.workoutBrands = interests.workoutBrands
            data.workoutClasses = interests.classTypes
            data.hometown = interests.hometown ?? ""
            data.favoriteProTeam = interests.favoriteTeam
        }

        // Load availability
        let availability = await loadUserAvailability(userId: userId)
        data.selectedDays = availability.days
        data.timePreference = availability.timePreference
        data.maxDistance = availability.maxDistance

        // Load preferences (happy hour)
        if let prefs = try? await loadUserPreferences(userId: userId) {
            data.wouldDoHappyHour = prefs.wouldDoHappyHour
        }

        return data
    }

    // MARK: - Save All Data

    /// Save all Power Up Profile data to respective tables
    func saveProfileData(_ data: PowerUpProfileData) async throws {
        guard supabase.isAuthenticated, let userId = supabase.currentUser?.id else {
            throw PowerUpProfileError.notAuthenticated
        }

        // Save in parallel where possible
        async let profileSave: () = saveUserProfile(userId: userId, data: data)
        async let sportsSave: () = saveUserSports(userId: userId, data: data)
        async let interestsSave: () = saveUserInterests(userId: userId, data: data)
        async let availabilitySave: () = saveUserAvailability(userId: userId, data: data)
        async let preferencesSave: () = saveUserPreferences(userId: userId, data: data)

        // Wait for all saves to complete
        _ = try await (profileSave, sportsSave, interestsSave, availabilitySave, preferencesSave)

        print("PowerUpProfileService: All data saved successfully")
    }

    // MARK: - Load Sports

    func loadSports() async throws -> [Sport] {
        do {
            let sports: [Sport] = try await supabase.query("sports")
                .select("*")
                .order("is_popular", ascending: false)
                .order("name", ascending: true)
                .execute()

            return sports
        } catch {
            print("PowerUpProfileService: Failed to load sports: \(error)")
            throw PowerUpProfileError.loadFailed(error.localizedDescription)
        }
    }

    // MARK: - Private Load Methods

    private func loadUserProfile(userId: UUID) async throws -> DatabaseUserProfile? {
        try await supabase.query("club_users")
            .select("*")
            .eq("id", value: userId)
            .single()
    }

    private func loadUserSports(userId: UUID) async -> [SportWithSkill] {
        do {
            let userSports: [DatabaseUserSport] = try await supabase.query("user_sports")
                .select("*, sports(*)")
                .eq("user_id", value: userId)
                .execute()

            return userSports.compactMap { dbSport -> SportWithSkill? in
                guard let sport = dbSport.sport else { return nil }
                let skillLevel = PowerUpSkillLevel(rawValue: dbSport.skill_level) ?? .competitor
                return SportWithSkill(id: dbSport.id, sport: sport, skillLevel: skillLevel)
            }
        } catch {
            print("PowerUpProfileService: Failed to load user sports: \(error)")
            return []
        }
    }

    private func loadUserInterests(userId: UUID) async throws -> DatabaseUserInterests? {
        try await supabase.query("user_interests")
            .select("*")
            .eq("user_id", value: userId)
            .single()
    }

    private func loadUserAvailability(userId: UUID) async -> (days: Set<Int>, timePreference: TimePreference, maxDistance: Int) {
        do {
            let slots: [DatabaseAvailabilitySlot] = try await supabase.query("user_availability")
                .select("*")
                .eq("user_id", value: userId)
                .execute()

            let days = Set(slots.map { $0.day_of_week })

            // Determine time preference from slots
            var timePreference: TimePreference = .anytime
            if let firstSlot = slots.first {
                if let startHour = Int(firstSlot.start_time.prefix(2)) {
                    if startHour < 12 {
                        timePreference = .morning
                    } else if startHour < 17 {
                        timePreference = .afternoon
                    } else {
                        timePreference = .evening
                    }
                }
            }

            // Load max distance from preferences
            var maxDistance = 25
            if let prefs: DatabaseUserPreferences = try? await supabase.query("user_preferences")
                .select("*")
                .eq("user_id", value: userId)
                .single() {
                maxDistance = prefs.max_distance ?? 25
            }

            return (days, timePreference, maxDistance)
        } catch {
            print("PowerUpProfileService: Failed to load availability: \(error)")
            return (Set(), .anytime, 25)
        }
    }

    private func loadUserPreferences(userId: UUID) async throws -> DatabaseUserPreferences? {
        try await supabase.query("user_preferences")
            .select("*")
            .eq("user_id", value: userId)
            .single()
    }

    // MARK: - Private Save Methods

    private func saveUserProfile(userId: UUID, data: PowerUpProfileData) async throws {
        let update = DatabaseUserProfileUpdate(
            bio: data.bio.isEmpty ? nil : data.bio,
            instagram_handle: data.instagramHandle.isEmpty ? nil : data.instagramHandle,
            profile_photo_url: data.profilePhotoURL
        )

        try await supabase.update(update, in: "club_users", where: "id = '\(userId)'")
        print("PowerUpProfileService: Profile saved")
    }

    private func saveUserSports(userId: UUID, data: PowerUpProfileData) async throws {
        // Delete existing sports first
        try await supabase.delete(from: "user_sports", where: "user_id = '\(userId)'")

        // Insert new sports
        for sportWithSkill in data.sportsWithSkills {
            let dbSport = DatabaseUserSportInsert(
                user_id: userId,
                sport_id: sportWithSkill.sport.id,
                skill_level: sportWithSkill.skillLevel.rawValue,
                is_preferred: true
            )
            try await supabase.insert(dbSport, into: "user_sports")
        }
        print("PowerUpProfileService: Sports saved (\(data.sportsWithSkills.count) sports)")
    }

    private func saveUserInterests(userId: UUID, data: PowerUpProfileData) async throws {
        // Check if interests record exists
        let existing: [DatabaseUserInterests] = try await supabase.query("user_interests")
            .select("*")
            .eq("user_id", value: userId)
            .execute()

        let interests = DatabaseUserInterestsUpsert(
            user_id: userId,
            hobbies: [],
            workout_brands: data.workoutBrands,
            class_types: data.workoutClasses,
            hometown: data.hometown.isEmpty ? nil : data.hometown,
            favorite_teams: data.favoriteProTeam.isEmpty ? [] : [data.favoriteProTeam]
        )

        if existing.isEmpty {
            try await supabase.insert(interests, into: "user_interests")
        } else {
            try await supabase.update(interests, in: "user_interests", where: "user_id = '\(userId)'")
        }
        print("PowerUpProfileService: Interests saved")
    }

    private func saveUserAvailability(userId: UUID, data: PowerUpProfileData) async throws {
        // Delete existing availability
        try await supabase.delete(from: "user_availability", where: "user_id = '\(userId)'")

        // Get effective days
        let days = data.effectiveSelectedDays

        // Determine time range based on preference
        let (startTime, endTime) = timeRangeForPreference(data.timePreference)

        // Insert availability slots
        for day in days {
            let slot = DatabaseAvailabilitySlotInsert(
                user_id: userId,
                day_of_week: day,
                start_time: startTime,
                end_time: endTime
            )
            try await supabase.insert(slot, into: "user_availability")
        }
        print("PowerUpProfileService: Availability saved (\(days.count) days)")
    }

    private func saveUserPreferences(userId: UUID, data: PowerUpProfileData) async throws {
        // Check if preferences exist
        let existing: [DatabaseUserPreferences] = try await supabase.query("user_preferences")
            .select("*")
            .eq("user_id", value: userId)
            .execute()

        var socialPrefs: [String: Any] = [:]
        if let happyHour = data.wouldDoHappyHour {
            socialPrefs["would_do_happy_hour"] = happyHour
        }

        let prefs = DatabaseUserPreferencesUpsert(
            user_id: userId,
            max_distance: data.maxDistance,
            social_preferences: socialPrefs
        )

        if existing.isEmpty {
            try await supabase.insert(prefs, into: "user_preferences")
        } else {
            try await supabase.update(prefs, in: "user_preferences", where: "user_id = '\(userId)'")
        }
        print("PowerUpProfileService: Preferences saved")
    }

    // MARK: - Helpers

    private func timeRangeForPreference(_ preference: TimePreference) -> (start: String, end: String) {
        switch preference {
        case .morning:
            return ("06:00", "12:00")
        case .afternoon:
            return ("12:00", "17:00")
        case .evening:
            return ("17:00", "22:00")
        case .anytime:
            return ("06:00", "22:00")
        }
    }
}

// MARK: - Database Models for Power Up

struct DatabaseUserSport: Codable {
    let id: UUID
    let user_id: UUID
    let sport_id: UUID
    let skill_level: String
    let is_preferred: Bool
    let sport: Sport?
}

struct DatabaseUserSportInsert: Codable {
    let user_id: UUID
    let sport_id: UUID
    let skill_level: String
    let is_preferred: Bool
}

struct DatabaseUserInterests: Codable {
    let id: UUID?
    let user_id: UUID
    let hobbies: [String]?
    let workout_brands: [String]?
    let class_types: [String]?
    let hometown: String?
    let favorite_teams: [String]?

    var workoutBrands: [String] {
        workout_brands ?? []
    }

    var classTypes: [String] {
        class_types ?? []
    }

    var favoriteTeam: String {
        favorite_teams?.first ?? ""
    }
}

struct DatabaseUserInterestsUpsert: Codable {
    let user_id: UUID
    let hobbies: [String]
    let workout_brands: [String]
    let class_types: [String]
    let hometown: String?
    let favorite_teams: [String]
}

struct DatabaseAvailabilitySlot: Codable {
    let id: UUID
    let user_id: UUID
    let day_of_week: Int
    let start_time: String
    let end_time: String
}

struct DatabaseAvailabilitySlotInsert: Codable {
    let user_id: UUID
    let day_of_week: Int
    let start_time: String
    let end_time: String
}

struct DatabaseUserPreferences: Codable {
    let id: UUID?
    let user_id: UUID
    let max_distance: Int?
    let social_preferences: [String: Bool]?

    var wouldDoHappyHour: Bool? {
        social_preferences?["would_do_happy_hour"]
    }
}

struct DatabaseUserPreferencesUpsert: Codable {
    let user_id: UUID
    let max_distance: Int
    let social_preferences: [String: Any]

    enum CodingKeys: String, CodingKey {
        case user_id
        case max_distance
        case social_preferences
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user_id, forKey: .user_id)
        try container.encode(max_distance, forKey: .max_distance)
        // Encode social_preferences as JSON string
        if let data = try? JSONSerialization.data(withJSONObject: social_preferences),
           let jsonString = String(data: data, encoding: .utf8) {
            try container.encode(jsonString, forKey: .social_preferences)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user_id = try container.decode(UUID.self, forKey: .user_id)
        max_distance = try container.decode(Int.self, forKey: .max_distance)
        social_preferences = [:]
    }

    init(user_id: UUID, max_distance: Int, social_preferences: [String: Any]) {
        self.user_id = user_id
        self.max_distance = max_distance
        self.social_preferences = social_preferences
    }
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
