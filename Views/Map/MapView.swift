//
//  MapView.swift
//  Club Ralley
//
//  Main Map tab view — interactive map with venue pins, sport filters, and city selection
//

import SwiftUI
import MapKit

// MARK: - Map View

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var mapPosition: MapCameraPosition = .automatic
    @EnvironmentObject var ralleyManager: RalleyManager

    private let darkGreen = Color(hex: "#2C4F40")
    private let sage = Color(hex: "#E2E4D6")

    var body: some View {
        ZStack(alignment: .top) {
            // Map
            Map(position: $mapPosition, selection: Binding<Venue.ID?>(
                get: { viewModel.selectedVenue?.id },
                set: { newId in
                    if let id = newId,
                       let venue = viewModel.filteredVenues.first(where: { $0.id == id }) {
                        viewModel.selectVenue(venue)
                    }
                }
            )) {
                ForEach(viewModel.filteredVenues) { venue in
                    Annotation(venue.name, coordinate: venue.coordinate, anchor: .bottom) {
                        VenueMapPin(
                            venue: venue,
                            isSelected: viewModel.selectedVenue?.id == venue.id
                        )
                        .onTapGesture {
                            viewModel.selectVenue(venue)
                        }
                    }
                    .tag(venue.id)
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .ignoresSafeArea(edges: .top)

            // Header overlay
            VStack(spacing: 0) {
                headerOverlay
                sportFilterStrip
            }
        }
        .onAppear {
            updateMapPosition(for: viewModel.selectedCity)
        }
        .onChange(of: viewModel.selectedCity) { _, newCity in
            withAnimation(.easeInOut(duration: 0.5)) {
                updateMapPosition(for: newCity)
            }
        }
        .sheet(isPresented: $viewModel.showingVenueDetail) {
            if let venue = viewModel.selectedVenue {
                VenueDetailSheet(venue: venue)
                    .environmentObject(ralleyManager)
            }
        }
        .sheet(isPresented: $viewModel.showingCityPicker) {
            CityPickerSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingFindRalleys) {
            NavigationStack {
                FindRalleysView()
                    .environmentObject(ralleyManager)
            }
        }
    }

    // MARK: - Header Overlay

    private var headerOverlay: some View {
        HStack(spacing: 12) {
            // City selector button
            Button(action: { viewModel.showingCityPicker = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 16))
                    Text(viewModel.selectedCity.displayName)
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(darkGreen)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }

            Spacer()

            // Find Ralleys button
            Button(action: { viewModel.showingFindRalleys = true }) {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 18))
                    .foregroundColor(darkGreen)
                    .frame(width: 40, height: 40)
                    .background(.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
    }

    // MARK: - Sport Filter Strip

    private var sportFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" pill
                FilterPill(
                    title: "All",
                    iconName: "sportscourt.fill",
                    isSelected: viewModel.selectedSportFilter == nil,
                    action: { viewModel.filterBySport(nil) }
                )

                // Sport pills
                ForEach(RalleySport.supportedSports) { sport in
                    FilterPill(
                        title: sport.name,
                        iconName: sport.iconName,
                        isSelected: viewModel.selectedSportFilter?.lowercased() == sport.name.lowercased(),
                        action: { viewModel.filterBySport(sport.name) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers

    private func updateMapPosition(for city: MapCity) {
        mapPosition = .region(city.region)
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void

    private let darkGreen = Color(hex: "#2C4F40")
    private let sage = Color(hex: "#E2E4D6")

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : darkGreen)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? darkGreen : sage)
            .cornerRadius(20)
        }
    }
}
