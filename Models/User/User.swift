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