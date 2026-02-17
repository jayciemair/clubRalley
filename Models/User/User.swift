//
//  User.swift
//  Club Ralley
//
//  Core user model for Club Ralley social platform
//

import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
    let username: String
    let dateOfBirth: DateOfBirth
    let gender: Gender
    let locationCity: String
    let locationState: String
    let bio: String?
    let instagramHandle: String?
    let profilePhotoURL: String?
    let isVerifiedAthlete: Bool
    let athleteInfo: AthleteInfo?
    let friendsCount: Int
    let ralleysCount: Int
    let createdAt: Date
    let updatedAt: Date

    // New fields for enhanced profile
    let isPrivateAccount: Bool
    let sportsWithSkills: [UserSportSkill]
    let playedCollegeSport: Bool
    let collegeAthleteInfo: CollegeAthleteInfo?

    // Computed properties
    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var displayLocation: String {
        "\(locationCity), \(locationState)"
    }

    var age: Int? {
        dateOfBirth.age
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case username
        case dateOfBirth = "date_of_birth"
        case gender
        case locationCity = "location_city"
        case locationState = "location_state"
        case bio
        case instagramHandle = "instagram_handle"
        case profilePhotoURL = "profile_photo_url"
        case isVerifiedAthlete = "is_verified_athlete"
        case athleteInfo = "athlete_info"
        case friendsCount = "friends_count"
        case ralleysCount = "ralleys_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isPrivateAccount = "is_private_account"
        case sportsWithSkills = "sports_with_skills"
        case playedCollegeSport = "played_college_sport"
        case collegeAthleteInfo = "college_athlete_info"
    }

    // Custom decoder to handle missing optional fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        username = try container.decode(String.self, forKey: .username)
        dateOfBirth = try container.decodeIfPresent(DateOfBirth.self, forKey: .dateOfBirth) ?? DateOfBirth(month: 1, year: 2000)
        gender = try container.decodeIfPresent(Gender.self, forKey: .gender) ?? .preferNotToSay
        locationCity = try container.decodeIfPresent(String.self, forKey: .locationCity) ?? ""
        locationState = try container.decodeIfPresent(String.self, forKey: .locationState) ?? ""
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        instagramHandle = try container.decodeIfPresent(String.self, forKey: .instagramHandle)
        profilePhotoURL = try container.decodeIfPresent(String.self, forKey: .profilePhotoURL)
        isVerifiedAthlete = try container.decodeIfPresent(Bool.self, forKey: .isVerifiedAthlete) ?? false
        athleteInfo = try container.decodeIfPresent(AthleteInfo.self, forKey: .athleteInfo)
        friendsCount = try container.decodeIfPresent(Int.self, forKey: .friendsCount) ?? 0
        ralleysCount = try container.decodeIfPresent(Int.self, forKey: .ralleysCount) ?? 0
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        isPrivateAccount = try container.decodeIfPresent(Bool.self, forKey: .isPrivateAccount) ?? false
        sportsWithSkills = try container.decodeIfPresent([UserSportSkill].self, forKey: .sportsWithSkills) ?? []
        playedCollegeSport = try container.decodeIfPresent(Bool.self, forKey: .playedCollegeSport) ?? false
        collegeAthleteInfo = try container.decodeIfPresent(CollegeAthleteInfo.self, forKey: .collegeAthleteInfo)
    }

    // Manual init for creating users
    init(
        id: UUID,
        email: String,
        firstName: String,
        lastName: String,
        username: String,
        dateOfBirth: DateOfBirth = DateOfBirth(month: 1, year: 2000),
        gender: Gender = .preferNotToSay,
        locationCity: String = "",
        locationState: String = "",
        bio: String? = nil,
        instagramHandle: String? = nil,
        profilePhotoURL: String? = nil,
        isVerifiedAthlete: Bool = false,
        athleteInfo: AthleteInfo? = nil,
        friendsCount: Int = 0,
        ralleysCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPrivateAccount: Bool = false,
        sportsWithSkills: [UserSportSkill] = [],
        playedCollegeSport: Bool = false,
        collegeAthleteInfo: CollegeAthleteInfo? = nil
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.locationCity = locationCity
        self.locationState = locationState
        self.bio = bio
        self.instagramHandle = instagramHandle
        self.profilePhotoURL = profilePhotoURL
        self.isVerifiedAthlete = isVerifiedAthlete
        self.athleteInfo = athleteInfo
        self.friendsCount = friendsCount
        self.ralleysCount = ralleysCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPrivateAccount = isPrivateAccount
        self.sportsWithSkills = sportsWithSkills
        self.playedCollegeSport = playedCollegeSport
        self.collegeAthleteInfo = collegeAthleteInfo
    }
}

