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
    @State private var selectedDate = Date()
    @State private var selectedDuration: RalleyDuration = .oneHour
    @State private var description = ""

    // Location State
    @State private var locationName = ""
    @State private var locationAddress = ""
    @State private var locationCity = "San Francisco"
    @State private var locationState = "CA"
    @State private var showingLocationSearch = false
    @State private var locationSearchResults: [LocationSuggestion] = []

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
    @State private var showingSportPicker = false
    @State private var showingDurationPicker = false

    var canCreate: Bool {
        !title.isEmpty && selectedSport != nil && !locationName.isEmpty && maxPlayers >= 2
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    VStack(spacing: 20) {
                        // Sport Selection
                        sportSelectionSection

                        // Title
                        titleSection

                        // Time & Duration
                        timeSection

                        // Location
                        locationSection

                        // Player Count
                        playerCountSection

                        // Privacy Settings
                        privacySection

                        // Description (Optional)
                        descriptionSection

                        // Create Button
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
                    Button("Cancel") {
                        dismiss()
                    }
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
                                    // Auto-fill title if empty
                                    if title.isEmpty {
                                        title = "\(sport.name) Pickup"
                                    }
                                }
                                let feedback = UIImpactFeedbackGenerator(style: .light)
                                feedback.impactOccurred()
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

            // Date Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Date & Start Time")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)

                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(Color(hex: "#2C4F40"))
            }

            Divider()

            // Duration Picker
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
                                onSelect: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedDuration = duration
                                    }
                                }
                            )
                        }
                    }
                }
            }

            // End time display
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

            // Max Players (Required)
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

                PlayerCountStepper(
                    value: $maxPlayers,
                    range: (hasMinPlayers ? minPlayers : 2)...50
                )
            }

            Divider()

            // Min Players Toggle
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

            // Min Players Stepper (if enabled)
            if hasMinPlayers {
                HStack {
                    Text("Minimum Players")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)

                    Spacer()

                    PlayerCountStepper(
                        value: $minPlayers,
                        range: 2...maxPlayers
                    )
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

            // Visibility Picker
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

            // Join Type Picker
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
            .background(
                canCreate
                    ? Color(hex: "#2C4F40")
                    : Color.gray.opacity(0.3)
            )
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

            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            showingSuccessMessage = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showingSuccessMessage = false
                dismiss()
            }

            isCreating = false
        }
    }
}

// MARK: - Supporting Views

struct SportSelectionCard: View {
    let sport: RalleySport
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Image(systemName: sport.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : Color(hex: "#2C4F40"))
                    .frame(width: 56, height: 56)
                    .background(
                        isSelected
                            ? Color(hex: "#2C4F40")
                            : Color(hex: "#2C4F40").opacity(0.1)
                    )
                    .cornerRadius(16)

                Text(sport.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "#2C4F40") : .gray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                isSelected
                    ? Color(hex: "#2C4F40").opacity(0.1)
                    : Color.clear
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "#2C4F40") : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct DurationChip: View {
    let duration: RalleyDuration
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(duration.shortName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color(hex: "#2C4F40"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    isSelected
                        ? Color(hex: "#2C4F40")
                        : Color(hex: "#2C4F40").opacity(0.1)
                )
                .cornerRadius(20)
        }
    }
}

struct PlayerCountStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                if value > range.lowerBound {
                    value -= 1
                    let feedback = UIImpactFeedbackGenerator(style: .light)
                    feedback.impactOccurred()
                }
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(value > range.lowerBound ? Color(hex: "#2C4F40") : .gray.opacity(0.3))
            }
            .disabled(value <= range.lowerBound)

            Text("\(value)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#2C4F40"))
                .frame(minWidth: 32)

            Button(action: {
                if value < range.upperBound {
                    value += 1
                    let feedback = UIImpactFeedbackGenerator(style: .light)
                    feedback.impactOccurred()
                }
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(value < range.upperBound ? Color(hex: "#2C4F40") : .gray.opacity(0.3))
            }
            .disabled(value >= range.upperBound)
        }
    }
}

