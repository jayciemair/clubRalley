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
    @State private var showingSportsEditor = false

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
            VStack(spacing: ClubRalleyTheme.Spacing.lg) {
                profilePhotoSection
                nameSection
                usernameSection
                bioSection
                locationSection
                instagramSection
                Divider().padding(.vertical, 8)
                privacySection
                Divider().padding(.vertical, 8)
                collegeAthleteSection
                Divider().padding(.vertical, 8)
                sportsSection
                saveButtonSection
                Spacer(minLength: 50)
            }
            .padding(ClubRalleyTheme.Spacing.lg)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                .disabled(viewModel.isSaving)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task { await saveProfile() }
                }
                .font(ClubRalleyTheme.Typography.bodyBold)
                .foregroundColor(ClubRalleyTheme.Colors.accent)
                .disabled(viewModel.isSaving)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .alert("Error Saving", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.saveError ?? "An error occurred while saving your profile.")
        }
        .overlay {
            if viewModel.isSaving {
                ProgressView("Saving...")
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.2), radius: 12)
            }
        }
        .allowsHitTesting(!viewModel.isSaving)
        .onAppear {
            loadCurrentProfile()
        }
    }

    // MARK: - Body Subsections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
            Text("Name")
                .font(ClubRalleyTheme.Typography.headline)
                .foregroundColor(ClubRalleyTheme.Colors.text)

            HStack(spacing: ClubRalleyTheme.Spacing.md) {
                TextField("First Name", text: $firstName)
                    .textFieldStyle(ClubRalleyTextFieldStyle())
                TextField("Last Name", text: $lastName)
                    .textFieldStyle(ClubRalleyTextFieldStyle())
            }

            if let nameError = viewModel.nameError {
                Text(nameError)
                    .font(ClubRalleyTheme.Typography.caption)
                    .foregroundColor(ClubRalleyTheme.Colors.error)
            }
        }
    }

    private var usernameSection: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
            Text("Username")
                .font(ClubRalleyTheme.Typography.headline)
                .foregroundColor(ClubRalleyTheme.Colors.text)

            TextField("username", text: $username)
                .textFieldStyle(ClubRalleyTextFieldStyle())
                .autocapitalization(.none)
                .autocorrectionDisabled()

            if let error = viewModel.usernameError {
                Text(error)
                    .font(ClubRalleyTheme.Typography.caption)
                    .foregroundColor(ClubRalleyTheme.Colors.error)
            }
        }
    }

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
            Text("Bio")
                .font(ClubRalleyTheme.Typography.headline)
                .foregroundColor(ClubRalleyTheme.Colors.text)

            TextEditor(text: $bio)
                .frame(minHeight: 100)
                .padding(8)
                .background(ClubRalleyTheme.Colors.sageGreen.opacity(0.3))
                .cornerRadius(ClubRalleyTheme.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: ClubRalleyTheme.CornerRadius.medium)
                        .stroke(ClubRalleyTheme.Colors.accent.opacity(0.3), lineWidth: 1)
                )

            HStack {
                Text("\(bio.count)/\(EditProfileViewModel.maxBioLength) characters")
                    .font(ClubRalleyTheme.Typography.caption)
                    .foregroundColor(bio.count > EditProfileViewModel.maxBioLength ? ClubRalleyTheme.Colors.error : ClubRalleyTheme.Colors.secondaryText)
                Spacer()
                if bio.count > EditProfileViewModel.maxBioLength {
                    Text("Too long")
                        .font(ClubRalleyTheme.Typography.caption)
                        .foregroundColor(ClubRalleyTheme.Colors.error)
                }
            }

            if let bioError = viewModel.bioError {
                Text(bioError)
                    .font(ClubRalleyTheme.Typography.caption)
                    .foregroundColor(ClubRalleyTheme.Colors.error)
            }
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
            Text("Location")
                .font(ClubRalleyTheme.Typography.headline)
                .foregroundColor(ClubRalleyTheme.Colors.text)

            HStack(spacing: ClubRalleyTheme.Spacing.md) {
                TextField("City", text: $city)
                    .textFieldStyle(ClubRalleyTextFieldStyle())
                TextField("State", text: $state)
                    .textFieldStyle(ClubRalleyTextFieldStyle())
                    .frame(width: 80)
            }
        }
    }

    private var instagramSection: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
            Text("Instagram")
                .font(ClubRalleyTheme.Typography.headline)
                .foregroundColor(ClubRalleyTheme.Colors.text)

            HStack {
                Text("@")
                    .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                TextField("username", text: $instagramHandle)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            .padding()
            .background(ClubRalleyTheme.Colors.sageGreen.opacity(0.3))
            .cornerRadius(ClubRalleyTheme.CornerRadius.medium)
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
            Text("Privacy")
                .font(ClubRalleyTheme.Typography.headline)
                .foregroundColor(ClubRalleyTheme.Colors.text)

            Toggle(isOn: $isPrivateAccount) {
                HStack(spacing: 12) {
                    Image(systemName: isPrivateAccount ? "lock.fill" : "lock.open.fill")
                        .foregroundColor(ClubRalleyTheme.Colors.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Private Account")
                            .font(ClubRalleyTheme.Typography.body)
                        Text(isPrivateAccount ? "Only approved followers can see your profile" : "Anyone can see your profile")
                            .font(ClubRalleyTheme.Typography.caption)
                            .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                    }
                }
            }
            .tint(ClubRalleyTheme.Colors.accent)
        }
    }

    private var collegeAthleteSection: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.md) {
            Text("College Athlete")
                .font(ClubRalleyTheme.Typography.headline)
                .foregroundColor(ClubRalleyTheme.Colors.text)

            Toggle(isOn: $playedCollegeSport) {
                HStack(spacing: 12) {
                    Image(systemName: "graduationcap.fill")
                        .foregroundColor(ClubRalleyTheme.Colors.accent)
                    Text("I played a sport in college")
                        .font(ClubRalleyTheme.Typography.body)
                }
            }
            .tint(ClubRalleyTheme.Colors.accent)

            if playedCollegeSport {
                collegeFieldsSection
            }
        }
        .animation(.easeInOut(duration: 0.2), value: playedCollegeSport)
    }

    private var collegeFieldsSection: some View {
        VStack(spacing: ClubRalleyTheme.Spacing.md) {
            TextField("Sport (e.g., Tennis, Soccer)", text: $collegeSport)
                .textFieldStyle(ClubRalleyTextFieldStyle())
            TextField("School Name", text: $collegeSchool)
                .textFieldStyle(ClubRalleyTextFieldStyle())
            HStack {
                Text("Division")
                    .font(ClubRalleyTheme.Typography.body)
                    .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                Spacer()
                Picker("Division", selection: $collegeDivision) {
                    ForEach(CollegeDivision.allCases, id: \.self) { division in
                        Text(division.displayName).tag(division)
                    }
                }
                .pickerStyle(.menu)
                .tint(ClubRalleyTheme.Colors.accent)
            }
            .padding()
            .background(ClubRalleyTheme.Colors.sageGreen.opacity(0.3))
            .cornerRadius(ClubRalleyTheme.CornerRadius.medium)
            TextField("Position (optional)", text: $collegePosition)
                .textFieldStyle(ClubRalleyTextFieldStyle())
            TextField("Years played (e.g., 2019-2023)", text: $collegeYears)
                .textFieldStyle(ClubRalleyTextFieldStyle())
        }
        .padding(.leading, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var sportsSection: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
            HStack {
                Text("My Sports")
                    .font(ClubRalleyTheme.Typography.headline)
                    .foregroundColor(ClubRalleyTheme.Colors.text)
                Spacer()
                Button(action: { showingSportsEditor = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(ClubRalleyTheme.Typography.caption)
                    .foregroundColor(ClubRalleyTheme.Colors.accent)
                }
            }

            Text("Add sports and skill levels to help others find you for ralleys")
                .font(ClubRalleyTheme.Typography.caption)
                .foregroundColor(ClubRalleyTheme.Colors.secondaryText)

            if let profile = SavedUserProfile.loadFromStorage(), !profile.selectedSports.isEmpty {
                sportsTagsView(sports: profile.selectedSports)
            } else {
                Text("No sports added yet")
                    .font(ClubRalleyTheme.Typography.body)
                    .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                    .padding(.vertical, 8)
            }
        }
    }

    private func sportsTagsView(sports: [String]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
            ForEach(sports, id: \.self) { sport in
                HStack(spacing: 4) {
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 12))
                    Text(sport)
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(ClubRalleyTheme.Colors.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ClubRalleyTheme.Colors.accent.opacity(0.1))
                .cornerRadius(16)
            }
        }
    }

    private var saveButtonSection: some View {
        Button(action: {
            Task { await saveProfile() }
        }) {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                }
                Text(viewModel.isSaving ? "Saving..." : "Save Profile")
                    .font(ClubRalleyTheme.Typography.bodyBold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(ClubRalleyTheme.Colors.accent)
            .foregroundColor(.white)
            .cornerRadius(ClubRalleyTheme.CornerRadius.large)
        }
        .disabled(viewModel.isSaving || !isFormValid)
        .opacity(isFormValid ? 1.0 : 0.6)
        .padding(.top, ClubRalleyTheme.Spacing.lg)
    }

    // MARK: - Profile Photo Section

    private var profilePhotoSection: some View {
        VStack(spacing: ClubRalleyTheme.Spacing.md) {
            ZStack(alignment: .bottomTrailing) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if let photoURL = viewModel.currentPhotoURL,
                          let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(ClubRalleyTheme.Colors.sageGreen)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(ClubRalleyTheme.Colors.accent)
                            )
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(ClubRalleyTheme.Colors.sageGreen)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(ClubRalleyTheme.Colors.accent)
                        )
                }

                Button(action: {
                    showingImagePicker = true
                }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(ClubRalleyTheme.Colors.accent)
                        .clipShape(Circle())
                }
            }

            Text("Tap to change photo")
                .font(ClubRalleyTheme.Typography.caption)
                .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
        }
    }

    // MARK: - Methods

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
            do {
                if let userId = SupabaseManager.shared.currentUser?.id {
                    photoURL = try await ImageUploadService.shared.uploadProfilePhoto(
                        imageData: imageData,
                        userId: userId
                    )
                    print("✅ EDIT_PROFILE - Photo uploaded: \(photoURL ?? "nil")")
                }
            } catch {
                print("❌ EDIT_PROFILE - Photo upload FAILED: \(error)")
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
            print("✅ EDIT_PROFILE saveProfile SUCCESS - dismissing")
            dismiss()
        } else {
            print("❌ EDIT_PROFILE saveProfile FAILED")
            showingSaveError = true
        }
    }
}