// MARK: - Sport with Skill Level

struct UserSportSkill: Codable, Identifiable {
    let id: UUID
    let sportName: String
    let skillLevel: SkillLevelType
    let iconName: String

    enum CodingKeys: String, CodingKey {
        case id
        case sportName = "sport_name"
        case skillLevel = "skill_level"
        case iconName = "icon_name"
    }

    init(id: UUID = UUID(), sportName: String, skillLevel: SkillLevelType, iconName: String = "sportscourt.fill") {
        self.id = id
        self.sportName = sportName
        self.skillLevel = skillLevel
        self.iconName = iconName
    }
}

enum SkillLevelType: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }

    var emoji: String {
        switch self {
        case .beginner: return "🌱"
        case .intermediate: return "🏃"
        case .advanced: return "⭐"
        case .expert: return "🏆"
        }
    }

    var color: String {
        switch self {
        case .beginner: return "#4CAF50"  // Green
        case .intermediate: return "#2196F3"  // Blue
        case .advanced: return "#FF9800"  // Orange
        case .expert: return "#9C27B0"  // Purple
        }
    }
}

// MARK: - College Athlete Info

struct CollegeAthleteInfo: Codable {
    let sport: String
    let school: String
    let division: CollegeDivision
    let yearsPlayed: String?  // e.g., "2019-2023"
    let position: String?
    let achievements: [String]

    enum CodingKeys: String, CodingKey {
        case sport
        case school
        case division
        case yearsPlayed = "years_played"
        case position
        case achievements
    }

    init(sport: String, school: String, division: CollegeDivision, yearsPlayed: String? = nil, position: String? = nil, achievements: [String] = []) {
        self.sport = sport
        self.school = school
        self.division = division
        self.yearsPlayed = yearsPlayed
        self.position = position
        self.achievements = achievements
    }
}

enum CollegeDivision: String, Codable, CaseIterable {
    case d1 = "D1"
    case d2 = "D2"
    case d3 = "D3"
    case naia = "NAIA"
    case juco = "JUCO"
    case club = "Club"

    var displayName: String {
        switch self {
        case .d1: return "Division I"
        case .d2: return "Division II"
        case .d3: return "Division III"
        case .naia: return "NAIA"
        case .juco: return "Junior College"
        case .club: return "Club"
        }
    }

    var shortName: String {
        rawValue
    }
}

struct DateOfBirth: Codable {
    let month: Int
    let year: Int
    
    var age: Int? {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())
        
        var calculatedAge = currentYear - year
        if month > currentMonth {
            calculatedAge -= 1
        }
        
        return calculatedAge > 0 ? calculatedAge : nil
    }
}

enum Gender: String, Codable, CaseIterable {
    case male = "male"
    case female = "female"
    case nonBinary = "non_binary"
    case preferNotToSay = "prefer_not_to_say"
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .nonBinary: return "Non-binary"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

struct AthleteInfo: Codable {
    let sport: Sport
    let school: School
    let verificationStatus: VerificationStatus
    let verificationImageURL: String?
    let submittedAt: Date?
    let verifiedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case sport
        case school
        case verificationStatus = "verification_status"
        case verificationImageURL = "verification_image_url"
        case submittedAt = "submitted_at"
        case verifiedAt = "verified_at"
    }
}

enum VerificationStatus: String, Codable {
    case pending = "pending"
    case verified = "verified"
    case rejected = "rejected"
    case notSubmitted = "not_submitted"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending Verification"
        case .verified: return "Verified"
        case .rejected: return "Verification Rejected"
        case .notSubmitted: return "Not Submitted"
        }
    }
    
    var badgeColor: String {
        switch self {
        case .pending: return "orange"
        case .verified: return "green"
        case .rejected: return "red"
        case .notSubmitted: return "gray"
        }
    }
}