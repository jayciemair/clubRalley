//
//  ClubRalleyOnboarding.swift
//  Club Ralley
//
//  Onboarding models and flow for Club Ralley social platform
//

import Foundation
import SwiftUI

// MARK: - Onboarding Flow Steps

enum ClubRalleyOnboardingStep: String, CaseIterable {
    case phoneInput = "phone_input"
    case otpVerification = "otp_verification"
    case name = "name"
    case username = "username"
    case profilePhoto = "profile_photo"
    case location = "location"
    case sports = "sports"
    case completion = "completion"

    var title: String {
        switch self {
        case .phoneInput:
            return "What's your phone number?"
        case .otpVerification:
            return "Enter verification code"
        case .name:
            return "What's your name?"
        case .username:
            return "Your username"
        case .profilePhoto:
            return "Add your profile photo"
        case .location:
            return "Where do you compete the most?"
        case .sports:
            return "What sports do you play?"
        case .completion:
            return "Congrats! You made the team!"
        }
    }

    var subtitle: String? {
        switch self {
        case .phoneInput:
            return "We'll send you a verification code"
        case .otpVerification:
            return nil
        case .name:
            return "This is how your teammates will see you!"
        case .username:
            return "How do you want to be known on Ralley?"
        case .profilePhoto:
            return "Show off your college headshots or your sports pics"
        case .location:
            return nil
        case .sports:
            return nil
        case .completion:
            return nil
        }
    }

    var progressValue: Double {
        let index = Double(ClubRalleyOnboardingStep.allCases.firstIndex(of: self) ?? 0)
        return index / Double(ClubRalleyOnboardingStep.allCases.count - 1)
    }

    var canGoBack: Bool {
        switch self {
        case .phoneInput, .completion:
            return false
        case .otpVerification:
            return true
        default:
            return true
        }
    }
}

// MARK: - Onboarding Data Models

struct OnboardingProfileData {
    var phoneNumber: String = ""
    var phoneCountryCode: String = "+1"
    var email: String = ""
    var username: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var profilePhotoData: Data?
    var profilePhotoURL: String?
    var city: String = ""
    var state: String = ""
    var gender: Gender?
    var birthday: Date?
    var contactsAccessGranted: Bool = false

    // Legacy fields for compatibility
    var firstName: String = ""
    var lastName: String = ""
    var dateOfBirth: DateOfBirth?
    var bio: String = ""
    var instagramHandle: String = ""

    var isPhoneComplete: Bool {
        phoneNumber.count >= 10
    }

    var isEmailComplete: Bool {
        !email.isEmpty && email.contains("@") && email.contains(".")
    }

    var isUsernameComplete: Bool {
        username.count >= 3 && username.count <= 20
    }

    var isPasswordComplete: Bool {
        password.count >= 8 && password == confirmPassword
    }

    var isLocationComplete: Bool {
        !city.isEmpty
    }

    var isGenderComplete: Bool {
        gender != nil
    }

    var isBirthdayComplete: Bool {
        birthday != nil
    }

    var isBasicsComplete: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !username.isEmpty && !email.isEmpty
    }

    var isDetailsComplete: Bool {
        dateOfBirth != nil && gender != nil && !city.isEmpty && !state.isEmpty
    }
}

struct OnboardingAthleteData {
    var isAthlete: Bool = false
    var sport: Sport?
    var school: School?
    var verificationImageURL: String?
    var verificationNotes: String = ""

    var isComplete: Bool {
        if !isAthlete { return true }
        return sport != nil && school != nil
    }
}

struct OnboardingInterestsData {
    var selectedSports: [UserSport] = []
    var hobbies: [String] = []
    var workoutBrands: [String] = []
    var classTypes: [String] = []
    var hometown: String = ""
    var favoriteTeams: [String] = []

    var isComplete: Bool {
        !selectedSports.isEmpty || !hobbies.isEmpty
    }
}

struct OnboardingAvailabilityData {
    var availabilitySlots: [AvailabilitySlot] = []
    var maxDistance: Int = 25  // miles
    var socialPreferences: [SocialPreference] = []

