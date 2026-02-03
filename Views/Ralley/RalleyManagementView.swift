//
//  RalleyManagementView.swift
//  Club Ralley
//
//  View for managing/editing a ralley (captain only)
//

import SwiftUI

struct RalleyManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var ralleyManager: RalleyManager

    let ralley: ClubRalley

    @State private var title: String
    @State private var description: String
    @State private var dateTime: Date
    @State private var locationName: String
    @State private var locationAddress: String
    @State private var locationCity: String
    @State private var locationState: String
    @State private var maxPlayers: Int
    @State private var visibility: RalleyVisibility
    @State private var joinType: RalleyJoinType

    @State private var isLoading = false
    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""

    init(ralley: ClubRalley) {
        self.ralley = ralley
        _title = State(initialValue: ralley.title)
        _description = State(initialValue: ralley.description)
        _dateTime = State(initialValue: ralley.dateTime)
        _locationName = State(initialValue: ralley.location.name)
        _locationAddress = State(initialValue: ralley.location.address)
        _locationCity = State(initialValue: ralley.location.city)
        _locationState = State(initialValue: ralley.location.state)
        _maxPlayers = State(initialValue: ralley.maxPlayers)
        _visibility = State(initialValue: ralley.visibility)
        _joinType = State(initialValue: ralley.joinType)
    }

    var body: some View {
        NavigationStack {
            formContent
                .navigationTitle("Manage Ralley")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .disabled(isLoading)
                .overlay { loadingOverlay }
                .alert("Cancel Ralley?", isPresented: $showingDeleteConfirmation) {
                    deleteConfirmationButtons
                } message: {
                    Text("This will permanently cancel the ralley and notify all \(ralley.currentPlayers) participant(s). This action cannot be undone.")
                }
                .alert("Error", isPresented: $showingError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage)
                }
        }
    }

    // MARK: - View Components

    private var formContent: some View {
        Form {
            basicInfoSection
            dateTimeSection
            locationSection
            capacitySection
            privacySection
            dangerZoneSection
        }
    }

    private var basicInfoSection: some View {
        Section("Basic Info") {
            TextField("Title", text: $title)
            TextField("Description", text: $description, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var dateTimeSection: some View {
        Section("Date & Time") {
            DatePicker("When", selection: $dateTime, in: Date()...)
        }
    }

    private var locationSection: some View {
        Section("Location") {
            TextField("Venue Name", text: $locationName)
            TextField("Address", text: $locationAddress)
            HStack {
                TextField("City", text: $locationCity)
                TextField("State", text: $locationState)
                    .frame(width: 60)
            }
        }
    }

    private var capacitySection: some View {
        Section("Capacity") {
            Stepper("Max Players: \(maxPlayers)", value: $maxPlayers, in: ralley.currentPlayers...50)
            Text("Current players: \(ralley.currentPlayers)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }

    private var privacySection: some View {
        Section("Privacy Settings") {
            Picker("Who Can See", selection: $visibility) {
                Text("Anyone").tag(RalleyVisibility.anyone)
                Text("Mutual Friends").tag(RalleyVisibility.mutualFriends)
                Text("Friends Only").tag(RalleyVisibility.friends)
            }

            Picker("How to Join", selection: $joinType) {
                Text("Open (Anyone Can Join)").tag(RalleyJoinType.open)
                Text("Approval Required").tag(RalleyJoinType.approvalRequired)
            }
        }
    }

    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Cancel Ralley")
                }
            }
        } header: {
            Text("Danger Zone")
        } footer: {
            Text("Canceling will notify all participants and remove the ralley.")
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") {
                Task { await saveChanges() }
            }
            .fontWeight(.semibold)
            .disabled(!hasChanges || isLoading)
        }
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if isLoading {
            ProgressView()
                .scaleEffect(1.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.2))
        }
    }

    @ViewBuilder
    private var deleteConfirmationButtons: some View {
        Button("Keep Ralley", role: .cancel) { }
        Button("Cancel Ralley", role: .destructive) {
            Task { await deleteRalley() }
        }
    }

    // MARK: - Computed Properties

    private var hasChanges: Bool {
        title != ralley.title ||
        description != ralley.description ||
        dateTime != ralley.dateTime ||
        locationName != ralley.location.name ||
        locationAddress != ralley.location.address ||
        locationCity != ralley.location.city ||
        locationState != ralley.location.state ||
        maxPlayers != ralley.maxPlayers ||
        visibility != ralley.visibility ||
        joinType != ralley.joinType
    }

    // MARK: - Actions

    private func saveChanges() async {
        guard hasChanges else { return }
        isLoading = true

        let updatedRalley = ClubRalley(
            id: ralley.id,
            title: title,
            sport: ralley.sport,
            description: description,
            organizer: ralley.organizer,
            dateTime: dateTime,
            location: ClubRalleyLocation(
                name: locationName,
                address: locationAddress,
                city: locationCity,
                state: locationState,
                latitude: ralley.location.latitude,
                longitude: ralley.location.longitude
            ),
            maxPlayers: maxPlayers,
            currentPlayers: ralley.currentPlayers,
            cost: ralley.cost,
            requirements: ralley.requirements,
            isPublic: visibility == .anyone,
            createdAt: ralley.createdAt,
            isActive: ralley.isActive,
            visibility: visibility,
            joinType: joinType,
            isCaptain: ralley.isCaptain,
            chatId: ralley.chatId,
            pendingRequestsCount: ralley.pendingRequestsCount,
            durationMinutes: ralley.durationMinutes
        )

        do {
            try await ralleyManager.updateRalley(updatedRalley)
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to save changes. Please try again."
                showingError = true
            }
        }
    }

    private func deleteRalley() async {
        isLoading = true

        do {
            try await ralleyManager.deleteRalley(ralley.id)
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Failed to cancel ralley. Please try again."
                showingError = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RalleyManagementView(ralley: ClubRalley(
        id: UUID(),
        title: "Sunday Hoops",
        sport: "Basketball",
        description: "Friendly pickup game",
        organizer: ClubRalleyOrganizer(id: UUID(), name: "John Doe", username: "@johnd", photoURL: ""),
        dateTime: Date().addingTimeInterval(86400),
        location: ClubRalleyLocation(name: "Central Park", address: "123 Main St", city: "Chicago", state: "IL", latitude: 41.8781, longitude: -87.6298),
        maxPlayers: 10,
        currentPlayers: 3,
        cost: 0,
        requirements: "",
        isPublic: true,
        isCaptain: true
    ))
    .environmentObject(RalleyManager())
}
