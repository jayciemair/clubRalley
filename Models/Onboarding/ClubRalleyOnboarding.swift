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
    case welcome = "welcome"
    case signUp = "sign_up"
    case profileBasics = "profile_basics"
    case profileDetails = "profile_details"
    case athleteQuestion = "athlete_question"
    case athleteVerification = "athlete_verification"
    case sportsSelection = "sports_selection"
    case interests = "interests"
    case availability = "availability"
    case completion = "completion"
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to Club Ralley"
        case .signUp:
            return "Create Your Account"
        case .profileBasics:
            return "Tell Us About You"
        case .profileDetails:
            return "Complete Your Profile"
        case .athleteQuestion:
            return "Are You an Athlete?"
        case .athleteVerification:
            return "Verify Your Athlete Status"
        case .sportsSelection:
            return "Select Your Sports"
        case .interests:
            return "What Are You Into?"
        case .availability:
            return "When Are You Free?"
        case .completion:
            return "You're All Set!"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .welcome:
            return "GFTO - Get the F*** Outside"
        case .signUp:
            return "Join the community of athletes and active people"
        case .profileBasics:
            return "Help others find and connect with you"
        case .profileDetails:
            return "Add a few more details to your profile"
        case .athleteQuestion:
            return "Get verified for exclusive features"
        case .athleteVerification:
            return "Upload proof of your athletic involvement"
        case .sportsSelection:
            return "What sports do you play or want to try?"
        case .interests:
            return "Beyond sports, what do you enjoy?"
        case .availability:
            return "When are you usually free to rally?"
        case .completion:
            return "Welcome to the Club Ralley community!"
        }
    }
    
    var progressValue: Double {
        let index = Double(ClubRalleyOnboardingStep.allCases.firstIndex(of: self) ?? 0)
        return index / Double(ClubRalleyOnboardingStep.allCases.count - 1)
    }
    
    var canGoBack: Bool {
        switch self {
        case .welcome, .completion:
            return false
        default:
            return true
        }
    }
}

// MARK: - Onboarding Data Models

struct OnboardingProfileData {
    var firstName: String = ""
    var lastName: String = ""
    var username: String = ""
    var email: String = ""
    var dateOfBirth: DateOfBirth?
    var gender: Gender?
    var city: String = ""
    var state: String = ""
    var bio: String = ""
    var instagramHandle: String = ""
    
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

// MARK: - Complete Onboarding Data

struct CompleteOnboardingData {
    var profile: OnboardingProfileData = OnboardingProfileData()
    var athlete: OnboardingAthleteData = OnboardingAthleteData()
    var interests: OnboardingInterestsData = OnboardingInterestsData()
    var availability: OnboardingAvailabilityData = OnboardingAvailabilityData()
    
    var isComplete: Bool {
        profile.isBasicsComplete && 
        profile.isDetailsComplete && 
        athlete.isComplete && 
        interests.isComplete && 
        availability.isComplete
    }
    
    /// Convert to User model for API submission
    func toUserCreationRequest() -> UserCreationRequest {
        return UserCreationRequest(
            email: profile.email,
            firstName: profile.firstName,
            lastName: profile.lastName,
            username: profile.username,
            dateOfBirth: profile.dateOfBirth ?? DateOfBirth(month: 1, year: 2000),
            gender: profile.gender ?? .preferNotToSay,
            locationCity: profile.city,
            locationState: profile.state,
            bio: profile.bio.isEmpty ? nil : profile.bio,
            instagramHandle: profile.instagramHandle.isEmpty ? nil : profile.instagramHandle,
            isVerifiedAthlete: athlete.isAthlete,
            athleteInfo: athlete.isAthlete ? AthleteInfo(
                sport: athlete.sport!,
                school: athlete.school!,
                verificationStatus: .pending,
                verificationImageURL: athlete.verificationImageURL,
                submittedAt: Date(),
                verifiedAt: nil
            ) : nil,
            selectedSports: interests.selectedSports,
            hobbies: interests.hobbies,
            availabilitySlots: availability.availabilitySlots,
            maxDistance: availability.maxDistance,
            socialPreferences: availability.socialPreferences.map { $0.rawValue }
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
    }
}

// MARK: - Onboarding Error Types

enum OnboardingError: LocalizedError {
    case usernameAlreadyTaken
    case emailAlreadyExists
    case invalidEmail
    case weakPassword
    case verificationImageTooLarge
    case verificationImageInvalid
    case networkError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .usernameAlreadyTaken:
            return "This username is already taken. Please choose another."
        case .emailAlreadyExists:
            return "An account with this email already exists."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 8 characters with uppercase, lowercase, and numbers."
        case .verificationImageTooLarge:
            return "Image is too large. Please choose a smaller file."
        case .verificationImageInvalid:
            return "Please select a valid image file."
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknownError:
            return "An unexpected error occurred. Please try again."
        }
    }
}