    var isComplete: Bool {
        !availabilitySlots.isEmpty
    }
}

enum SocialPreference: String, CaseIterable {
    case smallGroups = "small_groups"
    case largeGroups = "large_groups"
    case oneOnOne = "one_on_one"
    case competitive = "competitive"
    case casual = "casual"
    case beginner = "beginner_friendly"
    case advanced = "advanced_level"

    var displayName: String {
        switch self {
        case .smallGroups: return "Small Groups (2-5 people)"
        case .largeGroups: return "Large Groups (6+ people)"
        case .oneOnOne: return "One-on-One Activities"
        case .competitive: return "Competitive Environment"
        case .casual: return "Casual & Fun"
        case .beginner: return "Beginner Friendly"
        case .advanced: return "Advanced Level"
        }
    }

    var icon: String {
        switch self {
        case .smallGroups: return "person.2"
        case .largeGroups: return "person.3"
        case .oneOnOne: return "person"
        case .competitive: return "trophy"
        case .casual: return "hand.wave"
        case .beginner: return "graduationcap"
        case .advanced: return "star"
        }
    }
}

// MARK: - Available Cities

struct OnboardingCity: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let state: String
    let stateAbbreviation: String

    var displayName: String {
        "\(name), \(stateAbbreviation)"
    }

    static let availableCities: [OnboardingCity] = [
        OnboardingCity(name: "New York", state: "New York", stateAbbreviation: "NY"),
        OnboardingCity(name: "Los Angeles", state: "California", stateAbbreviation: "CA"),
        OnboardingCity(name: "Chicago", state: "Illinois", stateAbbreviation: "IL"),
        OnboardingCity(name: "Houston", state: "Texas", stateAbbreviation: "TX"),
        OnboardingCity(name: "Phoenix", state: "Arizona", stateAbbreviation: "AZ"),
        OnboardingCity(name: "Philadelphia", state: "Pennsylvania", stateAbbreviation: "PA"),
        OnboardingCity(name: "San Antonio", state: "Texas", stateAbbreviation: "TX"),
        OnboardingCity(name: "San Diego", state: "California", stateAbbreviation: "CA"),
        OnboardingCity(name: "Dallas", state: "Texas", stateAbbreviation: "TX"),
        OnboardingCity(name: "Austin", state: "Texas", stateAbbreviation: "TX"),
        OnboardingCity(name: "San Francisco", state: "California", stateAbbreviation: "CA"),
        OnboardingCity(name: "Seattle", state: "Washington", stateAbbreviation: "WA"),
        OnboardingCity(name: "Denver", state: "Colorado", stateAbbreviation: "CO"),
        OnboardingCity(name: "Boston", state: "Massachusetts", stateAbbreviation: "MA"),
        OnboardingCity(name: "Nashville", state: "Tennessee", stateAbbreviation: "TN"),
        OnboardingCity(name: "Atlanta", state: "Georgia", stateAbbreviation: "GA"),
        OnboardingCity(name: "Miami", state: "Florida", stateAbbreviation: "FL"),
        OnboardingCity(name: "Portland", state: "Oregon", stateAbbreviation: "OR"),
        OnboardingCity(name: "Minneapolis", state: "Minnesota", stateAbbreviation: "MN"),
        OnboardingCity(name: "Charlotte", state: "North Carolina", stateAbbreviation: "NC")
    ]
}

// MARK: - Complete Onboarding Data

struct CompleteOnboardingData {
    var profile: OnboardingProfileData = OnboardingProfileData()
    var athlete: OnboardingAthleteData = OnboardingAthleteData()
    var interests: OnboardingInterestsData = OnboardingInterestsData()
    var availability: OnboardingAvailabilityData = OnboardingAvailabilityData()

    var isComplete: Bool {
        profile.isPhoneComplete &&
        profile.isUsernameComplete &&
        profile.isLocationComplete
    }

