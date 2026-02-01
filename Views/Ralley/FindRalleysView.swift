//
//  FindRalleysView.swift
//  Club Ralley
//
//  View for discovering and browsing nearby ralleys (pickup games).
//  Includes filters for sport, date, and visibility.
//

import SwiftUI

// MARK: - Find Ralleys View

struct FindRalleysView: View {
    @EnvironmentObject var ralleyManager: RalleyManager

    // Filter State
    @State private var selectedSportFilter: String? = nil
    @State private var selectedDateFilter: DateFilter = .all
    @State private var showingFilterSheet = false
    @State private var searchText = ""

    /// Binding for completion sheet presentation
    private var completingRalleyBinding: Binding<ClubRalley?> {
        Binding(
            get: { ralleyManager.completionManager?.completingRalley },
            set: { _ in ralleyManager.completionManager?.dismissSheet() }
        )
    }

    var filteredRalleys: [ClubRalley] {
        var ralleys = ralleyManager.ralleys

        // Filter by sport
        if let sport = selectedSportFilter {
            ralleys = ralleys.filter { $0.sport.lowercased() == sport.lowercased() }
        }

        // Filter by date
        switch selectedDateFilter {
        case .today:
            ralleys = ralleys.filter { Calendar.current.isDateInToday($0.dateTime) }
        case .thisWeek:
            let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            ralleys = ralleys.filter { $0.dateTime >= Date() && $0.dateTime <= weekFromNow }
        case .thisMonth:
            let monthFromNow = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            ralleys = ralleys.filter { $0.dateTime >= Date() && $0.dateTime <= monthFromNow }
        case .all:
            break
        }

        // Filter by search text
        if !searchText.isEmpty {
            ralleys = ralleys.filter {
                $0.title.lowercased().contains(searchText.lowercased()) ||
                $0.sport.lowercased().contains(searchText.lowercased()) ||
                $0.location.name.lowercased().contains(searchText.lowercased())
            }
        }

        // Filter out past ralleys and sort by date
        return ralleys
            .filter { !$0.isPast }
            .sorted { $0.dateTime < $1.dateTime }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Search Bar
                    searchBar

                    // Quick Actions
                    quickActionsSection

                    // Sport Filter Pills
                    sportFilterSection

                    // Active Filters Display
                    if hasActiveFilters {
                        activeFiltersSection
                    }

                    // Nearby Ralleys
                    ralleysSection
                }
            }
            .background(Color(hex: "#F5F5F5"))
            .navigationBarHidden(true)
            .sheet(isPresented: $ralleyManager.showingCreateRalley) {
                RalleyCreationView()
                    .environmentObject(ralleyManager)
            }
            .sheet(isPresented: $showingFilterSheet) {
                RalleyFilterSheet(
                    selectedSport: $selectedSportFilter,
                    selectedDate: $selectedDateFilter
                )
            }
            .sheet(item: completingRalleyBinding) { ralley in
                RalleyCompletionSheet(ralley: ralley)
                    .environmentObject(ralleyManager)
            }
            .refreshable {
                await ralleyManager.refreshRalleys()
            }
            .onAppear {
                // Start monitoring for ended ralleys
                ralleyManager.completionManager?.startMonitoring()
            }
            .onDisappear {
                // Stop monitoring when view disappears
                ralleyManager.completionManager?.stopMonitoring()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "sportscourt.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "#2C4F40"))

            VStack(alignment: .leading, spacing: 4) {
                Text("Find Ralleys")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                Text("Join pickup games near you")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.gray)

            TextField("Search ralleys...", text: $searchText)
                .font(.system(size: 16))

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 24)
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            // Create Ralley Button
            Button(action: {
                ralleyManager.showingCreateRalley = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Create Ralley")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#2C4F40"), Color(hex: "#3A6B4F")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color(hex: "#2C4F40").opacity(0.3), radius: 8, x: 0, y: 4)
            }

            // Filter Button
            Button(action: { showingFilterSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16))
                    Text("Filter")
                        .font(.system(size: 16, weight: .semibold))

                    if hasActiveFilters {
                        Circle()
                            .fill(Color(hex: "#2C4F40"))
                            .frame(width: 8, height: 8)
                    }
                }
                .foregroundColor(Color(hex: "#2C4F40"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#2C4F40"), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Sport Filter Section

    private var sportFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // All Sports
                SportFilterPill(
                    name: "All",
                    iconName: "sportscourt.fill",
                    isSelected: selectedSportFilter == nil,
                    onTap: { selectedSportFilter = nil }
                )

                // Individual Sports
                ForEach(RalleySport.supportedSports) { sport in
                    SportFilterPill(
                        name: sport.name,
                        iconName: sport.iconName,
                        isSelected: selectedSportFilter == sport.name,
                        onTap: { selectedSportFilter = sport.name }
                    )
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Active Filters Section

    private var hasActiveFilters: Bool {
        selectedSportFilter != nil || selectedDateFilter != .all
    }

    private var activeFiltersSection: some View {
        HStack(spacing: 8) {
            Text("Active filters:")
                .font(.system(size: 13))
                .foregroundColor(.gray)

            if let sport = selectedSportFilter {
                FilterTag(text: sport, onRemove: { selectedSportFilter = nil })
            }

            if selectedDateFilter != .all {
                FilterTag(text: selectedDateFilter.displayName, onRemove: { selectedDateFilter = .all })
            }

            Spacer()

            Button("Clear all") {
                selectedSportFilter = nil
                selectedDateFilter = .all
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color(hex: "#2C4F40"))
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Ralleys Section

    private var ralleysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Nearby Ralleys")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Text("\(filteredRalleys.count) found")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 24)

            // Ralley Cards
            if filteredRalleys.isEmpty {
                EmptyRalleysView(hasFilters: hasActiveFilters, onCreateRalley: {
                    ralleyManager.showingCreateRalley = true
                })
            } else {
                VStack(spacing: 16) {
                    ForEach(filteredRalleys) { ralley in
                        NavigationLink(destination: RalleyDetailView(ralley: ralley).environmentObject(ralleyManager)) {
                            RalleyCardView(ralley: ralley)
                                .environmentObject(ralleyManager)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer(minLength: 100)
        }
    }
}

// MARK: - Sport Filter Pill

struct SportFilterPill: View {
    let name: String
    let iconName: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 14))
                Text(name)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Color(hex: "#2C4F40"))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color(hex: "#2C4F40") : Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: "#2C4F40").opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Filter Tag

struct FilterTag: View {
    let text: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 13, weight: .medium))
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .foregroundColor(Color(hex: "#2C4F40"))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(hex: "#2C4F40").opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Date Filter Enum

enum DateFilter: String, CaseIterable {
    case all = "all"
    case today = "today"
    case thisWeek = "this_week"
    case thisMonth = "this_month"

    var displayName: String {
        switch self {
        case .all: return "All Dates"
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        }
    }
}

// MARK: - Ralley Card View

struct RalleyCardView: View {
    let ralley: ClubRalley
    @EnvironmentObject var ralleyManager: RalleyManager
    @State private var participationStatus: UserParticipationStatus = .notJoined
    @State private var isLoading = false

    var sportIcon: String {
        switch ralley.sport.lowercased() {
        case "basketball": return "basketball.fill"
        case "tennis": return "tennisball.fill"
        case "soccer": return "soccerball"
        case "pickleball": return "figure.pickleball"
        default: return "sportscourt.fill"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: ralley.organizer.photoURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(hex: "#2C4F40"))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(ralley.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .lineLimit(1)

                        if ralley.isCaptain {
                            Text("CAPTAIN")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "#2C4F40"))
                                .cornerRadius(4)
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text(ralley.dateTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.gray)
                }

                Spacer()

                // Sport Icon
                Image(systemName: sportIcon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }
            .padding(16)

            // Players & Location
            HStack(spacing: 16) {
                // Players count
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 14))
                    Text("\(ralley.currentPlayers)/\(ralley.maxPlayers)")
                        .font(.system(size: 14, weight: .semibold))

                    if ralley.isFull {
                        Text("FULL")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }
                .foregroundColor(Color(hex: "#2C4F40"))

                Spacer()

                // Location
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                    Text(ralley.location.name)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)

            // Privacy indicators
            HStack(spacing: 12) {
                // Visibility badge
                HStack(spacing: 4) {
                    Image(systemName: ralley.visibility.iconName)
                        .font(.system(size: 12))
                    Text(ralley.visibility.displayName)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.gray)

                // Join type badge
                HStack(spacing: 4) {
                    Image(systemName: ralley.joinType.iconName)
                        .font(.system(size: 12))
                    Text(ralley.joinType == .open ? "Open" : "Approval")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.gray)

                Spacer()

                // Cost
                Text(ralley.cost == 0 ? "FREE" : "$\(ralley.cost)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#2C4F40"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#2C4F40").opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Action Button
            actionButton
                .padding(16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .task {
            await checkUserParticipationStatus()
        }
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        if ralley.isCaptain {
            // Captain view - show manage button
            Button(action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                    Text("Manage Ralley")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#2C4F40"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(hex: "#2C4F40").opacity(0.1))
                .cornerRadius(10)
            }
        } else if ralley.isFull && participationStatus != .joined {
            // Full ralley
            Button(action: {}) {
                Text("Ralley Full")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
            .disabled(true)
        } else {
            // Join/Request button based on status and join type
            Button(action: { Task { await handleJoinAction() } }) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(buttonText)
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(buttonTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(buttonBackground)
                .cornerRadius(10)
            }
            .disabled(isLoading || participationStatus == .joined)
        }
    }

    private var buttonText: String {
        switch participationStatus {
        case .notJoined:
            return ralley.joinType == .open ? "Join Ralley" : "Request to Join"
        case .pending:
            return "Request Pending"
        case .joined:
            return "Joined"
        }
    }

    private var buttonTextColor: Color {
        switch participationStatus {
        case .notJoined:
            return .white
        case .pending:
            return .orange
        case .joined:
            return Color(hex: "#2C4F40")
        }
    }

    private var buttonBackground: Color {
        switch participationStatus {
        case .notJoined:
            return Color(hex: "#2C4F40")
        case .pending:
            return Color.orange.opacity(0.2)
        case .joined:
            return Color(hex: "#2C4F40").opacity(0.1)
        }
    }

    // MARK: - Actions

    private func checkUserParticipationStatus() async {
        if let manager = ralleyManager.participationManager {
            participationStatus = await manager.getParticipationStatus(for: ralley.id)
        }
    }

    private func handleJoinAction() async {
        guard participationStatus == .notJoined else { return }

        isLoading = true

        if ralley.joinType == .open {
            await ralleyManager.joinRalley(ralley.id)
        } else {
            await ralleyManager.requestToJoin(ralley.id)
        }

        await checkUserParticipationStatus()
        isLoading = false
    }
}

// MARK: - Empty Ralleys View

struct EmptyRalleysView: View {
    var hasFilters: Bool = false
    var onCreateRalley: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasFilters ? "line.3.horizontal.decrease.circle" : "sportscourt")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))

            Text(hasFilters ? "No matching ralleys" : "No ralleys nearby")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)

            Text(hasFilters ? "Try adjusting your filters or search" : "Be the first to create a pickup game in your area!")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if !hasFilters, let onCreateRalley = onCreateRalley {
                Button(action: onCreateRalley) {
                    Text("Create Ralley")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#2C4F40"))
                        .cornerRadius(12)
                }
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Ralley Filter Sheet

struct RalleyFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSport: String?
    @Binding var selectedDate: DateFilter

    var body: some View {
        NavigationStack {
            List {
                // Sport Section
                Section("Sport") {
                    Button(action: { selectedSport = nil }) {
                        HStack {
                            Text("All Sports")
                            Spacer()
                            if selectedSport == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "#2C4F40"))
                            }
                        }
                    }
                    .foregroundColor(.primary)

                    ForEach(RalleySport.supportedSports) { sport in
                        Button(action: { selectedSport = sport.name }) {
                            HStack {
                                Image(systemName: sport.iconName)
                                    .foregroundColor(Color(hex: "#2C4F40"))
                                Text(sport.name)
                                Spacer()
                                if selectedSport == sport.name {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "#2C4F40"))
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                // Date Section
                Section("Date") {
                    ForEach(DateFilter.allCases, id: \.self) { filter in
                        Button(action: { selectedDate = filter }) {
                            HStack {
                                Text(filter.displayName)
                                Spacer()
                                if selectedDate == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "#2C4F40"))
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Filter Ralleys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedSport = nil
                        selectedDate = .all
                    }
                    .foregroundColor(Color(hex: "#2C4F40"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
    }
}
