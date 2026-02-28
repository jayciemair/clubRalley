//
//  EditProfileView.swift
//  Club Ralley
//
//  View for editing user profile information
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditProfileViewModel()

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var instagramHandle: String = ""

    // New profile fields
    @State private var isPrivateAccount: Bool = false
    @State private var playedCollegeSport: Bool = false
    @State private var collegeSport: String = ""
    @State private var collegeSchool: String = ""
    @State private var collegeDivision: CollegeDivision = .club
    @State private var collegeYears: String = ""
    @State private var collegePosition: String = ""

    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingSaveError = false
    @State private var saveErrorMessage: String?

    // Power Up: Sports & Skills
    @State private var sportsWithSkills: [SportWithSkill] = []
    @State private var availableSports: [Sport] = DefaultSports.all
    @State private var isSportsExpanded: Bool = false

    // Power Up: Availability
    @State private var isAvailabilityExpanded: Bool = false
    @State private var daySelection: DaySelection = .weekdays
    @State private var selectedDays: Set<Int> = []
    @State private var timePreference: TimePreference = .anytime
    @State private var maxDistance: Int = 25

    // Power Up: Fun Questions
    @State private var isFunQuestionsExpanded: Bool = false
    @State private var favoriteProTeam: String = ""
    @State private var workoutBrands: [String] = []
    @State private var workoutClasses: [String] = []
    @State private var hometown: String = ""
    @State private var wouldDoHappyHour: Bool? = nil

    private let powerUpService = PowerUpProfileService()

    /// Check if form is valid for submission
    private var isFormValid: Bool {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespaces)
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)

        return !trimmedFirstName.isEmpty &&
               !trimmedLastName.isEmpty &&
               trimmedUsername.count >= 3 &&
               bio.count <= EditProfileViewModel.maxBioLength
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile photo
                EditProfilePhotoSection(
                    showingImagePicker: $showingImagePicker,
                    selectedImage: $selectedImage,
                    currentPhotoURL: viewModel.currentPhotoURL
                )
                .padding(.top, 8)
                .padding(.bottom, 4)

                Divider()

                // Basic info fields
                EditProfileNameSection(
                    firstName: $firstName,
                    lastName: $lastName,
                    nameError: viewModel.nameError
                )
                EditProfileUsernameSection(
                    username: $username,
                    usernameError: viewModel.usernameError
                )
                EditProfileBioSection(
                    bio: $bio,
                    bioError: viewModel.bioError,
                    maxBioLength: EditProfileViewModel.maxBioLength
                )
                EditProfileLocationSection(
                    city: $city,
                    state: $state
                )
                EditProfileInstagramSection(
                    instagramHandle: $instagramHandle
                )

                // Settings section
                sectionHeader("Settings")

                EditProfilePrivacySection(
                    isPrivateAccount: $isPrivateAccount
                )
                EditProfileCollegeSection(
                    playedCollegeSport: $playedCollegeSport,
                    collegeSport: $collegeSport,
                    collegeSchool: $collegeSchool,
                    collegeDivision: $collegeDivision,
                    collegeYears: $collegeYears,
                    collegePosition: $collegePosition
                )

                // Power up section
                sectionHeader("Power Up Your Profile")

                EditProfileSportsSection(
                    sportsWithSkills: $sportsWithSkills,
                    availableSports: availableSports,
                    isSportsExpanded: $isSportsExpanded
                )
                EditProfileAvailabilitySection(
                    isAvailabilityExpanded: $isAvailabilityExpanded,
                    daySelection: $daySelection,
                    selectedDays: $selectedDays,
                    timePreference: $timePreference,
                    maxDistance: $maxDistance
                )
                EditProfileFunQuestionsSection(
                    isFunQuestionsExpanded: $isFunQuestionsExpanded,
                    favoriteProTeam: $favoriteProTeam,
                    workoutBrands: $workoutBrands,
                    workoutClasses: $workoutClasses,
                    hometown: $hometown,
                    wouldDoHappyHour: $wouldDoHappyHour
                )

                EditProfileSaveButton(
                    isSaving: viewModel.isSaving,
                    isFormValid: isFormValid,
                    onSave: { Task { await saveProfile() } }
                )

                Spacer(minLength: 50)
            }
        }
        .background(Color(.systemBackground))
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 16))
                .foregroundColor(ClubRalleyTheme.Colors.text)
                .disabled(viewModel.isSaving)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await saveProfile() } }) {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                }
                .disabled(viewModel.isSaving || !isFormValid)
                .opacity(isFormValid ? 1.0 : 0.4)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .alert("Error Saving", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage ?? viewModel.saveError ?? "An error occurred while saving your profile.")
        }
        .overlay {
            if viewModel.isSaving {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(ClubRalleyTheme.Colors.darkGreen)
                    .padding(28)
                    .background(.ultraThinMaterial)
                    .cornerRadius(14)
            }
        }
        .allowsHitTesting(!viewModel.isSaving)
        .onAppear {
            loadCurrentProfile()
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        VStack(spacing: 0) {
            Color(.systemGray6)
                .frame(height: 20)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.systemGray))
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
        }
    }

    // MARK: - Data Lifecycle

    private func loadCurrentProfile() {
        print("📝 EDIT_PROFILE loadCurrentProfile START")

        if let profile = SavedUserProfile.loadFromStorage() {
            print("📝 EDIT_PROFILE - Found saved profile: \(profile.firstName) \(profile.lastName)")
            print("📝 EDIT_PROFILE - username: \(profile.username), city: \(profile.locationCity)")

            firstName = profile.firstName
            lastName = profile.lastName
            username = profile.username
            city = profile.locationCity
            state = profile.locationState
            bio = profile.bio ?? ""
            instagramHandle = profile.instagramHandle ?? ""
            viewModel.currentPhotoURL = profile.profilePhotoURL

            // Load new fields from extended profile data
            isPrivateAccount = profile.isPrivateAccount ?? false
            playedCollegeSport = profile.playedCollegeSport ?? false
            if let collegeInfo = profile.collegeAthleteInfo {
                collegeSport = collegeInfo.sport
                collegeSchool = collegeInfo.school
                collegeDivision = CollegeDivision(rawValue: collegeInfo.division) ?? .club
                collegeYears = collegeInfo.yearsPlayed ?? ""
                collegePosition = collegeInfo.position ?? ""
            }

            print("📝 EDIT_PROFILE - Fields populated from local storage")
        } else {
            print("❌ EDIT_PROFILE - No saved profile found in local storage")
        }

        // Also try to load from Supabase for bio/instagram if not in local storage
        Task {
            await loadFromSupabase()
        }
    }

    private func loadFromSupabase() async {
        print("📝 EDIT_PROFILE loadFromSupabase START")

        // Try to get userId from Supabase or fall back to saved profile
        var userId: UUID? = SupabaseManager.shared.currentUser?.id
        print("📝 EDIT_PROFILE - Supabase userId: \(userId?.uuidString ?? "nil")")

        if userId == nil, let savedProfile = SavedUserProfile.loadFromStorage() {
            userId = savedProfile.id
            print("📝 EDIT_PROFILE - Using SavedProfile userId: \(savedProfile.id)")
        }

        guard let userId = userId else {
            print("❌ EDIT_PROFILE loadFromSupabase - No userId available from any source")
            return
        }

        print("📝 EDIT_PROFILE loadFromSupabase - using userId: \(userId)")

        do {
            print("📝 EDIT_PROFILE - Querying users table...")
            let users: [ClubUserProfileData] = try await SupabaseManager.shared.query("club_users")
                .select("bio, instagram_handle")
                .eq("id", value: userId)
                .execute()

            print("📝 EDIT_PROFILE - Got \(users.count) results from Supabase")

            if let user = users.first {
                print("✅ EDIT_PROFILE - Found user data: bio=\(user.bio ?? "nil"), instagram=\(user.instagram_handle ?? "nil")")
                if bio.isEmpty, let dbBio = user.bio {
                    bio = dbBio
                    print("✅ EDIT_PROFILE - Updated bio from Supabase")
                }
                if instagramHandle.isEmpty, let dbInsta = user.instagram_handle {
                    instagramHandle = dbInsta
                    print("✅ EDIT_PROFILE - Updated instagram from Supabase")
                }
            } else {
                print("❌ EDIT_PROFILE - No user data found in Supabase")
            }
        } catch {
            print("❌ EDIT_PROFILE loadFromSupabase FAILED: \(error)")
        }

        // Load Power Up JSONB data
        do {
            let powerUpData = try await powerUpService.loadExistingProfileData()
            print("📝 EDIT_PROFILE - Loaded Power Up data: \(powerUpData.sportsWithSkills.count) sports")

            // Match loaded sports against DefaultSports by name for correct icons
            sportsWithSkills = powerUpData.sportsWithSkills.map { loaded in
                if let defaultSport = availableSports.first(where: { $0.name == loaded.sport.name }) {
                    return SportWithSkill(sport: defaultSport, skillLevel: loaded.skillLevel)
                }
                return loaded
            }

            // Availability
            let loadedDays = powerUpData.selectedDays
            if !loadedDays.isEmpty {
                selectedDays = loadedDays
                // Infer daySelection from loaded days
                let weekdaySet: Set<Int> = [2, 3, 4, 5, 6]
                let weekendSet: Set<Int> = [1, 7]
                if loadedDays == weekdaySet {
                    daySelection = .weekdays
                } else if loadedDays == weekendSet {
                    daySelection = .weekends
                } else {
                    daySelection = .specificDays
                }
            }
            timePreference = powerUpData.timePreference
            maxDistance = powerUpData.maxDistance

            // Fun Questions
            favoriteProTeam = powerUpData.favoriteProTeam
            workoutBrands = powerUpData.workoutBrands
            workoutClasses = powerUpData.workoutClasses
            hometown = powerUpData.hometown
            wouldDoHappyHour = powerUpData.wouldDoHappyHour
        } catch {
            print("📝 EDIT_PROFILE - Power Up data load failed (non-fatal): \(error)")
        }
    }

    private func saveProfile() async {
        print("📝 EDIT_PROFILE saveProfile START")
        print("📝 EDIT_PROFILE - firstName: \(firstName)")
        print("📝 EDIT_PROFILE - lastName: \(lastName)")
        print("📝 EDIT_PROFILE - username: \(username)")
        print("📝 EDIT_PROFILE - bio: \(bio)")
        print("📝 EDIT_PROFILE - city: \(city), state: \(state)")
        print("📝 EDIT_PROFILE - instagramHandle: \(instagramHandle)")

        // Upload new photo if selected
        var photoURL: String? = viewModel.currentPhotoURL
        print("📝 EDIT_PROFILE - existing photoURL: \(photoURL ?? "nil")")

        if let image = selectedImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            print("📝 EDIT_PROFILE - Uploading new photo...")
            // Use Supabase currentUser, fallback to saved profile ID
            let userId = SupabaseManager.shared.currentUser?.id ?? SavedUserProfile.loadFromStorage()?.id
            if let userId = userId {
                do {
                    photoURL = try await ImageUploadService.shared.uploadProfilePhoto(
                        imageData: imageData,
                        userId: userId
                    )
                    print("✅ EDIT_PROFILE - Photo uploaded: \(photoURL ?? "nil")")
                } catch {
                    print("❌ EDIT_PROFILE - Photo upload FAILED: \(error)")
                    saveErrorMessage = "Failed to upload photo: \(error.localizedDescription)"
                    showingSaveError = true
                    return
                }
            } else {
                print("❌ EDIT_PROFILE - No userId available for photo upload")
                saveErrorMessage = "Unable to upload photo. Please try signing out and back in."
                showingSaveError = true
                return
            }
        }

        // Save profile
        print("📝 EDIT_PROFILE - Calling viewModel.saveProfile...")
        let success = await viewModel.saveProfile(
            firstName: firstName,
            lastName: lastName,
            username: username,
            bio: bio,
            city: city,
            state: state,
            instagramHandle: instagramHandle,
            profilePhotoURL: photoURL,
            isPrivateAccount: isPrivateAccount,
            playedCollegeSport: playedCollegeSport,
            collegeSport: collegeSport,
            collegeSchool: collegeSchool,
            collegeDivision: collegeDivision,
            collegeYears: collegeYears,
            collegePosition: collegePosition
        )

        if success {
            // Save Power Up JSONB data (non-fatal if it fails)
            do {
                var powerUpData = PowerUpProfileData()
                powerUpData.sportsWithSkills = sportsWithSkills
                powerUpData.daySelection = daySelection
                powerUpData.selectedDays = selectedDays
                powerUpData.timePreference = timePreference
                powerUpData.maxDistance = maxDistance
                powerUpData.favoriteProTeam = favoriteProTeam
                powerUpData.workoutBrands = workoutBrands
                powerUpData.workoutClasses = workoutClasses
                powerUpData.hometown = hometown
                powerUpData.wouldDoHappyHour = wouldDoHappyHour
                // Pass through bio/instagram so JSONB save doesn't clear them
                powerUpData.bio = bio
                powerUpData.instagramHandle = instagramHandle
                powerUpData.profilePhotoURL = photoURL

                try await powerUpService.saveProfileData(powerUpData)
                print("✅ EDIT_PROFILE Power Up data saved")
            } catch {
                print("📝 EDIT_PROFILE Power Up save failed (non-fatal): \(error)")
            }

            print("✅ EDIT_PROFILE saveProfile SUCCESS - dismissing")
            dismiss()
        } else {
            print("❌ EDIT_PROFILE saveProfile FAILED")
            showingSaveError = true
        }
    }
}
