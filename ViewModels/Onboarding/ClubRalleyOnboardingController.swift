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
    @Published var currentStep: ClubRalleyOnboardingStep = .phoneInput
    @Published var onboardingData = CompleteOnboardingData()
    @Published var isLoading = false
    @Published var error: ClubRalleyOnboardingError?
    @Published var isComplete = false
    @Published var isReturningUser = false

    // Validation states
    @Published var isUsernameAvailable: Bool?
    @Published var isCheckingUsername = false
    @Published var isPhoneVerified = false
    @Published var verificationCode = ""

    // OTP cooldown
    @Published var resendCooldown: Int = 0
    private var cooldownTimer: Timer?

    // Authenticated user ID (set after OTP verification)
    private var authenticatedUserId: UUID?

    // MARK: - Computed Properties
    var currentProgress: Double {
        currentStep.progressValue
    }

    var canGoBack: Bool {
        currentStep.canGoBack
    }

    var canContinue: Bool {
        switch currentStep {
        case .phoneInput:
            return onboardingData.profile.isPhoneComplete
        case .otpVerification:
            return verificationCode.count == 6
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
        case .completion:
            return true
        }
    }

    // MARK: - Dependencies
    private let userService = UserProfileService.shared
    private let supabaseManager = SupabaseManager.shared

    // MARK: - Navigation Methods

    func goToNextStep() {
        let allSteps = ClubRalleyOnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
              currentIndex < allSteps.count - 1 else {
            completeOnboarding()
            return
        }

        let nextStep = allSteps[currentIndex + 1]

        // If we're about to show the completion screen, submit data first
        if nextStep == .completion {
            completeOnboarding()
        }

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

    /// Full E.164 phone number for Supabase
    private var e164Phone: String {
        let digits = onboardingData.profile.phoneNumber.filter { $0.isNumber }
        return "\(onboardingData.profile.phoneCountryCode)\(digits)"
    }

    func sendVerificationCode() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        let phone = e164Phone
        print("📱 Sending OTP to: \(phone)")

        do {
            try await supabaseManager.sendOTP(phone: phone)
            startResendCooldown()
            return true
        } catch {
            // TODO: Remove mock fallback once Twilio is configured
            print("⚠️ OTP send failed, using mock mode: \(error)")
            startResendCooldown()
            return true
        }
    }

    func verifyPhoneCode(_ code: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let userId = try await supabaseManager.verifyOTP(phone: e164Phone, code: code)
            isPhoneVerified = true
            authenticatedUserId = userId

            // Check if returning user has an existing profile
            if let existingProfile = try? await supabaseManager.fetchUserProfile(userId: userId) {
                handleReturningUser(existingProfile, userId: userId)
                return true
            }

            return true
        } catch {
            // TODO: Remove mock fallback once Twilio is configured
            print("⚠️ OTP verify failed, using mock mode: \(error)")
            if code.count == 6 {
                isPhoneVerified = true
                authenticatedUserId = UUID()
                return true
            }
            self.error = .networkError("Please enter a 6-digit code.")
            return false
        }
    }

    /// Handle a returning user who already has a profile
    private func handleReturningUser(_ profile: SavedUserProfile, userId: UUID) {
        // Save profile locally
        MultiProfileManager.shared.addProfile(profile, setAsActive: true)

        if let profileData = try? JSONEncoder().with { $0.dateEncodingStrategy = .iso8601 }.encode(profile) {
            UserDefaults.standard.set(profileData, forKey: "currentUserProfile")
        }

        // Update SupabaseManager
        supabaseManager.currentUser = SupabaseUser(
            id: userId,
            email: profile.email,
            firstName: profile.firstName,
            lastName: profile.lastName
        )

        // Mark onboarding complete and jump straight to main app
        UserDefaults.standard.set(true, forKey: "hasCompletedClubRalleyOnboarding")
        isReturningUser = true
        isComplete = true
    }

    // MARK: - OTP Cooldown

    private func startResendCooldown() {
        resendCooldown = 60
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else { timer.invalidate(); return }
                if self.resendCooldown > 0 {
                    self.resendCooldown -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
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

        // User is already authenticated via OTP — use the authenticated user ID
        let userId = authenticatedUserId ?? supabaseManager.currentUser?.id ?? UUID()
        let phone = e164Phone

        // STEP 1: Create profile in club_users table
        do {
            try await supabaseManager.createClubUser(
                id: userId,
                email: onboardingData.profile.email,
                firstName: onboardingData.profile.firstName,
                lastName: onboardingData.profile.lastName,
                username: onboardingData.profile.username,
                city: onboardingData.profile.city,
                state: onboardingData.profile.state,
                profilePhotoURL: onboardingData.profile.profilePhotoURL
            )
        } catch {
            let errorMessage = error.localizedDescription.lowercased()
            if errorMessage.contains("already") || errorMessage.contains("duplicate") || errorMessage.contains("unique") {
                self.error = .usernameAlreadyTaken
                isLoading = false
                return
            }
            // Non-critical — continue with local-only mode
        }

        // STEP 2: Save local profile backup
        do {
            let userProfile = SavedUserProfile(
                id: userId,
                email: onboardingData.profile.email,
                firstName: onboardingData.profile.firstName,
                lastName: onboardingData.profile.lastName,
                username: onboardingData.profile.username,
                phoneNumber: phone,
                locationCity: onboardingData.profile.city,
                locationState: onboardingData.profile.state,
                profilePhotoURL: onboardingData.profile.profilePhotoURL,
                selectedSports: onboardingData.interests.selectedSports.map { $0.sport.name },
                createdAt: Date()
            )

            MultiProfileManager.shared.addProfile(userProfile, setAsActive: true)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let profileData = try encoder.encode(userProfile)
            UserDefaults.standard.set(profileData, forKey: "currentUserProfile")

            if let photoData = onboardingData.profile.profilePhotoData {
                UserDefaults.standard.set(photoData, forKey: "currentUserProfilePhoto")
            }

            supabaseManager.currentUser = SupabaseUser(
                id: userId,
                email: onboardingData.profile.email,
                firstName: onboardingData.profile.firstName,
                lastName: onboardingData.profile.lastName
            )

        } catch {
            print("Failed to save local profile: \(error)")
        }

        // STEP 3: Mark onboarding as complete
        UserDefaults.standard.set(true, forKey: "hasCompletedClubRalleyOnboarding")

        try? await Task.sleep(nanoseconds: 500_000_000)

        isComplete = true
        isLoading = false
    }

    // MARK: - Reset

    func resetOnboarding() {
        currentStep = .phoneInput
        onboardingData = CompleteOnboardingData()
        isComplete = false
        error = nil
        isUsernameAvailable = nil
        isPhoneVerified = false
        authenticatedUserId = nil
        verificationCode = ""
        resendCooldown = 0
        cooldownTimer?.invalidate()
        UserDefaults.standard.removeObject(forKey: "hasCompletedClubRalleyOnboarding")
        SavedUserProfile.clearStorage()
    }

    // MARK: - Validation Helpers

    func isValidPhoneNumber(_ phone: String) -> Bool {
        let digits = phone.filter { $0.isNumber }
        return digits.count >= 10 && digits.count <= 15
    }
}

// MARK: - JSONEncoder Helper

private extension JSONEncoder {
    func with(_ configure: (JSONEncoder) -> Void) -> JSONEncoder {
        configure(self)
        return self
    }
}
