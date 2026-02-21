//
//  FindRalleysView.swift
//  Club Ralley
//
//  View for discovering and browsing nearby ralleys (pickup games).
//

import SwiftUI
import MapKit

// MARK: - Find Ralleys View

struct FindRalleysView: View {
    @EnvironmentObject var ralleyManager: RalleyManager
    @EnvironmentObject var postManager: PostManager
    @StateObject private var mapViewModel = MapViewModel()

    // Filter State
    @State private var selectedSportFilter: String? = nil
    @State private var selectedDateFilter: DateFilter = .all
    @State private var showingFilterSheet = false
    @State private var searchText = ""

    private var completingRalleyBinding: Binding<ClubRalley?> {
        Binding(
            get: { ralleyManager.completionManager?.completingRalley },
            set: { _ in ralleyManager.completionManager?.dismissSheet() }
        )
    }

    var filteredRalleys: [ClubRalley] {
        var ralleys = ralleyManager.ralleys

        if let sport = selectedSportFilter {
            ralleys = ralleys.filter { $0.sport.lowercased() == sport.lowercased() }
        }

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

        if !searchText.isEmpty {
            ralleys = ralleys.filter {
                $0.title.lowercased().contains(searchText.lowercased()) ||
                $0.sport.lowercased().contains(searchText.lowercased()) ||
                $0.location.name.lowercased().contains(searchText.lowercased())
            }
        }

        return ralleys.filter { !$0.isPast }.sorted { $0.dateTime < $1.dateTime }
    }

    private var hasActiveFilters: Bool {
        selectedSportFilter != nil || selectedDateFilter != .all
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                actionButtons
                if hasActiveFilters { activeFiltersSection }
                sectionHeader
                ralleysSection
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .sheet(isPresented: $ralleyManager.showingCreateRalley) {
            RalleyCreationView()
                .environmentObject(ralleyManager)
                .environmentObject(postManager)
        }
        .sheet(isPresented: $showingFilterSheet) {
            RalleyFilterSheet(selectedSport: $selectedSportFilter, selectedDate: $selectedDateFilter)
        }
        .sheet(item: completingRalleyBinding) { ralley in
            RalleyCompletionSheet(ralley: ralley).environmentObject(ralleyManager)
        }
        .sheet(isPresented: $mapViewModel.showingVenueDetail) {
            if let venue = mapViewModel.selectedVenue {
                VenueDetailSheet(venue: venue)
                    .environmentObject(ralleyManager)
            }
        }
        .refreshable {
            await ralleyManager.refreshRalleys()
        }
        .onAppear {
            ralleyManager.completionManager?.startMonitoring()
        }
        .onDisappear {
            ralleyManager.completionManager?.stopMonitoring()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Find Ralleys")
                .font(.custom("Chillax-Semibold", size: 34))
                .foregroundColor(Color(hex: "#2C4F40"))

            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#5a7268"))
                Text(mapViewModel.selectedCity.displayName)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#5a7268"))
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 16)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 10) {
            // Create Ralley — solid primary capsule
            Button(action: { ralleyManager.showingCreateRalley = true }) {
                HStack(spacing: 7) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Create Ralley")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#2C4F40"))
                .clipShape(Capsule())
            }

            // Filter — solid green capsule
            Button(action: { showingFilterSheet = true }) {
                HStack(spacing: 7) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Filter")
                        .font(.system(size: 15, weight: .semibold))
                    if hasActiveFilters {
                        Circle().fill(Color.white).frame(width: 6, height: 6)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#2C4F40"))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
    }

    // MARK: - Active Filters

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
        .padding(.horizontal, 22)
        .padding(.top, 16)
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Text("Nearby Ralleys")
                .font(.custom("Chillax-Semibold", size: 18))
                .foregroundColor(Color(hex: "#2C4F40"))
            Spacer()
            if !ralleyManager.isLoading {
                Text("\(filteredRalleys.count) found \u{203A}")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#7a9088"))
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 22)
        .padding(.bottom, 10)
    }

    // MARK: - Ralleys Section

    private var ralleysSection: some View {
        Group {
            if ralleyManager.isLoading && ralleyManager.ralleys.isEmpty {
                ralleysLoadingView
            } else if let error = ralleyManager.error, ralleyManager.ralleys.isEmpty {
                ralleysErrorView(error: error)
            } else if filteredRalleys.isEmpty && !hasActiveFilters {
                NoNearbyRalleysView(onCreateRalley: {
                    ralleyManager.showingCreateRalley = true
                })
            } else if filteredRalleys.isEmpty {
                EmptyRalleysView(hasFilters: true, onCreateRalley: {
                    ralleyManager.showingCreateRalley = true
                })
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredRalleys) { ralley in
                        NavigationLink(destination: RalleyDetailView(ralley: ralley).environmentObject(ralleyManager)) {
                            RalleyCardView(ralley: ralley).environmentObject(ralleyManager)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onAppear {
                            if ralley.id == filteredRalleys.last?.id && ralleyManager.hasMoreRalleys {
                                Task {
                                    await ralleyManager.loadMoreRalleys()
                                }
                            }
                        }
                    }

                    if ralleyManager.isLoadingMore {
                        ProgressView()
                            .padding(.vertical, 16)
                    }
                }
                .padding(.horizontal, 22)
            }

            Spacer(minLength: 100)
        }
    }

    // MARK: - Loading View

    private var ralleysLoadingView: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                RalleySkeletonView()
            }
        }
        .padding(.horizontal, 22)
    }

    // MARK: - Error View

    private func ralleysErrorView(error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))

            Text("Unable to load ralleys")
                .font(.system(size: 20, weight: .semibold))
                .fontDesign(.rounded)
                .foregroundColor(Color(hex: "#2C4F40"))

            Text("Check your internet connection and try again")
                .font(.system(size: 15))
                .fontDesign(.rounded)
                .foregroundColor(Color(hex: "#7a9088"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                Task {
                    await ralleyManager.refreshRalleys()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 16, weight: .semibold))
                .fontDesign(.rounded)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: "#2C4F40"))
                .clipShape(Capsule())
            }
        }
        .padding(.top, 40)
    }
}

// MARK: - Ralley Skeleton View

struct RalleySkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 24)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 90, height: 14)
                Spacer()
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 32)
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.25))
                .frame(height: 18)
                .frame(maxWidth: 180)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 200, height: 14)

            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 60, height: 12)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 120, height: 12)
            }

            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.15))
                .frame(height: 4)

            HStack(spacing: 8) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 26, height: 26)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 130, height: 12)
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .opacity(isAnimating ? 0.6 : 1.0)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