struct PrivacyOptionRow: View {
    let title: String
    let description: String
    let iconName: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : Color(hex: "#2C4F40"))
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Color(hex: "#2C4F40") : Color.gray.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
            .padding(12)
            .background(isSelected ? Color(hex: "#2C4F40").opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

// MARK: - Location Search Sheet

struct LocationSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var locationName: String
    @Binding var locationAddress: String
    @Binding var locationCity: String
    @Binding var locationState: String

    @State private var searchText = ""
    @State private var searchResults: [LocationSuggestion] = []
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)

                    TextField("Search parks, courts, fields...", text: $searchText)
                        .font(.system(size: 16))
                        .autocorrectionDisabled()
                        .onChange(of: searchText) { _, newValue in
                            searchLocations(query: newValue)
                        }

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding()

                Divider()

                // Results List
                if isSearching {
                    ProgressView()
                        .padding(.top, 40)
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "mappin.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No locations found")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 60)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Manual Entry Option
                            Button(action: {
                                locationName = searchText.isEmpty ? "Custom Location" : searchText
                                locationAddress = ""
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(hex: "#2C4F40"))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Enter custom location")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.black)
                                        Text("Type any address or place name")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()
                                }
                                .padding(16)
                            }

                            Divider().padding(.leading, 48)

                            // Search Results
                            ForEach(searchResults) { location in
                                Button(action: {
                                    selectLocation(location)
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: location.iconName)
                                            .font(.system(size: 18))
                                            .foregroundColor(Color(hex: "#2C4F40"))
                                            .frame(width: 36, height: 36)
                                            .background(Color(hex: "#2C4F40").opacity(0.1))
                                            .cornerRadius(8)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(location.name)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.black)
                                            Text(location.address)
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray)
                                        }

                                        Spacer()
                                    }
                                    .padding(16)
                                }

                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Find Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
        .onAppear {
            loadNearbyLocations()
        }
    }

    private func searchLocations(query: String) {
        guard !query.isEmpty else {
            loadNearbyLocations()
            return
        }

        isSearching = true

        // Simulate search with mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            searchResults = LocationSuggestion.mockSearchResults(for: query)
            isSearching = false
        }
    }

    private func loadNearbyLocations() {
        searchResults = LocationSuggestion.mockNearbyLocations()
    }

    private func selectLocation(_ location: LocationSuggestion) {
        locationName = location.name
        locationAddress = location.address
        locationCity = location.city
        locationState = location.state
        dismiss()
    }
}

// MARK: - Location Suggestion Model

struct LocationSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let city: String
    let state: String
    let type: LocationType
    let latitude: Double
    let longitude: Double

    var iconName: String {
        type.iconName
    }

    enum LocationType {
        case park
        case court
        case field
        case gym
        case other

        var iconName: String {
            switch self {
            case .park: return "leaf.fill"
            case .court: return "sportscourt.fill"
            case .field: return "figure.soccer"
            case .gym: return "dumbbell.fill"
            case .other: return "mappin.circle.fill"
            }
        }
    }

    static func mockNearbyLocations() -> [LocationSuggestion] {
        [
            LocationSuggestion(name: "Golden Gate Park Tennis Courts", address: "501 Stanyan St", city: "San Francisco", state: "CA", type: .court, latitude: 37.7694, longitude: -122.4533),
            LocationSuggestion(name: "Dolores Park", address: "19th & Dolores St", city: "San Francisco", state: "CA", type: .park, latitude: 37.7596, longitude: -122.4269),
            LocationSuggestion(name: "Mission Rec Center", address: "745 Treat Ave", city: "San Francisco", state: "CA", type: .gym, latitude: 37.7558, longitude: -122.4145),
            LocationSuggestion(name: "Potrero Hill Rec Center", address: "801 Arkansas St", city: "San Francisco", state: "CA", type: .court, latitude: 37.7559, longitude: -122.3961),
            LocationSuggestion(name: "Marina Green", address: "Marina Blvd", city: "San Francisco", state: "CA", type: .field, latitude: 37.8066, longitude: -122.4374)
        ]
    }

    static func mockSearchResults(for query: String) -> [LocationSuggestion] {
        let allLocations = mockNearbyLocations() + [
            LocationSuggestion(name: "Crissy Field", address: "Mason St & Halleck St", city: "San Francisco", state: "CA", type: .field, latitude: 37.8038, longitude: -122.4658),
            LocationSuggestion(name: "Kezar Pavilion", address: "755 Stanyan St", city: "San Francisco", state: "CA", type: .gym, latitude: 37.7668, longitude: -122.4537),
            LocationSuggestion(name: "Ocean Beach", address: "Great Highway", city: "San Francisco", state: "CA", type: .other, latitude: 37.7593, longitude: -122.5107)
        ]

        return allLocations.filter {
            $0.name.lowercased().contains(query.lowercased()) ||
            $0.address.lowercased().contains(query.lowercased())
        }
    }
}

// MARK: - Styles & Modifiers

struct RalleyTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
    }
}

extension View {
    func formCard() -> some View {
        self
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Custom Text Field Style (for backwards compatibility)

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
}
