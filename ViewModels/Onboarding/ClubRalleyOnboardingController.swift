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
    @Published var currentStep: ClubRalleyOnboardingStep = .phoneNumber
    @Published var onboardingData = CompleteOnboardingData()
    @Published var isLoading = false
    @Published var error: ClubRalleyOnboardingError?
    @Published var isComplete = false
    @Published var isReturningUser = false

    // Validation states
    @Published var isUsernameAvailable: Bool?
    @Published var isCheckingUsername = false

    // Email auth
    private var authenticatedUserId: UUID?

    // MARK: - Phone/OTP (commented out — Twilio not configured)
    // @Published var isPhoneVerified = false
    // @Published var verificationCode = ""
    // @Published var resendCooldown: Int = 0
    // private var cooldownTimer: Timer?

    // MARK: - Computed Properties
    var currentProgress: Double {
        currentStep.progressValue
    }

    var canGoBack: Bool {
        currentStep.canGoBack
    }

    var canContinue: Bool {
        switch currentStep {
        case .phoneNumber:
            return onboardingData.profile.isPhoneComplete
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
        case .collegeAthlete:
            return true
        case .athleteVerification:
            return onboardingData.athlete.isComplete
        case .completion:
            return true
        }
    }

    // MARK: - Dependencies
    private let userService = UserProfileService.shared
    private let supabaseManager = SupabaseManager.shared

    // MARK: - Navigation Methods

    func goToNextStep() {
        print("[supaTennis] ➡️ goToNextStep() — current: \(currentStep)")
        let allSteps = ClubRalleyOnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
              currentIndex < allSteps.count - 1 else {
            print("[supaTennis] ➡️ No more steps — calling completeOnboarding()")
            completeOnboarding()
            return
        }

        var nextStep = allSteps[currentIndex + 1]

        // Skip athleteVerification if user is not an athlete
        if nextStep == .athleteVerification && !onboardingData.athlete.isAthlete {
            guard let skipIndex = allSteps.firstIndex(of: nextStep),
                  skipIndex < allSteps.count - 1 else { return }
            nextStep = allSteps[skipIndex + 1]
        }

        print("[supaTennis] ➡️ Next step: \(nextStep)")

        // If we're about to show the completion screen, submit data first
        if nextStep == .completion {
            print("[supaTennis] 🏁 Next is .completion — triggering completeOnboarding()")
            completeOnboarding()
        }

        currentStep = nextStep
    }

    func goToPreviousStep() {
        guard canGoBack else { return }

        let allSteps = ClubRalleyOnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
              currentIndex > 0 else { return }

        var previousStep = allSteps[currentIndex - 1]

        // Skip athleteVerification going backwards if user is not an athlete
        if previousStep == .athleteVerification && !onboardingData.athlete.isAthlete {
            guard let skipIndex = allSteps.firstIndex(of: previousStep),
                  skipIndex > 0 else { return }
            previousStep = allSteps[skipIndex - 1]
        }

        currentStep = previousStep
    }

    func skipToStep(_ step: ClubRalleyOnboardingStep) {
        currentStep = step
    }

    // MARK: - Anonymous Auth (Twilio SMS auth coming later)

    /// Sign in anonymously so Supabase RLS works without requiring email/phone
    private func signInAnonymously() async throws -> UUID {
        print("[supaTennis] 🔑 signInAnonymously() called")
        let userId = try await supabaseManager.signInAnonymously()
        authenticatedUserId = userId
        print("[supaTennis] ✅ Anonymous sign-in succeeded — userId: \(userId)")
        return userId
    }

    // MARK: - Phone Number Methods (commented out — Twilio not configured)
    // Uncomment when Twilio is set up to re-enable phone auth
    /*
    func updatePhoneNumber(_ phone: String, countryCode: String = "+1") {
        onboardingData.profile.phoneNumber = phone.filter { $0.isNumber }
        onboardingData.profile.phoneCountryCode = countryCode
    }

    private var e164Phone: String {
        let digits = onboardingData.profile.phoneNumber.filter { $0.isNumber }
        return "\(onboardingData.profile.phoneCountryCode)\(digits)"
    }

    func sendVerificationCode() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        let phone = e164Phone
        print("[supaTennis] 📱 sendVerificationCode() — phone: \(phone)")

        do {
            try await supabaseManager.sendOTP(phone: phone)
            print("[supaTennis] ✅ sendVerificationCode() — OTP sent OK")
            startResendCooldown()
            return true
        } catch {
            print("[supaTennis] ⚠️ sendVerificationCode() FAILED: \(error)")
            print("[supaTennis] ⚠️ Falling back to mock mode")
            startResendCooldown()
            return true
        }
    }

    func verifyPhoneCode(_ code: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        print("[supaTennis] 🔐 verifyPhoneCode() — code length: \(code.count), phone: \(e164Phone)")

        do {
            let userId = try await supabaseManager.verifyOTP(phone: e164Phone, code: code)
            isPhoneVerified = true
            authenticatedUserId = userId
            print("[supaTennis] ✅ verifyPhoneCode() — REAL auth succeeded, userId: \(userId)")

            print("[supaTennis] 🔍 Checking for existing profile...")
            if let existingProfile = try? await supabaseManager.fetchUserProfile(userId: userId) {
                print("[supaTennis] 🔄 Found existing profile — returning user: \(existingProfile.username ?? "no username")")
                handleReturningUser(existingProfile, userId: userId)
                return true
            }
            print("[supaTennis] 🆕 No existing profile — new user flow")

            return true
        } catch {
            print("[supaTennis] ❌ verifyPhoneCode() REAL auth FAILED: \(error)")
            print("[supaTennis] ⚠️ Falling back to mock mode")
            if code.count == 6 {
                isPhoneVerified = true
                authenticatedUserId = UUID()
                print("[supaTennis] ⚠️ MOCK userId assigned: \(authenticatedUserId!)")
                return true
            }
            self.error = .networkError("Please enter a 6-digit code.")
            return false
        }
    }

    private func handleReturningUser(_ profile: SavedUserProfile, userId: UUID) {
        MultiProfileManager.shared.addProfile(profile, setAsActive: true)

        if let profileData = try? JSONEncoder().with({ $0.dateEncodingStrategy = .iso8601 }).encode(profile) {
            UserDefaults.standard.set(profileData, forKey: "currentUserProfile")
        }

        supabaseManager.currentUser = SupabaseUser(
            id: userId,
            email: profile.email,
            firstName: profile.firstName,
            lastName: profile.lastName
        )

        UserDefaults.standard.set(true, forKey: "hasCompletedClubRalleyOnboarding")
        isReturningUser = true
        isComplete = true
    }

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
    */

    // MARK: - Email Methods

    func updateEmail(_ email: String) {
        onboardingData.profile.email = email.trimmingCharacters(in: .whitespaces).lowercased()
    }

    /// Sign up with email/password, returns true on success
    func signUpWithEmail() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        let email = onboardingData.profile.email
        let password = onboardingData.profile.password

        do {
            let userId = try await supabaseManager.signUpWithEmail(email: email, password: password)
            authenticatedUserId = userId
            return true
        } catch {
            let msg = error.localizedDescription.lowercased()
            if msg.contains("already") || msg.contains("exists") || msg.contains("registered") {
                self.error = .emailAlreadyExists
            } else {
                self.error = .networkError(error.localizedDescription)
            }
            return false
        }
    }

    /// Sign in only (re-auth mode), completes onboarding on success
    func signInOnly() async {
        isLoading = true
        defer { isLoading = false }

        let email = onboardingData.profile.email
        let password = onboardingData.profile.password

        do {
            let userId = try await supabaseManager.signInWithEmail(email: email, password: password)
            authenticatedUserId = userId

            // Try to load existing profile
            if let existingProfile = try? await supabaseManager.fetchUserProfile(userId: userId) {
                MultiProfileManager.shared.addProfile(existingProfile, setAsActive: true)

                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                if let profileData = try? encoder.encode(existingProfile) {
                    UserDefaults.standard.set(profileData, forKey: "currentUserProfile")
                }

                supabaseManager.currentUser = SupabaseUser(
                    id: userId,
                    email: existingProfile.email,
                    firstName: existingProfile.firstName,
                    lastName: existingProfile.lastName
                )
            }

            UserDefaults.standard.set(true, forKey: "hasCompletedClubRalleyOnboarding")
            isReturningUser = true
            isComplete = true
        } catch {
            self.error = .networkError("Invalid email or password. Please try again.")
        }
    }

    // MARK: - Phone Verification (Mock — Twilio not configured)

    /// Mock phone verification — accepts any 6-digit code.
    /// Uses anonymous Supabase auth behind the scenes so RLS works.
    /// TODO: Replace with real Twilio OTP verification.
    func verifyPhoneCode(_ code: String) async -> Bool {
        guard code.count == 6 else {
            self.error = .networkError("Please enter a 6-digit code.")
            return false
        }

        isLoading = true
        defer { isLoading = false }

        // Sign in anonymously so Supabase RLS works
        if authenticatedUserId == nil && supabaseManager.currentUser == nil {
            do {
                let userId = try await signInAnonymously()
                print("[supaTennis] 🔑 Mock phone verify — anonymous auth succeeded: \(userId)")
            } catch {
                print("[supaTennis] ❌ Mock phone verify — anonymous auth failed: \(error)")
                self.error = .networkError("Failed to create session. Please try again.")
                return false
            }
        }

        // Check for existing profile (returning user)
        if let userId = authenticatedUserId ?? supabaseManager.currentUser?.id,
           let existingProfile = try? await supabaseManager.fetchUserProfile(userId: userId) {
            print("[supaTennis] 🔄 Returning user detected: \(existingProfile.username)")
            MultiProfileManager.shared.addProfile(existingProfile, setAsActive: true)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let profileData = try? encoder.encode(existingProfile) {
                UserDefaults.standard.set(profileData, forKey: "currentUserProfile")
            }

            supabaseManager.currentUser = SupabaseUser(
                id: userId,
                email: existingProfile.email,
                firstName: existingProfile.firstName,
                lastName: existingProfile.lastName
            )

            UserDefaults.standard.set(true, forKey: "hasCompletedClubRalleyOnboarding")
            isReturningUser = true
            isComplete = true
            return true
        }

        // New user — continue to profile setup
        return true
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

        // Upload to Supabase Storage via ImageUploadService
        let userId = authenticatedUserId ?? supabaseManager.currentUser?.id ?? UUID()
        let url = try await ImageUploadService.shared.uploadProfilePhoto(imageData: imageData, userId: userId)
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

        // Check against reserved usernames
        let reserved = ["admin", "clubralley", "test", "user", "athlete", "ralley"]
        guard !reserved.contains(username.lowercased()) else { return false }

        // Check availability against Supabase club_users table
        do {
            let existing: [DatabaseUser] = try await supabaseManager.query("club_users")
                .select("first_name, last_name, username, profile_photo_url")
                .eq("username", value: username.lowercased())
                .limit(1)
                .execute()
            return existing.isEmpty
        } catch {
            print("[supaTennis] ⚠️ Username availability check failed: \(error)")
            // On network error, allow the user to proceed — the server will
            // catch duplicates at submission time
            return true
        }
    }

    // MARK: - Image Upload

    func uploadVerificationImage(_ imageData: Data) async throws -> String {
        isLoading = true
        defer { isLoading = false }

        // Upload to Supabase Storage (reuse profile-photos bucket with verification path)
        let userId = authenticatedUserId ?? supabaseManager.currentUser?.id ?? UUID()
        return try await ImageUploadService.shared.uploadProfilePhoto(imageData: imageData, userId: userId)
    }

    // MARK: - Completion

    private func completeOnboarding() {
        print("[supaTennis] 🏁 completeOnboarding() called — launching submitOnboardingData() task")
        Task {
            await submitOnboardingData()
        }
    }

    private func submitOnboardingData() async {
        isLoading = true
        error = nil

        print("[supaTennis] 🚀 submitOnboardingData() START")

        // STEP 0: Sign in anonymously (gives us auth.uid() for RLS)
        if authenticatedUserId == nil && supabaseManager.currentUser == nil {
            do {
                let anonId = try await signInAnonymously()
                print("[supaTennis] 🔑 Anonymous auth succeeded — userId: \(anonId)")
            } catch {
                print("[supaTennis] ❌ Anonymous auth failed: \(error)")
                self.error = .networkError("Failed to create account. Please try again.")
                isLoading = false
                return
            }
        }

        let userId = authenticatedUserId ?? supabaseManager.currentUser?.id ?? UUID()

        print("[supaTennis] 🚀 Resolved userId: \(userId)")
        print("[supaTennis] 🚀 Onboarding data:")
        print("[supaTennis]   firstName: '\(onboardingData.profile.firstName)'")
        print("[supaTennis]   lastName: '\(onboardingData.profile.lastName)'")
        print("[supaTennis]   username: '\(onboardingData.profile.username)'")
        print("[supaTennis]   email: '\(onboardingData.profile.email)'")
        print("[supaTennis]   city: '\(onboardingData.profile.city)'")
        print("[supaTennis]   state: '\(onboardingData.profile.state)'")
        print("[supaTennis]   profilePhotoURL: \(onboardingData.profile.profilePhotoURL ?? "nil")")
        print("[supaTennis]   isAthlete: \(onboardingData.athlete.isAthlete)")
        print("[supaTennis]   sports: \(onboardingData.interests.selectedSports.map { $0.sport.name })")

        // Build athlete info JSONB if user is an athlete
        let athleteInfoJSON: ClubUserAthleteInfoJSON? = {
            guard onboardingData.athlete.isAthlete,
                  let sport = onboardingData.athlete.sport,
                  let school = onboardingData.athlete.school else { return nil }
            return ClubUserAthleteInfoJSON(
                school: school.name,
                sport: sport.name,
                division: nil,
                years_played: nil,
                position: nil,
                played_college: true,
                verified: false,
                verification_image_url: onboardingData.athlete.verificationImageURL,
                verification_notes: onboardingData.athlete.verificationNotes.isEmpty ? nil : onboardingData.athlete.verificationNotes
            )
        }()

        let sportsArray: [String]? = onboardingData.interests.selectedSports.isEmpty
            ? nil
            : onboardingData.interests.selectedSports.map { $0.sport.name }

        // STEP 1: Create profile in club_users table
        print("[supaTennis] 📝 STEP 1: Creating club_users row...")
        do {
            try await supabaseManager.createClubUser(
                id: userId,
                email: onboardingData.profile.email,
                firstName: onboardingData.profile.firstName,
                lastName: onboardingData.profile.lastName,
                username: onboardingData.profile.username,
                city: onboardingData.profile.city,
                state: onboardingData.profile.state,
                profilePhotoURL: onboardingData.profile.profilePhotoURL,
                isVerifiedAthlete: onboardingData.athlete.isAthlete ? true : nil,
                athleteInfo: athleteInfoJSON,
                sports: sportsArray
            )
            print("[supaTennis] ✅ STEP 1 SUCCESS — club_users row created")
        } catch {
            print("[supaTennis] ❌ STEP 1 FAILED: \(error)")
            print("[supaTennis] ❌ Error localizedDescription: \(error.localizedDescription)")
            let errorMessage = error.localizedDescription.lowercased()
            if errorMessage.contains("already") || errorMessage.contains("duplicate") || errorMessage.contains("unique") {
                print("[supaTennis] ❌ Duplicate user detected — navigating back to username screen")
                self.error = .usernameAlreadyTaken
                self.isUsernameAvailable = false
                self.currentStep = .username
                isLoading = false
                return
            }
            print("[supaTennis] ❌ Non-duplicate Supabase error — showing error to user")
            self.error = .networkError("Failed to create account: \(error.localizedDescription)")
            isLoading = false
            return
        }

        // STEP 2: Save local profile backup
        print("[supaTennis] 💾 STEP 2: Saving local profile backup...")
        do {
            // Build saved athlete info for local persistence
            let savedAthleteInfo: SavedCollegeAthleteInfo? = {
                guard onboardingData.athlete.isAthlete,
                      let sport = onboardingData.athlete.sport,
                      let school = onboardingData.athlete.school else { return nil }
                return SavedCollegeAthleteInfo(
                    sport: sport.name,
                    school: school.name,
                    division: "",
                    yearsPlayed: nil,
                    position: nil
                )
            }()

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
                createdAt: Date(),
                playedCollegeSport: onboardingData.athlete.isAthlete,
                collegeAthleteInfo: savedAthleteInfo
            )

            MultiProfileManager.shared.addProfile(userProfile, setAsActive: true)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let profileData = try encoder.encode(userProfile)
            UserDefaults.standard.set(profileData, forKey: "currentUserProfile")
            print("[supaTennis] ✅ STEP 2 — local profile saved to UserDefaults")

            if let photoData = onboardingData.profile.profilePhotoData {
                UserDefaults.standard.set(photoData, forKey: "currentUserProfilePhoto")
                print("[supaTennis] ✅ STEP 2 — profile photo data saved (\(photoData.count) bytes)")
            }

            supabaseManager.currentUser = SupabaseUser(
                id: userId,
                email: onboardingData.profile.email,
                firstName: onboardingData.profile.firstName,
                lastName: onboardingData.profile.lastName
            )
            print("[supaTennis] ✅ STEP 2 — supabaseManager.currentUser set")

        } catch {
            print("[supaTennis] ❌ STEP 2 FAILED — local save error: \(error)")
        }

        // STEP 3: Mark onboarding as complete
        print("[supaTennis] 🏁 STEP 3: Marking onboarding complete...")
        UserDefaults.standard.set(true, forKey: "hasCompletedClubRalleyOnboarding")

        PushNotificationService.shared.requestPermissionAndRegister()
        await InAppNotificationService.shared.startListening()

        try? await Task.sleep(nanoseconds: 500_000_000)

        isComplete = true
        isLoading = false
        print("[supaTennis] 🎉 submitOnboardingData() COMPLETE — isComplete: \(isComplete)")
    }

    // MARK: - Reset

    func resetOnboarding() {
        currentStep = .phoneNumber
        onboardingData = CompleteOnboardingData()
        isComplete = false
        error = nil
        isUsernameAvailable = nil
        authenticatedUserId = nil
        // Phone/OTP reset (commented out — Twilio not configured)
        // isPhoneVerified = false
        // authenticatedUserId = nil
        // verificationCode = ""
        // resendCooldown = 0
        // cooldownTimer?.invalidate()
        UserDefaults.standard.removeObject(forKey: "hasCompletedClubRalleyOnboarding")
        SavedUserProfile.clearStorage()
    }

    // MARK: - Validation Helpers (phone commented out — Twilio not configured)
    /*
    func isValidPhoneNumber(_ phone: String) -> Bool {
        let digits = phone.filter { $0.isNumber }
        return digits.count >= 10 && digits.count <= 15
    }
    */
}

// MARK: - JSONEncoder Helper

private extension JSONEncoder {
    func with(_ configure: (JSONEncoder) -> Void) -> JSONEncoder {
        configure(self)
        return self
    }
}