    /// Convert to User model for API submission
    func toUserCreationRequest() -> UserCreationRequest {
        // Convert birthday to DateOfBirth
        var dob = DateOfBirth(month: 1, year: 2000)
        if let birthday = profile.birthday {
            let calendar = Calendar.current
            dob = DateOfBirth(
                month: calendar.component(.month, from: birthday),
                year: calendar.component(.year, from: birthday)
            )
        }

        return UserCreationRequest(
            email: profile.email,
            firstName: profile.firstName,
            lastName: profile.lastName,
            username: profile.username,
            dateOfBirth: dob,
            gender: profile.gender ?? .preferNotToSay,
            locationCity: profile.city,
            locationState: profile.state,
            bio: profile.bio.isEmpty ? nil : profile.bio,
            instagramHandle: profile.instagramHandle.isEmpty ? nil : profile.instagramHandle,
            isVerifiedAthlete: athlete.isAthlete,
            athleteInfo: {
                guard athlete.isAthlete, let sport = athlete.sport, let school = athlete.school else { return nil }
                return AthleteInfo(
                    sport: sport,
                    school: school,
                    verificationStatus: .pending,
                    verificationImageURL: athlete.verificationImageURL,
                    submittedAt: Date(),
                    verifiedAt: nil
                )
            }(),
            selectedSports: interests.selectedSports,
            hobbies: interests.hobbies,
            availabilitySlots: availability.availabilitySlots,
            maxDistance: availability.maxDistance,
            socialPreferences: availability.socialPreferences.map { $0.rawValue },
            phoneNumber: profile.phoneCountryCode + profile.phoneNumber,
            profilePhotoURL: profile.profilePhotoURL,
            contactsAccessGranted: profile.contactsAccessGranted
        )
    }
}

struct UserCreationRequest: Codable {
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
    let isVerifiedAthlete: Bool
    let athleteInfo: AthleteInfo?
    let selectedSports: [UserSport]
    let hobbies: [String]
    let availabilitySlots: [AvailabilitySlot]
    let maxDistance: Int
    let socialPreferences: [String]
    let phoneNumber: String?
    let profilePhotoURL: String?
    let contactsAccessGranted: Bool?

    enum CodingKeys: String, CodingKey {
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
        case isVerifiedAthlete = "is_verified_athlete"
        case athleteInfo = "athlete_info"
        case selectedSports = "selected_sports"
        case hobbies
        case availabilitySlots = "availability_slots"
        case maxDistance = "max_distance"
        case socialPreferences = "social_preferences"
        case phoneNumber = "phone_number"
        case profilePhotoURL = "profile_photo_url"
        case contactsAccessGranted = "contacts_access_granted"
    }

    init(
        email: String,
        firstName: String,
        lastName: String,
        username: String,
        dateOfBirth: DateOfBirth,
        gender: Gender,
        locationCity: String,
        locationState: String,
        bio: String?,
        instagramHandle: String?,
        isVerifiedAthlete: Bool,
        athleteInfo: AthleteInfo?,
        selectedSports: [UserSport],
        hobbies: [String],
        availabilitySlots: [AvailabilitySlot],
        maxDistance: Int,
        socialPreferences: [String],
        phoneNumber: String? = nil,
        profilePhotoURL: String? = nil,
        contactsAccessGranted: Bool? = nil
    ) {
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
        self.isVerifiedAthlete = isVerifiedAthlete
        self.athleteInfo = athleteInfo
        self.selectedSports = selectedSports
        self.hobbies = hobbies
        self.availabilitySlots = availabilitySlots
        self.maxDistance = maxDistance
        self.socialPreferences = socialPreferences
        self.phoneNumber = phoneNumber
        self.profilePhotoURL = profilePhotoURL
        self.contactsAccessGranted = contactsAccessGranted
    }
}

// MARK: - Onboarding Error Types

