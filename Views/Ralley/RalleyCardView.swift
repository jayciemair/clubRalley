//
//  RalleyCardView.swift
//  Club Ralley
//
//  Card view for displaying ralley information
//

import SwiftUI

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
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color(hex: "#2C4F40"))
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
                        Image(systemName: "clock.fill").font(.system(size: 12))
                        Text(ralley.dateTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: sportIcon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }
            .padding(16)

            // Players & Location
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill").font(.system(size: 14))
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

                HStack(spacing: 4) {
                    Image(systemName: "location.fill").font(.system(size: 12))
                    Text(ralley.location.name)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)

            // Privacy indicators
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: ralley.visibility.iconName).font(.system(size: 12))
                    Text(ralley.visibility.displayName).font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.gray)

                HStack(spacing: 4) {
                    Image(systemName: ralley.joinType.iconName).font(.system(size: 12))
                    Text(ralley.joinType == .open ? "Open" : "Approval")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.gray)

                Spacer()

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
            actionButton.padding(16)
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
        case .notJoined: return .white
        case .pending: return .orange
        case .joined: return Color(hex: "#2C4F40")
        }
    }

    private var buttonBackground: Color {
        switch participationStatus {
        case .notJoined: return Color(hex: "#2C4F40")
        case .pending: return Color.orange.opacity(0.2)
        case .joined: return Color(hex: "#2C4F40").opacity(0.1)
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
