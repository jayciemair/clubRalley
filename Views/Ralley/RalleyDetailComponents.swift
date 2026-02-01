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
            // Sport icon
            ZStack {
                Circle()
                    .fill(Color(hex: "#2C4F40").opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: sportIcon)
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }

            // Title
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
                    .foregroundColor(.gray)

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
                    .foregroundColor(.gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                Label(ralley.joinType.displayName, systemImage: ralley.joinType.iconName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }

    private var sportIcon: String {
        switch ralley.sport.lowercased() {
        case "basketball": return "basketball.fill"
        case "tennis": return "tennisball.fill"
        case "soccer", "football": return "soccerball"
        case "volleyball": return "volleyball.fill"
        case "running": return "figure.run"
        case "cycling": return "bicycle"
        case "swimming": return "figure.pool.swim"
        default: return "sportscourt.fill"
        }
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
                        .foregroundColor(.gray)
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
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            Divider()

            // Cost
            HStack(spacing: 12) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#2C4F40"))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "#2C4F40").opacity(0.1))
                    .cornerRadius(10)

                Text(ralley.cost == 0 ? "Free" : "$\(ralley.cost) per person")
                    .font(.system(size: 16, weight: .semibold))

                Spacer()
            }

            if !ralley.description.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
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
                        .foregroundColor(.gray)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Participants")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                Text("\(ralley.currentPlayers)/\(ralley.maxPlayers)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(ralley.isFull ? .red : Color(hex: "#2C4F40"))
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(ralley.isFull ? Color.red : Color(hex: "#2C4F40"))
                        .frame(width: geometry.size.width * CGFloat(ralley.currentPlayers) / CGFloat(ralley.maxPlayers), height: 8)
                }
            }
            .frame(height: 8)

            if ralley.isFull {
                Text("This ralley is full")
                    .font(.system(size: 13))
                    .foregroundColor(.red)
            } else {
                Text("\(ralley.availableSpots) spots remaining")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
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

            // Pending Requests Button
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
                            .background(Color.red)
                            .cornerRadius(12)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(16)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
            .foregroundColor(.black)

            // Complete Ralley Button
            if !ralley.isPast {
                Button(action: { showingCompletionSheet = true }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 18))

                        Text("Complete Ralley")
                            .font(.system(size: 16, weight: .medium))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(16)
                    .background(Color.gray.opacity(0.05))
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
