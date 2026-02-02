//
//  FindRalleysView.swift
//  Club Ralley
//
//  View for discovering and browsing nearby ralleys (pickup games).
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    searchBar
                    quickActionsSection
                    sportFilterSection
                    if hasActiveFilters { activeFiltersSection }
                    ralleysSection
                }
            }
            .background(Color(hex: "#F5F5F5"))
            .navigationBarHidden(true)
            .sheet(isPresented: $ralleyManager.showingCreateRalley) {
                RalleyCreationView().environmentObject(ralleyManager)
            }
            .sheet(isPresented: $showingFilterSheet) {
                RalleyFilterSheet(selectedSport: $selectedSportFilter, selectedDate: $selectedDateFilter)
            }
            .sheet(item: completingRalleyBinding) { ralley in
                RalleyCompletionSheet(ralley: ralley).environmentObject(ralleyManager)
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
            Button(action: { ralleyManager.showingCreateRalley = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 18))
                    Text("Create Ralley").font(.system(size: 16, weight: .semibold))
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

            Button(action: { showingFilterSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3").font(.system(size: 16))
                    Text("Filter").font(.system(size: 16, weight: .semibold))
                    if hasActiveFilters {
                        Circle().fill(Color(hex: "#2C4F40")).frame(width: 8, height: 8)
                    }
                }
                .foregroundColor(Color(hex: "#2C4F40"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#2C4F40"), lineWidth: 2))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Sport Filter Section

    private var sportFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                SportFilterPill(
                    name: "All",
                    iconName: "sportscourt.fill",
                    isSelected: selectedSportFilter == nil,
                    onTap: { selectedSportFilter = nil }
                )

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
            Text("Active filters:").font(.system(size: 13)).foregroundColor(.gray)

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

            if filteredRalleys.isEmpty {
                EmptyRalleysView(hasFilters: hasActiveFilters, onCreateRalley: {
                    ralleyManager.showingCreateRalley = true
                })
            } else {
                VStack(spacing: 16) {
                    ForEach(filteredRalleys) { ralley in
                        NavigationLink(destination: RalleyDetailView(ralley: ralley).environmentObject(ralleyManager)) {
                            RalleyCardView(ralley: ralley).environmentObject(ralleyManager)
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
