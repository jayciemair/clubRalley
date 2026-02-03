//
//  PowerUpProfileData.swift
//  Club Ralley
//
//  Data models for Power Up Profile wizard flow
//

import Foundation

// MARK: - Power Up Steps

enum PowerUpStep: Int, CaseIterable {
    case rosterPhoto = 0
    case socialBio = 1
    case sportsSkill = 2
    case availability = 3
    case funQuestions = 4

    var title: String {
        switch self {
        case .rosterPhoto: return "Roster Photo"
        case .socialBio: return "Social & Bio"
        case .sportsSkill: return "Sports & Skill"
        case .availability: return "Availability"
        case .funQuestions: return "Fun Questions"
        }
    }

    var subtitle: String {
        switch self {
        case .rosterPhoto: return "Add a photo to help teammates recognize you"
        case .socialBio: return "Tell us about yourself"
        case .sportsSkill: return "What sports do you play?"
        case .availability: return "When are you free to play?"
        case .funQuestions: return "Let's get to know you better"
        }
    }

    var progressValue: Double {
        Double(rawValue + 1) / Double(PowerUpStep.allCases.count)
    }
}

// MARK: - Skill Level (Rookie/Competitor/All-Star)

enum PowerUpSkillLevel: String, CaseIterable, Codable {
    case rookie = "beginner"
    case competitor = "intermediate"
    case allStar = "advanced"

    var displayName: String {
        switch self {
        case .rookie: return "Rookie"
        case .competitor: return "Competitor"
        case .allStar: return "All-Star"
        }
    }

    var emoji: String {
        switch self {
        case .rookie: return "🌱"
        case .competitor: return "🏃"
        case .allStar: return "⭐"
        }
    }

    var description: String {
        switch self {
        case .rookie: return "Just starting out"
        case .competitor: return "Solid player"
        case .allStar: return "Top performer"
        }
    }

    /// Convert from existing SkillLevel enum
    init(from skillLevel: SkillLevel) {
        switch skillLevel {
        case .beginner: self = .rookie
        case .intermediate: self = .competitor
        case .advanced, .expert: self = .allStar
        }
    }

    /// Convert to existing SkillLevel enum for database compatibility
    var toSkillLevel: SkillLevel {
        switch self {
        case .rookie: return .beginner
        case .competitor: return .intermediate
        case .allStar: return .advanced
        }
    }
}

// MARK: - Sport with Skill Level

struct SportWithSkill: Identifiable, Equatable {
    let id: UUID
    let sport: Sport
    var skillLevel: PowerUpSkillLevel

    init(id: UUID = UUID(), sport: Sport, skillLevel: PowerUpSkillLevel = .competitor) {
        self.id = id
        self.sport = sport
        self.skillLevel = skillLevel
    }

    static func == (lhs: SportWithSkill, rhs: SportWithSkill) -> Bool {
        lhs.id == rhs.id && lhs.sport.id == rhs.sport.id && lhs.skillLevel == rhs.skillLevel
    }
}

// MARK: - Time Preference

enum TimePreference: String, CaseIterable, Codable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case anytime = "anytime"

    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .anytime: return "Anytime"
        }
    }

    var timeRange: String {
        switch self {
        case .morning: return "6 AM - 12 PM"
        case .afternoon: return "12 PM - 5 PM"
        case .evening: return "5 PM - 10 PM"
        case .anytime: return "All day"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        case .anytime: return "clock.fill"
        }
    }
}

// MARK: - Day Selection

enum DaySelection: String, CaseIterable {
    case weekdays = "weekdays"
    case weekends = "weekends"
    case specificDays = "specific"

    var displayName: String {
        switch self {
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .specificDays: return "Specific Days"
        }
    }

    var subtitle: String {
        switch self {
        case .weekdays: return "Mon - Fri"
        case .weekends: return "Sat - Sun"
        case .specificDays: return "Choose days"
        }
    }
}

// MARK: - Power Up Profile Data

struct PowerUpProfileData {
    // Step 1: Photo
    var profilePhotoData: Data?
    var profilePhotoURL: String?

    // Step 2: Social/Bio
    var instagramHandle: String = ""
    var bio: String = ""

    // Step 3: Sports & Skills
    var sportsWithSkills: [SportWithSkill] = []

    // Step 4: Availability
    var daySelection: DaySelection = .weekdays
    var selectedDays: Set<Int> = []  // 1 = Sunday, 2 = Monday, ..., 7 = Saturday
    var timePreference: TimePreference = .anytime
    var maxDistance: Int = 25

    // Step 5: Fun Questions
    var favoriteProTeam: String = ""
    var workoutBrands: [String] = []
    var workoutClasses: [String] = []
    var hometown: String = ""
    var wouldDoHappyHour: Bool? = nil

    // MARK: - Computed Properties

    var hasPhoto: Bool {
        profilePhotoData != nil || (profilePhotoURL != nil && !profilePhotoURL!.isEmpty)
    }

    var hasSocialInfo: Bool {
        !instagramHandle.isEmpty || !bio.isEmpty
    }

    var hasSports: Bool {
        !sportsWithSkills.isEmpty
    }

    var hasAvailability: Bool {
        !selectedDays.isEmpty || daySelection != .specificDays
    }

    var hasFunQuestions: Bool {
        !favoriteProTeam.isEmpty || !workoutBrands.isEmpty ||
        !workoutClasses.isEmpty || !hometown.isEmpty || wouldDoHappyHour != nil
    }

    /// Returns the days of week as integers (1-7 for Sun-Sat)
    var effectiveSelectedDays: Set<Int> {
        switch daySelection {
        case .weekdays:
            return Set([2, 3, 4, 5, 6]) // Mon-Fri
        case .weekends:
            return Set([1, 7]) // Sun, Sat
        case .specificDays:
            return selectedDays
        }
    }
}

// MARK: - Workout Brand Options

struct WorkoutBrandOptions {
    static let brands = [
        "Nike", "Adidas", "Lululemon", "Under Armour", "Reebok",
        "New Balance", "Gymshark", "Athleta", "Patagonia", "ALO",
        "Vuori", "Fabletics", "Outdoor Voices", "Ten Thousand"
    ]
}

// MARK: - Workout Class Options

struct WorkoutClassOptions {
    static let classes = [
        "CrossFit", "Pilates", "Yoga", "Spin", "Barre",
        "Boxing", "HIIT", "Zumba", "Kickboxing", "Bootcamp",
        "Orange Theory", "F45", "Barry's", "SoulCycle"
    ]
}

// MARK: - Day of Week Helper

struct DayOfWeek {
    static let days: [(id: Int, name: String, shortName: String)] = [
        (1, "Sunday", "S"),
        (2, "Monday", "M"),
        (3, "Tuesday", "T"),
        (4, "Wednesday", "W"),
        (5, "Thursday", "T"),
        (6, "Friday", "F"),
        (7, "Saturday", "S")
    ]
}