enum ClubRalleyOnboardingError: LocalizedError {
    case usernameAlreadyTaken
    case emailAlreadyExists
    case phoneAlreadyExists
    case invalidEmail
    case invalidPhone
    case weakPassword
    case passwordMismatch
    case verificationImageTooLarge
    case verificationImageInvalid
    case contactsAccessDenied
    case networkError(String)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .usernameAlreadyTaken:
            return "This username is already taken. Please choose another."
        case .emailAlreadyExists:
            return "An account with this email already exists."
        case .phoneAlreadyExists:
            return "An account with this phone number already exists."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .invalidPhone:
            return "Please enter a valid phone number."
        case .weakPassword:
            return "Password must be at least 8 characters with uppercase, lowercase, and numbers."
        case .passwordMismatch:
            return "Passwords do not match."
        case .verificationImageTooLarge:
            return "Image is too large. Please choose a smaller file."
        case .verificationImageInvalid:
            return "Please select a valid image file."
        case .contactsAccessDenied:
            return "Contacts access was denied. You can enable it later in Settings."
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknownError:
            return "An unexpected error occurred. Please try again."
        }
    }
}

// MARK: - Saved College Athlete Info (for persistence)

struct SavedCollegeAthleteInfo: Codable {
    let sport: String
    let school: String
    let division: String  // Stored as string for Codable simplicity
    let yearsPlayed: String?
    let position: String?
}

// MARK: - Saved User Profile (for persistence)

struct SavedUserProfile: Codable {
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

    // New profile fields
    var isPrivateAccount: Bool?
    var playedCollegeSport: Bool?
    var collegeAthleteInfo: SavedCollegeAthleteInfo?

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    var displayLocation: String {
        if locationCity.isEmpty { return "" }
        return "\(locationCity), \(locationState)"
    }

    enum CodingKeys: String, CodingKey {
        case id, email, firstName, lastName, username, phoneNumber
        case locationCity, locationState, profilePhotoURL, selectedSports, createdAt
        case bio, instagramHandle
        case isPrivateAccount, playedCollegeSport, collegeAthleteInfo
    }

    init(id: UUID, email: String, firstName: String, lastName: String, username: String, phoneNumber: String, locationCity: String, locationState: String, profilePhotoURL: String?, selectedSports: [String], createdAt: Date, bio: String? = nil, instagramHandle: String? = nil, isPrivateAccount: Bool? = nil, playedCollegeSport: Bool? = nil, collegeAthleteInfo: SavedCollegeAthleteInfo? = nil) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.phoneNumber = phoneNumber
        self.locationCity = locationCity
        self.locationState = locationState
        self.profilePhotoURL = profilePhotoURL
        self.selectedSports = selectedSports
        self.createdAt = createdAt
        self.bio = bio
        self.instagramHandle = instagramHandle
        self.isPrivateAccount = isPrivateAccount
        self.playedCollegeSport = playedCollegeSport
        self.collegeAthleteInfo = collegeAthleteInfo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        username = try container.decode(String.self, forKey: .username)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber) ?? ""
        locationCity = try container.decode(String.self, forKey: .locationCity)
        locationState = try container.decode(String.self, forKey: .locationState)
        profilePhotoURL = try container.decodeIfPresent(String.self, forKey: .profilePhotoURL)
        selectedSports = try container.decodeIfPresent([String].self, forKey: .selectedSports) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        instagramHandle = try container.decodeIfPresent(String.self, forKey: .instagramHandle)
        isPrivateAccount = try container.decodeIfPresent(Bool.self, forKey: .isPrivateAccount)
        playedCollegeSport = try container.decodeIfPresent(Bool.self, forKey: .playedCollegeSport)
        collegeAthleteInfo = try container.decodeIfPresent(SavedCollegeAthleteInfo.self, forKey: .collegeAthleteInfo)
    }

    /// Load saved profile from UserDefaults
    static func loadFromStorage() -> SavedUserProfile? {
        guard let data = UserDefaults.standard.data(forKey: "currentUserProfile") else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(SavedUserProfile.self, from: data)
    }

    /// Load profile photo data from UserDefaults
    static func loadProfilePhotoData() -> Data? {
        return UserDefaults.standard.data(forKey: "currentUserProfilePhoto")
    }

    /// Clear saved profile (for logout/reset)
    static func clearStorage() {
        UserDefaults.standard.removeObject(forKey: "currentUserProfile")
        UserDefaults.standard.removeObject(forKey: "currentUserProfilePhoto")
    }
}
