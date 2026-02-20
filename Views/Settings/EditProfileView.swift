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
                sportsAndSkillsSection
                Divider().padding(.vertical, 8)
                availabilitySection
                Divider().padding(.vertical, 8)
                funQuestionsSection
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

    // MARK: - Sports & Skills Section (Collapsible)

    private var sportsAndSkillsSection: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSportsExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Sports & Skills")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                    Spacer()
                    if !isSportsExpanded && !sportsWithSkills.isEmpty {
                        sportsCollapsedSummary
                    }
                    Image(systemName: isSportsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isSportsExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select your sports")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(availableSports) { sport in
                            SportSelectionCardPowerUp(
                                sport: sport,
                                isSelected: isSportSelectedByName(sport.name),
                                onTap: { toggleSportByName(sport) }
                            )
                        }
                    }

                    if !sportsWithSkills.isEmpty {
                        Text("Set your skill level")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        ForEach(sportsWithSkills.indices, id: \.self) { index in
                            SkillLevelPicker(
                                sport: sportsWithSkills[index].sport,
                                skillLevel: $sportsWithSkills[index].skillLevel
                            )
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSportsExpanded)
    }

    private var sportsCollapsedSummary: some View {
        HStack(spacing: 4) {
            ForEach(sportsWithSkills.prefix(3), id: \.id) { sportWithSkill in
                Text(sportWithSkill.sport.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ClubRalleyTheme.Colors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(ClubRalleyTheme.Colors.accent.opacity(0.1))
                    .cornerRadius(10)
            }
            if sportsWithSkills.count > 3 {
                Text("+\(sportsWithSkills.count - 3)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
            }
        }
    }

    // MARK: - Availability Section (Collapsible)

    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAvailabilityExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Availability")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                    Spacer()
                    if !isAvailabilityExpanded {
                        Text(daySelection.displayName + " \u{00B7} " + timePreference.displayName)
                            .font(.system(size: 12))
                            .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                    }
                    Image(systemName: isAvailabilityExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isAvailabilityExpanded {
                VStack(alignment: .leading, spacing: 20) {
                    // Day selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("When are you usually free?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        VStack(spacing: 10) {
                            ForEach(DaySelection.allCases, id: \.self) { option in
                                DayOptionCard(
                                    option: option,
                                    isSelected: daySelection == option,
                                    onTap: { selectDayOption(option) }
                                )
                            }
                        }

                        if daySelection == .specificDays {
                            HStack(spacing: 8) {
                                ForEach(DayOfWeek.days, id: \.id) { day in
                                    DayCircleButton(
                                        label: day.shortName,
                                        isSelected: selectedDays.contains(day.id),
                                        onTap: { toggleDay(day.id) }
                                    )
                                }
                            }
                            .padding(.top, 4)
                        }
                    }

                    // Time preference
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What time works best?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(TimePreference.allCases, id: \.self) { time in
                                TimePreferenceCard(
                                    preference: time,
                                    isSelected: timePreference == time,
                                    onTap: { timePreference = time }
                                )
                            }
                        }
                    }

                    // Distance slider
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How far will you travel?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            HStack {
                                Text("Up to")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                Text("\(maxDistance) miles")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                                Spacer()
                            }

                            Slider(
                                value: Binding(
                                    get: { Double(maxDistance) },
                                    set: { maxDistance = Int($0) }
                                ),
                                in: 5...100,
                                step: 5
                            )
                            .tint(ClubRalleyTheme.Colors.darkGreen)

                            HStack {
                                Text("5 mi")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("100 mi")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isAvailabilityExpanded)
    }

    // MARK: - Fun Questions Section (Collapsible)

    private var funQuestionsSection: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFunQuestionsExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Fun Questions")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                    Spacer()
                    Image(systemName: isFunQuestionsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isFunQuestionsExpanded {
                VStack(alignment: .leading, spacing: 20) {
                    // Favorite pro team
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Favorite pro sports team?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        TextField("e.g. Lakers, Patriots, Yankees...", text: $favoriteProTeam)
                            .font(.system(size: 16))
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                    }

                    // Workout brands
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Favorite workout brands?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        PowerUpTagGrid(
                            items: WorkoutBrandOptions.brands,
                            selectedItems: $workoutBrands
                        )
                    }

                    // Workout classes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Favorite type of workout class?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        PowerUpTagGrid(
                            items: WorkoutClassOptions.classes,
                            selectedItems: $workoutClasses
                        )
                    }

                    // Hometown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hometown")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        TextField("City, State", text: $hometown)
                            .font(.system(size: 16))
                            .textInputAutocapitalization(.words)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                    }

                    // Happy hour
                    YesNoToggle(
                        question: "Would you go to happy hour after a workout?",
                        value: $wouldDoHappyHour
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFunQuestionsExpanded)
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

    // MARK: - Sports Helpers (name-based matching)

    private func isSportSelectedByName(_ name: String) -> Bool {
        sportsWithSkills.contains { $0.sport.name == name }
    }

    private func toggleSportByName(_ sport: Sport) {
        if let index = sportsWithSkills.firstIndex(where: { $0.sport.name == sport.name }) {
            sportsWithSkills.remove(at: index)
        } else {
            sportsWithSkills.append(SportWithSkill(sport: sport, skillLevel: .competitor))
        }
    }

    // MARK: - Availability Helpers

    private func selectDayOption(_ option: DaySelection) {
        daySelection = option
        if option != .specificDays {
            selectedDays.removeAll()
        }
    }

    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
        daySelection = .specificDays
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
