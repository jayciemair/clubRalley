//
//  VenueDetailSheet.swift
//  Club Ralley
//
//  Bottom sheet showing venue details when a map pin is tapped
//

import SwiftUI

// MARK: - Venue Detail Sheet

struct VenueDetailSheet: View {
    let venue: Venue
    @EnvironmentObject var ralleyManager: RalleyManager
    @Environment(\.dismiss) private var dismiss

    private let darkGreen = Color(hex: "#2C4F40")
    private let sage = Color(hex: "#E2E4D6")

    /// Ralleys at this venue that are upcoming or active
    private var venueRalleys: [ClubRalley] {
        ralleyManager.ralleys.filter { ralley in
            ralley.location.name.lowercased() == venue.name.lowercased() && !ralley.isPast
        }
        .sorted { $0.dateTime < $1.dateTime }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Venue name + type badge
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(venue.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)

                            // Type badge
                            HStack(spacing: 4) {
                                Image(systemName: venue.typeIconName)
                                    .font(.system(size: 12))
                                Text(venue.typeBadge)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(darkGreen)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(sage)
                            .cornerRadius(8)
                        }

                        Spacer()

                        // Open/Closed status
                        HStack(spacing: 4) {
                            Circle()
                                .fill(venue.isOpen ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(venue.isOpen ? "Open" : "Closed")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(venue.isOpen ? .green : .red)
                        }
                        .padding(.top, 4)
                    }

                    // Address row
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(darkGreen)

                        Text(venue.address)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)

                        if !venue.city.isEmpty {
                            Text("\(venue.city), \(venue.state)")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Sports pills
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sports")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(ClubRalleyTheme.Colors.darkGreen)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(venue.sports, id: \.self) { sport in
                                    HStack(spacing: 4) {
                                        Image(systemName: SportIconMapper.iconName(for: sport))
                                            .font(.system(size: 13))
                                        Text(sport)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(darkGreen)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(sage)
                                    .cornerRadius(20)
                                }
                            }
                        }
                    }

                    // Upcoming Ralleys at this venue
                    venueRalleysSection

                    // Get Directions button
                    Button(action: openDirections) {
                        HStack {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                .font(.system(size: 16))
                            Text("Get Directions")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(darkGreen)
                        .cornerRadius(12)
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Venue Ralleys Section

    @ViewBuilder
    private var venueRalleysSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Upcoming Ralleys")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                Spacer()
                if !venueRalleys.isEmpty {
                    Text("\(venueRalleys.count)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            if venueRalleys.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "sportscourt")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    Text("No upcoming ralleys here yet")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.06))
                .cornerRadius(12)
            } else {
                ForEach(venueRalleys) { ralley in
                    NavigationLink(destination: RalleyDetailView(ralley: ralley).environmentObject(ralleyManager)) {
                        VenueRalleyRow(ralley: ralley)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - Actions

    private func openDirections() {
        let coordinate = venue.coordinate
        let urlString = "http://maps.apple.com/?daddr=\(coordinate.latitude),\(coordinate.longitude)&dirflg=d"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Venue Ralley Row

/// Compact ralley card for display inside the venue detail sheet
struct VenueRalleyRow: View {
    let ralley: ClubRalley

    private let darkGreen = Color(hex: "#2C4F40")
    private let sage = Color(hex: "#E2E4D6")

    var body: some View {
        HStack(spacing: 12) {
            // Organizer photo
            AsyncImage(url: URL(string: ralley.organizer.photoURL)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle().fill(darkGreen.opacity(0.2))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            // Ralley info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(ralley.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                        .lineLimit(1)

                    // Sport pill
                    HStack(spacing: 2) {
                        Image(systemName: SportIconMapper.iconName(for: ralley.sport))
                            .font(.system(size: 9))
                        Text(ralley.sport)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(darkGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(sage)
                    .cornerRadius(6)
                }

                HStack(spacing: 12) {
                    // Time
                    HStack(spacing: 3) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text(ralley.dateTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.gray)

                    // Players
                    HStack(spacing: 3) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10))
                        Text("\(ralley.currentPlayers)/\(ralley.maxPlayers)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(ralley.isFull ? .red : darkGreen)
                }
            }

            Spacer()

            // Status indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
