//
//  ClubRalleyOnboardingController.swift
//  Club Ralley
//
//  Flow controller for Club Ralley onboarding experience
//

import Foundation
import SwiftUI
import Combine
import Contacts

@MainActor
class ClubRalleyOnboardingController: ObservableObject {

    // MARK: - Published Properties
    @Published var currentStep: ClubRalleyOnboardingStep = .welcome
    @Published var onboardingData = CompleteOnboardingData()
    @Published var isLoading = false
    @Published var error: ClubRalleyOnboardingError?
    @Published var isComplete = false

    // Validation states
    @Published var isUsernameAvailable: Bool?
    @Published var isCheckingUsername = false
    @Published var isPhoneVerified = false
    @Published var verificationCode = ""

    // MARK: - Computed Properties
    var currentProgress: Double {
        currentStep.progressValue
    }

    var canGoBack: Bool {
        currentStep.canGoBack
    }

    var canContinue: Bool {
        switch currentStep {
        case .welcome, .completion:
            return true
        case .email:
            return onboardingData.profile.isEmailComplete
        case .password:
            return onboardingData.profile.isPasswordComplete
        case .name:
            return !onboardingData.profile.firstName.isEmpty && !onboardingData.profile.lastName.isEmpty
        case .username:
            return onboardingData.profile.isUsernameComplete && isUsernameAvailable == true
        case .profilePhoto:
            return true // Photo is optional
        case .location:
            return onboardingData.profile.isLocationComplete
        case .sports:
            return !onboardingData.interests.selectedSports.isEmpty
        }
    }

    // MARK: - Dependencies
    // Note: Main app uses OAuth (Apple/Google) for auth, onboarding collects profile data
    private let userService = UserProfileService.shared
    private let supabaseManager = SupabaseManager.shared

    // MARK: - Navigation Methods

    func goToNextStep() {
        // Note: Screens handle their own validation via continueEnabled
        // This method just advances to the next step
        let allSteps = ClubRalleyOnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
              currentIndex < allSteps.count - 1 else {
            completeOnboarding()
            return
        }

        let nextStep = allSteps[currentIndex + 1]
        currentStep = nextStep
    }

    func goToPreviousStep() {
        guard canGoBack else { return }

        let allSteps = ClubRalleyOnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
              currentIndex > 0 else { return }

        let previousStep = allSteps[currentIndex - 1]
        currentStep = previousStep
    }

    func skipToStep(_ step: ClubRalleyOnboardingStep) {
        currentStep = step
    }

    // MARK: - Phone Number Methods

    func updatePhoneNumber(_ phone: String, countryCode: String = "+1") {
        onboardingData.profile.phoneNumber = phone.filter { $0.isNumber }
        onboardingData.profile.phoneCountryCode = countryCode
    }

