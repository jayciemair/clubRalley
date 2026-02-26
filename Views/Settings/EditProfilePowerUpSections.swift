//
//  EditProfilePowerUpSections.swift
//  Club Ralley
//
//  Extracted Power Up sections for EditProfileView
//

import SwiftUI

// MARK: - Sports & Skills

struct EditProfileSportsSection: View {
    @Binding var sportsWithSkills: [SportWithSkill]
    var availableSports: [Sport]
    @Binding var isSportsExpanded: Bool

    var body: some View {
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
                        collapsedSummary
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

    private var collapsedSummary: some View {
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
}

// MARK: - Availability

struct EditProfileAvailabilitySection: View {
    @Binding var isAvailabilityExpanded: Bool
    @Binding var daySelection: DaySelection
    @Binding var selectedDays: Set<Int>
    @Binding var timePreference: TimePreference
    @Binding var maxDistance: Int

    var body: some View {
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
}

// MARK: - Fun Questions

struct EditProfileFunQuestionsSection: View {
    @Binding var isFunQuestionsExpanded: Bool
    @Binding var favoriteProTeam: String
    @Binding var workoutBrands: [String]
    @Binding var workoutClasses: [String]
    @Binding var hometown: String
    @Binding var wouldDoHappyHour: Bool?

    var body: some View {
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
}

// MARK: - Save Button

struct EditProfileSaveButton: View {
    var isSaving: Bool
    var isFormValid: Bool
    var onSave: () -> Void

    var body: some View {
        Button(action: onSave) {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                }
                Text(isSaving ? "Saving..." : "Save Profile")
                    .font(ClubRalleyTheme.Typography.bodyBold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(ClubRalleyTheme.Colors.accent)
            .foregroundColor(.white)
            .cornerRadius(ClubRalleyTheme.CornerRadius.large)
        }
        .disabled(isSaving || !isFormValid)
        .opacity(isFormValid ? 1.0 : 0.6)
        .padding(.top, ClubRalleyTheme.Spacing.lg)
    }
}
