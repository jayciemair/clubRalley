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
    @State private var showingManagement = false

    var body: some View {
        VStack(spacing: 0) {
            // Sport type pill
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: SportIconMapper.iconName(for: ralley.sport))
                        .font(.system(size: 12))
                    Text(ralley.sport)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(Color(hex: "#2C4F40"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: "#E2E4D6"))
                .cornerRadius(8)

                Spacer()

                if !ralley.isFull {
                    Text("\(ralley.availableSpots) spots left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)

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
                            .background(Color(hex: "#2C4F40"))
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
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Action Button
            actionButton.padding(16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        .task {
            await checkUserParticipationStatus()
        }
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        if ralley.isCaptain {
            Button(action: { showingManagement = true }) {
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
            .sheet(isPresented: $showingManagement) {
                RalleyManagementView(ralley: ralley)
                    .environmentObject(ralleyManager)
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
        case .pending: return Color(hex: "#2C4F40")
        case .joined: return Color(hex: "#2C4F40")
        }
    }

    private var buttonBackground: Color {
        switch participationStatus {
        case .notJoined: return Color(hex: "#2C4F40")
        case .pending: return Color(hex: "#E2E4D6")
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

        // Block non-athletes from joining college-athletes-only ralleys
        if ralley.isCollegeAthletesOnly {
            let isFormerAthlete = SavedUserProfile.loadFromStorage()?.playedCollegeSport == true
            guard isFormerAthlete else { return }
        }

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
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasFilters ? "line.3.horizontal.decrease.circle" : "sportscourt")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))
                .scaleEffect(isVisible ? 1 : 0.5)
                .opacity(isVisible ? 1 : 0)

            Text(hasFilters ? "No matching ralleys" : "No ralleys nearby")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

            Text(hasFilters ? "Try adjusting your filters or search" : "Be the first to create a pickup game in your area!")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

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
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

// MARK: - No Nearby Ralleys View (Empty State without filters)

struct NoNearbyRalleysView: View {
    var onCreateRalley: () -> Void
    var onNotifyMe: () -> Void = {}
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.7))
                .scaleEffect(isVisible ? 1 : 0.5)
                .opacity(isVisible ? 1 : 0)

            Text("No Ralleys near you yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

            Text("Be the first to rally! Create a game and invite your friends.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

            Button(action: onCreateRalley) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("Create a Ralley")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "#2C4F40"))
                .cornerRadius(14)
                .shadow(color: Color(hex: "#2C4F40").opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 24)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)

            Button(action: onNotifyMe) {
                Text("Notify me when Ralleys appear nearby")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}