    func sendVerificationCode() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        // Mock implementation - in real app, send SMS
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        return true
    }

    func verifyPhoneCode(_ code: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        // Mock implementation - in real app, verify code
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        // Accept any 6-digit code for demo
        if code.count == 6 {
            isPhoneVerified = true
            return true
        }
        return false
    }

    // MARK: - Email Methods

    func updateEmail(_ email: String) {
        onboardingData.profile.email = email.trimmingCharacters(in: .whitespaces).lowercased()
    }

    // MARK: - Username Methods

    func updateUsername(_ username: String) {
        let cleanUsername = username.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
        onboardingData.profile.username = cleanUsername
        isUsernameAvailable = nil
    }

    func checkUsernameAvailability() async {
        let username = onboardingData.profile.username
        guard username.count >= 3 else {
            isUsernameAvailable = nil
            return
        }

        isCheckingUsername = true
        isUsernameAvailable = await validateUsername(username)
        isCheckingUsername = false
    }

    // MARK: - Password Methods

    func updatePassword(_ password: String, confirm: String) {
        onboardingData.profile.password = password
        onboardingData.profile.confirmPassword = confirm
    }

    var passwordStrength: PasswordStrength {
        let password = onboardingData.profile.password
        if password.isEmpty { return .none }
        if password.count < 8 { return .weak }

        var score = 0
        if password.contains(where: { $0.isUppercase }) { score += 1 }
        if password.contains(where: { $0.isLowercase }) { score += 1 }
        if password.contains(where: { $0.isNumber }) { score += 1 }
        if password.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) }) { score += 1 }

        switch score {
        case 0...1: return .weak
        case 2: return .medium
        default: return .strong
        }
    }

    // MARK: - Profile Photo Methods

    func updateProfilePhoto(_ imageData: Data) async throws -> String {
        isLoading = true
        defer { isLoading = false }

        onboardingData.profile.profilePhotoData = imageData

        // Mock upload - in real app, upload to cloud storage
        try await Task.sleep(nanoseconds: 2_000_000_000)
        let url = "https://example.com/photos/\(UUID().uuidString).jpg"
        onboardingData.profile.profilePhotoURL = url
        return url
    }

    func skipProfilePhoto() {
        onboardingData.profile.profilePhotoData = nil
        onboardingData.profile.profilePhotoURL = nil
    }

    // MARK: - Location Methods

    func updateLocation(city: OnboardingCity) {
        onboardingData.profile.city = city.name
        onboardingData.profile.state = city.stateAbbreviation
    }

    func updateLocation(city: String, state: String) {
        onboardingData.profile.city = city
        onboardingData.profile.state = state
    }

    // MARK: - Gender Methods

    func updateGender(_ gender: Gender) {
        onboardingData.profile.gender = gender
    }

    // MARK: - Birthday Methods

    func updateBirthday(_ date: Date) {
        onboardingData.profile.birthday = date

        // Also update legacy dateOfBirth
        let calendar = Calendar.current
        onboardingData.profile.dateOfBirth = DateOfBirth(
            month: calendar.component(.month, from: date),
            year: calendar.component(.year, from: date)
        )
    }

    var age: Int? {
        guard let birthday = onboardingData.profile.birthday else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: now)
        return ageComponents.year
    }

    var isValidAge: Bool {
        guard let age = age else { return false }
        return age >= 13 && age <= 120
    }

    // MARK: - Contacts Access Methods

    func requestContactsAccess() async -> Bool {
        let store = CNContactStore()

        do {
            let granted = try await store.requestAccess(for: .contacts)
            onboardingData.profile.contactsAccessGranted = granted
            return granted
        } catch {
            onboardingData.profile.contactsAccessGranted = false
            return false
        }
    }

    func skipContactsAccess() {
        onboardingData.profile.contactsAccessGranted = false
    }

    // MARK: - Legacy Data Update Methods (for compatibility)

    func updateProfileBasics(firstName: String, lastName: String, username: String, email: String) {
        onboardingData.profile.firstName = firstName
        onboardingData.profile.lastName = lastName
        onboardingData.profile.username = username
        onboardingData.profile.email = email
    }

    func updateProfileDetails(dateOfBirth: DateOfBirth, gender: Gender, city: String, state: String, bio: String, instagram: String) {
        onboardingData.profile.dateOfBirth = dateOfBirth
        onboardingData.profile.gender = gender
        onboardingData.profile.city = city
        onboardingData.profile.state = state
        onboardingData.profile.bio = bio
        onboardingData.profile.instagramHandle = instagram
    }

    func updateAthleteStatus(isAthlete: Bool) {
        onboardingData.athlete.isAthlete = isAthlete
        if !isAthlete {
            onboardingData.athlete.sport = nil
            onboardingData.athlete.school = nil
            onboardingData.athlete.verificationImageURL = nil
            onboardingData.athlete.verificationNotes = ""
        }
    }

    func updateAthleteVerification(sport: Sport, school: School, verificationImageURL: String?, notes: String) {
        onboardingData.athlete.sport = sport
        onboardingData.athlete.school = school
        onboardingData.athlete.verificationImageURL = verificationImageURL
        onboardingData.athlete.verificationNotes = notes
    }

    func updateSportsSelection(_ sports: [UserSport]) {
        onboardingData.interests.selectedSports = sports
    }

    func updateInterests(hobbies: [String], workoutBrands: [String], classTypes: [String], hometown: String, favoriteTeams: [String]) {
        onboardingData.interests.hobbies = hobbies
        onboardingData.interests.workoutBrands = workoutBrands
        onboardingData.interests.classTypes = classTypes
        onboardingData.interests.hometown = hometown
        onboardingData.interests.favoriteTeams = favoriteTeams
    }

    func updateAvailability(slots: [AvailabilitySlot], maxDistance: Int, socialPreferences: [SocialPreference]) {
        onboardingData.availability.availabilitySlots = slots
        onboardingData.availability.maxDistance = maxDistance
        onboardingData.availability.socialPreferences = socialPreferences
    }

    // MARK: - Username Validation

    func validateUsername(_ username: String) async -> Bool {
        guard !username.isEmpty,
              username.count >= 3,
              username.count <= 20,
              username.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else {
            return false
        }

        // Check if username is available (mock implementation)
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Mock some taken usernames for demo
        let takenUsernames = ["admin", "clubralley", "test", "user", "athlete"]
        return !takenUsernames.contains(username.lowercased())
    }

    // MARK: - Image Upload

    func uploadVerificationImage(_ imageData: Data) async throws -> String {
        isLoading = true
        defer { isLoading = false }

        try await Task.sleep(nanoseconds: 2_000_000_000)
        return "https://example.com/uploads/verification_\(UUID().uuidString).jpg"
    }

    // MARK: - Completion

    private func completeOnboarding() {
        Task {
            await submitOnboardingData()
        }
    }

    private func submitOnboardingData() async {
        isLoading = true
        error = nil

        // Generate a local user ID (will be replaced by Supabase ID if signup succeeds)
        var userId = UUID()

        // STEP 1: Try to create Supabase Auth account
        do {
            userId = try await supabaseManager.signUp(
                email: onboardingData.profile.email,
                password: onboardingData.profile.password
            )
            print("ClubRalleyOnboardingController: Supabase signup successful")

            // STEP 2: Create profile in club_users table
            try await supabaseManager.createClubUser(
                id: userId,
                email: onboardingData.profile.email,
                firstName: onboardingData.profile.firstName,
                lastName: onboardingData.profile.lastName,
                username: onboardingData.profile.username,
                phoneNumber: "",
                locationCity: onboardingData.profile.city,
                locationState: onboardingData.profile.state,
                profilePhotoURL: onboardingData.profile.profilePhotoURL
            )
            print("ClubRalleyOnboardingController: Profile created in database")

        } catch {
            // Check if this is a critical auth error that should stop onboarding
            let errorMessage = error.localizedDescription.lowercased()
            if errorMessage.contains("already registered") || errorMessage.contains("already exists") {
                self.error = .emailAlreadyExists
                isLoading = false
                return
            } else if errorMessage.contains("weak password") || errorMessage.contains("invalid password") {
                self.error = .weakPassword
                isLoading = false
                return
            }

            // For other errors (network, not configured), continue with local-only mode
            print("ClubRalleyOnboardingController: Supabase error, using local mode: \(error.localizedDescription)")
        }

        // STEP 3: Save local profile backup (always do this)
        do {
            let userProfile = SavedUserProfile(
                id: userId,
                email: onboardingData.profile.email,
                firstName: onboardingData.profile.firstName,
                lastName: onboardingData.profile.lastName,
                username: onboardingData.profile.username,
                phoneNumber: "",
                locationCity: onboardingData.profile.city,
                locationState: onboardingData.profile.state,
                profilePhotoURL: onboardingData.profile.profilePhotoURL,
                selectedSports: onboardingData.interests.selectedSports.map { $0.sport.name },
                createdAt: Date()
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let profileData = try encoder.encode(userProfile)
            UserDefaults.standard.set(profileData, forKey: "currentUserProfile")

            // Also save profile photo data if available
            if let photoData = onboardingData.profile.profilePhotoData {
                UserDefaults.standard.set(photoData, forKey: "currentUserProfilePhoto")
            }

            // Update SupabaseManager with user info
            supabaseManager.isAuthenticated = true
            supabaseManager.currentUser = SupabaseUser(
                id: userId,
                email: onboardingData.profile.email,
                firstName: onboardingData.profile.firstName,
                lastName: onboardingData.profile.lastName
            )

        } catch {
            print("ClubRalleyOnboardingController: Failed to save local profile: \(error)")
        }

        // STEP 4: Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "hasCompletedClubRalleyOnboarding")

        // Brief delay for UX
        try? await Task.sleep(nanoseconds: 500_000_000)

        isComplete = true
        isLoading = false
    }

    // MARK: - Reset

    func resetOnboarding() {
        currentStep = .welcome
        onboardingData = CompleteOnboardingData()
        isComplete = false
        error = nil
        isUsernameAvailable = nil
        isPhoneVerified = false
        UserDefaults.standard.removeObject(forKey: "hasCompletedClubRalleyOnboarding")
        SavedUserProfile.clearStorage()
    }

    // MARK: - Validation Helpers

    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8 &&
               password.contains(where: { $0.isUppercase }) &&
               password.contains(where: { $0.isLowercase }) &&
               password.contains(where: { $0.isNumber })
    }

    func isValidPhoneNumber(_ phone: String) -> Bool {
        let digits = phone.filter { $0.isNumber }
        return digits.count >= 10 && digits.count <= 15
    }
}

// MARK: - Password Strength

enum PasswordStrength {
    case none
    case weak
    case medium
    case strong

    var color: Color {
        switch self {
        case .none: return .gray
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }

    var label: String {
        switch self {
        case .none: return ""
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        }
    }
}
