//
//  EditProfilePowerUpSections.swift
//  Club Ralley
//
//  Instagram-style power-up profile sections
//

import SwiftUI

// MARK: - Sports & Skills

struct EditProfileSportsSection: View {
    @Binding var sportsWithSkills: [SportWithSkill]
    var availableSports: [Sport]
    @Binding var isSportsExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSportsExpanded.toggle()
                }
            }) {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 16))
                            .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                            .frame(width: 24)

                        Text("Sports & Skills")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(ClubRalleyTheme.Colors.text)
                    }

                    Spacer()

                    if !isSportsExpanded && !sportsWithSkills.isEmpty {
                        Text("\(sportsWithSkills.count) selected")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.systemGray))
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(.systemGray3))
                        .rotationEffect(.degrees(isSportsExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
            }
            .buttonStyle(PlainButtonStyle())

            Divider()
                .padding(.leading, 52)

            if isSportsExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select your sports")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.systemGray))
                        .textCase(.uppercase)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(availableSports) { sport in
                            SportSelectionCardPowerUp(
                                sport: sport,
                                isSelected: isSportSelectedByName(sport.name),
                                onTap: { toggleSportByName(sport) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)

                    if !sportsWithSkills.isEmpty {
                        Text("Skill level")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(.systemGray))
                            .textCase(.uppercase)
                            .padding(.horizontal, 16)

                        VStack(spacing: 0) {
                            ForEach(sportsWithSkills.indices, id: \.self) { index in
                                SkillLevelPicker(
                                    sport: sportsWithSkills[index].sport,
                                    skillLevel: $sportsWithSkills[index].skillLevel
                                )
                                if index < sportsWithSkills.count - 1 {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSportsExpanded)
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
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAvailabilityExpanded.toggle()
                }
            }) {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                            .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                            .frame(width: 24)

                        Text("Availability")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(ClubRalleyTheme.Colors.text)
                    }

                    Spacer()

                    if !isAvailabilityExpanded {
                        Text("\(daySelection.displayName)")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.systemGray))
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(.systemGray3))
                        .rotationEffect(.degrees(isAvailabilityExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
            }
            .buttonStyle(PlainButtonStyle())

            Divider()
                .padding(.leading, 52)

            if isAvailabilityExpanded {
                VStack(alignment: .leading, spacing: 20) {
                    // Day selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("When are you usually free?")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(.systemGray))
                            .textCase(.uppercase)

                        VStack(spacing: 8) {
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
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Best time of day")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(.systemGray))
                            .textCase(.uppercase)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(TimePreference.allCases, id: \.self) { time in
                                TimePreferenceCard(
                                    preference: time,
                                    isSelected: timePreference == time,
                                    onTap: { timePreference = time }
                                )
                            }
                        }
                    }

                    // Distance
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Travel distance")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(.systemGray))
                            .textCase(.uppercase)

                        VStack(spacing: 8) {
                            HStack {
                                Text("Up to")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.systemGray))
                                Text("\(maxDistance) miles")
                                    .font(.system(size: 14, weight: .semibold))
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
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(.systemGray2))
                                Spacer()
                                Text("100 mi")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(.systemGray2))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFunQuestionsExpanded.toggle()
                }
            }) {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                            .frame(width: 24)

                        Text("Fun Questions")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(ClubRalleyTheme.Colors.text)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(.systemGray3))
                        .rotationEffect(.degrees(isFunQuestionsExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
            }
            .buttonStyle(PlainButtonStyle())

            Divider()
                .padding(.leading, 52)

            if isFunQuestionsExpanded {
                VStack(alignment: .leading, spacing: 20) {
                    // Favorite pro team
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Favorite pro sports team")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(.systemGray))
                            .textCase(.uppercase)

                        TextField("e.g. Lakers, Patriots...", text: $favoriteProTeam)
                            .font(.system(size: 15))
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }

                    // Workout brands
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Favorite workout brands")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(.systemGray))
                            .textCase(.uppercase)

                        PowerUpTagGrid(
                            items: WorkoutBrandOptions.brands,
                            selectedItems: $workoutBrands
                        )
                    }

                    // Workout classes
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Favorite workout classes")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(.systemGray))
                            .textCase(.uppercase)

                        PowerUpTagGrid(
                            items: WorkoutClassOptions.classes,
                            selectedItems: $workoutClasses
                        )
                    }

                    // Hometown
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hometown")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(.systemGray))
                            .textCase(.uppercase)

                        TextField("City, State", text: $hometown)
                            .font(.system(size: 15))
                            .textInputAutocapitalization(.words)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }

                    // Happy hour
                    YesNoToggle(
                        question: "Would you go to happy hour after a workout?",
                        value: $wouldDoHappyHour
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(isSaving ? "Saving..." : "Done")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(ClubRalleyTheme.Colors.darkGreen)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isSaving || !isFormValid)
        .opacity(isFormValid ? 1.0 : 0.4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
