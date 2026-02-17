//
//  RalleyDetailComponents.swift
//  Club Ralley
//
//  Reusable components for RalleyDetailView.
//

import SwiftUI

// MARK: - Ralley Detail Header

struct RalleyDetailHeader: View {
    let ralley: ClubRalley

    var body: some View {
        VStack(spacing: 16) {
            // Sport icon — matches actual sport
            ZStack {
                Circle()
                    .fill(Color(hex: "#2C4F40").opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: SportIconMapper.iconName(for: ralley.sport))
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }

            Text(ralley.title)
                .font(.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)

            // Organizer info
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: ralley.organizer.photoURL)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())

                Text("Hosted by \(ralley.organizer.name)")
                    .font(.system(size: 15))
                    .foregroundColor(Color.black.opacity(0.5))

                if ralley.isCaptain {
                    Text("(You)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }

            // Privacy badges
            HStack(spacing: 8) {
                Label(ralley.visibility.displayName, systemImage: ralley.visibility.iconName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.black.opacity(0.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#E2E4D6"))
                    .cornerRadius(12)

                Label(ralley.joinType.displayName, systemImage: ralley.joinType.iconName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.black.opacity(0.5))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#E2E4D6"))
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
}

// MARK: - Ralley Info Section

struct RalleyInfoSection: View {
    let ralley: ClubRalley

    var body: some View {
        VStack(spacing: 16) {
            // Date & Time
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#2C4F40"))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "#2C4F40").opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDate)
                        .font(.system(size: 16, weight: .semibold))
                    Text(formattedTime)
                        .font(.system(size: 14))
                        .foregroundColor(Color.black.opacity(0.5))
                }

                Spacer()
            }

            Divider()

            // Location
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#2C4F40"))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "#2C4F40").opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(ralley.location.name)
                        .font(.system(size: 16, weight: .semibold))
                    Text(ralley.location.shortAddress)
                        .font(.system(size: 14))
                        .foregroundColor(Color.black.opacity(0.5))
                }

                Spacer()
            }

            if !ralley.description.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.black.opacity(0.5))
                    Text(ralley.description)
                        .font(.system(size: 15))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !ralley.requirements.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Requirements")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.black.opacity(0.5))
                    Text(ralley.requirements)
                        .font(.system(size: 15))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: ralley.dateTime)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: ralley.dateTime)
    }
}

// MARK: - Ralley Participants Section

struct RalleyParticipantsSection: View {
    let ralley: ClubRalley
    let attendees: [RalleyAttendee]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Participants")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Text("\(ralley.currentPlayers)/\(ralley.maxPlayers)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(ralley.isFull ? Color(hex: "#2C4F40") : Color(hex: "#2C4F40"))
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#E2E4D6"))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#2C4F40"))
                        .frame(width: geometry.size.width * CGFloat(ralley.currentPlayers) / CGFloat(max(ralley.maxPlayers, 1)), height: 8)
                }
            }
            .frame(height: 8)

            if ralley.isFull {
                Text("This ralley is full")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#2C4F40"))
            } else {
                Text("\(ralley.availableSpots) spots remaining")
                    .font(.system(size: 13))
                    .foregroundColor(Color.black.opacity(0.5))
            }

            // Attendee list with photo + name
            if !attendees.isEmpty {
                Divider().padding(.top, 4)

                VStack(spacing: 10) {
                    ForEach(attendees) { attendee in
                        HStack(spacing: 10) {
                            AsyncImage(url: URL(string: attendee.photoURL ?? "")) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color(hex: "#2C4F40"))
                                    .overlay(
                                        Text(String(attendee.name.prefix(1)).uppercased())
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 1) {
                                Text(attendee.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                                Text("@\(attendee.username)")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.black.opacity(0.5))
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

// MARK: - Ralley Captain Controls

struct RalleyCaptainControls: View {
    let ralley: ClubRalley
    let pendingRequests: [PendingJoinRequest]
    @Binding var showingPendingRequests: Bool
    @Binding var showingCompletionSheet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Captain Controls")
                .font(.system(size: 18, weight: .semibold))

            // Only show Pending Requests if ralley requires approval
            if ralley.requiresApproval {
                Button(action: { showingPendingRequests = true }) {
                    HStack {
                        Image(systemName: "person.badge.clock")
                            .font(.system(size: 18))

                        Text("Pending Requests")
                            .font(.system(size: 16, weight: .medium))

                        Spacer()

                        if pendingRequests.count > 0 {
                            Text("\(pendingRequests.count)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#2C4F40"))
                                .cornerRadius(12)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color.black.opacity(0.3))
                    }
                    .padding(16)
                    .background(Color(hex: "#E2E4D6").opacity(0.3))
                    .cornerRadius(12)
                }
                .foregroundColor(.black)
            }

            // Complete Ralley — only show after ralley end time has passed
            if ralley.isPast {
                Button(action: { showingCompletionSheet = true }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 18))

                        Text("Complete Ralley")
                            .font(.system(size: 16, weight: .medium))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Color.black.opacity(0.3))
                    }
                    .padding(16)
                    .background(Color(hex: "#E2E4D6").opacity(0.3))
                    .cornerRadius(12)
                }
                .foregroundColor(.black)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}
