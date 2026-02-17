//
//  RalleyCreationView.swift
//  Club Ralley
//
//  Enhanced form view for creating new ralleys (pickup games).
//  Includes sport selection, time/duration, location search, and privacy settings.
//

import SwiftUI
import MapKit

// MARK: - Ralley Creation View

struct RalleyCreationView: View {
    @EnvironmentObject var ralleyManager: RalleyManager
    @Environment(\.dismiss) private var dismiss

    // Form State
    @State private var title = ""
    @State private var selectedSport: RalleySport? = nil
    @State private var selectedDate = Date().roundedToNext15Minutes()
    @State private var selectedDuration: RalleyDuration = .oneHour
    @State private var description = ""

    // Location State
    @State private var locationName = ""
    @State private var locationAddress = ""
    @State private var locationCity = "San Francisco"
    @State private var locationState = "CA"
    @State private var showingLocationSearch = false

    // Player Count State
    @State private var minPlayers: Int = 2
    @State private var maxPlayers: Int = 4
    @State private var hasMinPlayers = false

    // Privacy State
    @State private var visibility: RalleyVisibility = .anyone
    @State private var joinType: RalleyJoinType = .open

    // UI State
    @State private var isCreating = false
    @State private var showingSuccessMessage = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var canCreate: Bool {
        !title.isEmpty && selectedSport != nil && !locationName.isEmpty && maxPlayers >= 2
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    VStack(spacing: 20) {
                        sportSelectionSection
                        titleSection
                        timeSection
                        locationSection
                        playerCountSection
                        privacySection
                        descriptionSection
                        createButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(hex: "#F5F5F5"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
        .overlay(successOverlay)
        .sheet(isPresented: $showingLocationSearch) {
            LocationSearchSheet(
                locationName: $locationName,
                locationAddress: $locationAddress,
                locationCity: $locationCity,
                locationState: $locationState
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#2C4F40"))
            Text("Create a Ralley")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
            Text("Organize a pickup game and become the captain")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Sport Selection Section

    private var sportSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Sport", icon: "sportscourt.fill")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(RalleySport.supportedSports) { sport in
                        SportSelectionCard(
                            sport: sport,
                            isSelected: selectedSport?.id == sport.id,
                            onSelect: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedSport = sport
                                    if title.isEmpty { title = "\(sport.name) Pickup" }
                                }
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        )
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
        .formCard()
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Ralley Name", icon: "textformat")
            TextField("e.g. Saturday Morning Hoops", text: $title)
                .textFieldStyle(RalleyTextFieldStyle())
        }
        .formCard()
    }

    // MARK: - Time Section

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "When", icon: "calendar")

            VStack(alignment: .leading, spacing: 8) {
                Text("Date & Start Time")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                FifteenMinuteDatePicker(selection: $selectedDate, minimumDate: Date())
                    .fixedSize()
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Duration")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(RalleyDuration.allCases) { duration in
                            DurationChip(
                                duration: duration,
                                isSelected: selectedDuration == duration,
                                onSelect: { withAnimation(.spring(response: 0.3)) { selectedDuration = duration } }
                            )
                        }
                    }
                }
            }

            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#2C4F40"))
                Text("Ends at \(formattedEndTime)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "#2C4F40").opacity(0.1))
            .cornerRadius(8)
        }
        .formCard()
    }

    private var formattedEndTime: String {
        let endTime = selectedDuration.endTime(from: selectedDate)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: endTime)
    }

    // MARK: - Location Section

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Location", icon: "mappin.and.ellipse")
            Button(action: { showingLocationSearch = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#2C4F40"))
                    if locationName.isEmpty {
                        Text("Search for a location...")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(locationName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                            if !locationAddress.isEmpty {
                                Text(locationAddress)
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(16)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
            }
        }
        .formCard()
    }

    // MARK: - Player Count Section

    private var playerCountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Players", icon: "person.2.fill")

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Maximum Players")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)
                    Text("Required")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                Spacer()
                PlayerCountStepper(value: $maxPlayers, range: (hasMinPlayers ? minPlayers : 2)...50)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set Minimum Players")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)
                    Text("Cancel if not enough players join")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                Spacer()
                Toggle("", isOn: $hasMinPlayers)
                    .labelsHidden()
                    .tint(Color(hex: "#2C4F40"))
            }

            if hasMinPlayers {
                HStack {
                    Text("Minimum Players")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)
                    Spacer()
                    PlayerCountStepper(value: $minPlayers, range: 2...maxPlayers)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .formCard()
        .animation(.spring(response: 0.3), value: hasMinPlayers)
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Privacy Settings", icon: "lock.fill")

            VStack(alignment: .leading, spacing: 8) {
                Text("Who can see this Ralley?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                ForEach(RalleyVisibility.allCases, id: \.self) { option in
                    PrivacyOptionRow(
                        title: option.displayName,
                        description: option.description,
                        iconName: option.iconName,
                        isSelected: visibility == option,
                        onSelect: { visibility = option }
                    )
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("How can people join?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                ForEach(RalleyJoinType.allCases, id: \.self) { option in
                    PrivacyOptionRow(
                        title: option.displayName,
                        description: option.description,
                        iconName: option.iconName,
                        isSelected: joinType == option,
                        onSelect: { joinType = option }
                    )
                }
            }
        }
        .formCard()
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: "Description", icon: "text.alignleft")
                Spacer()
                Text("Optional")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            TextField("Add details about skill level, what to bring, etc.", text: $description, axis: .vertical)
                .textFieldStyle(RalleyTextFieldStyle())
                .lineLimit(3...6)
        }
        .formCard()
    }

    // MARK: - Create Button

    private var createButton: some View {
        Button(action: createRalley) {
            HStack(spacing: 8) {
                if isCreating {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(isCreating ? "Creating..." : "Create Ralley")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canCreate ? Color(hex: "#2C4F40") : Color.gray.opacity(0.3))
            .cornerRadius(12)
            .shadow(color: canCreate ? Color(hex: "#2C4F40").opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
        .disabled(!canCreate || isCreating)
        .padding(.top, 8)
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        Group {
            if showingSuccessMessage {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        Text("Ralley created! You're the Captain")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#2C4F40"))
                    .cornerRadius(25)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSuccessMessage)
            }
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#2C4F40"))
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
        }
    }

    // MARK: - Actions

    private func createRalley() {
        guard canCreate && !isCreating else { return }
        isCreating = true

        Task { @MainActor in
            let previousError = ralleyManager.error

            await ralleyManager.createRalley(
                title: title,
                sport: selectedSport?.name ?? "",
                dateTime: selectedDate,
                locationName: locationName,
                address: locationAddress,
                city: locationCity,
                state: locationState,
                maxPlayers: maxPlayers,
                cost: 0,
                description: description.isEmpty ? "Join us for a fun \(selectedSport?.name ?? "game")!" : description,
                requirements: "",
                visibility: visibility,
                joinType: joinType
            )

            // Check if error was set during operation
            if ralleyManager.error != nil && ralleyManager.error?.localizedDescription != previousError?.localizedDescription {
                errorMessage = "Failed to create ralley. Please check your connection and try again."
                showingError = true
                isCreating = false
                return
            }

            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showingSuccessMessage = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showingSuccessMessage = false
                dismiss()
            }
            isCreating = false
        }
    }
}

// MARK: - Date Rounding to 15-Minute Intervals

extension Date {
    /// Rounds to the nearest 15-minute mark
    func roundedToNearest15Minutes() -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: self)
        let rounded = (minute + 7) / 15 * 15
        let diff = rounded - minute
        return calendar.date(byAdding: .minute, value: diff, to: self)?.zeroSeconds() ?? self
    }

    /// Rounds up to the next 15-minute mark
    func roundedToNext15Minutes() -> Date {
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: self)
        let remainder = minute % 15
        let minutesToAdd = remainder == 0 ? 0 : 15 - remainder
        return calendar.date(byAdding: .minute, value: minutesToAdd, to: self)?.zeroSeconds() ?? self
    }

    private func zeroSeconds() -> Date {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        return calendar.date(from: comps) ?? self
    }
}
