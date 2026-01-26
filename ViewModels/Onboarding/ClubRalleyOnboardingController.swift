//
//  ClubRalleyOnboardingController.swift
//  Club Ralley
//
//  Flow controller for Club Ralley onboarding experience
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ClubRalleyOnboardingController: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentStep: ClubRalleyOnboardingStep = .welcome
    @Published var onboardingData = CompleteOnboardingData()
    @Published var isLoading = false
    @Published var error: OnboardingError?
    @Published var isComplete = false
    
    // MARK: - Computed Properties
    var currentProgress: Double {
        currentStep.progressValue
    }
    
    var canGoBack: Bool {
        currentStep.canGoBack
    }
    
    var canContinue: Bool {
        switch currentStep {
        case .welcome, .signUp, .completion:
            return true
        case .profileBasics:
            return onboardingData.profile.isBasicsComplete
        case .profileDetails:
            return onboardingData.profile.isDetailsComplete
        case .athleteQuestion:
            return true  // Always can continue after selecting yes/no
        case .athleteVerification:
            return onboardingData.athlete.isComplete
        case .sportsSelection:
            return !onboardingData.interests.selectedSports.isEmpty
        case .interests:
            return onboardingData.interests.isComplete
        case .availability:
            return onboardingData.availability.isComplete
        }
    }
    
    // MARK: - Dependencies
    private let authService = AuthenticationService.shared
    private let userService = UserProfileService.shared
    
    // MARK: - Navigation Methods
    
    func goToNextStep() {
        guard canContinue else { return }
        
        let allSteps = ClubRalleyOnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
              currentIndex < allSteps.count - 1 else {
            completeOnboarding()
            return
        }
        
        let nextStep = allSteps[currentIndex + 1]
        
        // Skip athlete verification if user is not an athlete
        if nextStep == .athleteVerification && !onboardingData.athlete.isAthlete {
            currentStep = .sportsSelection
        } else {
            currentStep = nextStep
        }
    }
    
    func goToPreviousStep() {
        guard canGoBack else { return }
        
        let allSteps = ClubRalleyOnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
              currentIndex > 0 else { return }
        
        let previousStep = allSteps[currentIndex - 1]
        
        // Skip athlete verification when going back if user is not an athlete
        if previousStep == .athleteVerification && !onboardingData.athlete.isAthlete {
            currentStep = .athleteQuestion
        } else {
            currentStep = previousStep
        }
    }
    
    func skipToStep(_ step: ClubRalleyOnboardingStep) {
        currentStep = step
    }
    
    // MARK: - Data Update Methods
    
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
            // Clear athlete data if they're not an athlete
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
        // In real app, this would be an API call
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        // Mock some taken usernames for demo
        let takenUsernames = ["admin", "clubralley", "test", "user", "athlete"]
        return !takenUsernames.contains(username.lowercased())
    }
    
    // MARK: - Image Upload
    
    func uploadVerificationImage(_ imageData: Data) async throws -> String {
        isLoading = true
        defer { isLoading = false }
        
        // Mock image upload - in real app this would upload to cloud storage
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
        
        // Return mock URL
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
        
        do {
            let userRequest = onboardingData.toUserCreationRequest()
            
            // Submit to backend (mock implementation)
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
            
            // Mark onboarding as complete
            UserDefaults.standard.set(true, forKey: "hasCompletedClubRalleyOnboarding")
            
            isComplete = true
            isLoading = false
            
        } catch {
            self.error = .networkError(error.localizedDescription)
            isLoading = false
        }
    }
    
    // MARK: - Reset
    
    func resetOnboarding() {
        currentStep = .welcome
        onboardingData = CompleteOnboardingData()
        isComplete = false
        error = nil
        UserDefaults.standard.removeObject(forKey: "hasCompletedClubRalleyOnboarding")
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
}