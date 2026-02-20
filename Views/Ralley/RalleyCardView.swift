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

    private var fillPercent: Double {
        guard ralley.maxPlayers > 0 else { return 0 }
        return Double(ralley.currentPlayers) / Double(ralley.maxPlayers)
    }

    private var formattedTime: String {
        let cal = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let time = timeFormatter.string(from: ralley.dateTime)

        if cal.isDateInToday(ralley.dateTime) {
            return "Today \u{00B7} \(time)"
        } else if cal.isDateInTomorrow(ralley.dateTime) {
            return "Tomorrow \u{00B7} \(time)"
        } else {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEE"
            return "\(dayFormatter.string(from: ralley.dateTime)) \u{00B7} \(time)"
        }
    }

    private var hostInitial: String {
        String(ralley.organizer.name.prefix(1)).uppercased()
    }

    private var skillLabel: String {
        ralley.requirements.isEmpty ? "All levels" : ralley.requirements
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topRow
            titleRow
            locationRow
            progressSection
            hostRow
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .sheet(isPresented: $showingManagement) {
            RalleyManagementView(ralley: ralley)
                .environmentObject(ralleyManager)
        }
        .task {
            await checkUserParticipationStatus()
        }
    }

    // MARK: - Top Row (sport tag + time + join button)

    private var topRow: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    // Sport tag capsule
                    HStack(spacing: 5) {
                        Image(systemName: SportIconMapper.iconName(for: ralley.sport))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "#2C4F40"))
                        Text(ralley.sport)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "#2C4F40"))
                    }
                    .padding(.vertical, 4)
                    .padding(.leading, 7)
                    .padding(.trailing, 10)
                    .background(Color(hex: "#E2E4D6"))
                    .clipShape(Capsule())

                    Text(formattedTime)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#7a9088"))
                }
            }
            Spacer()
            joinButton
        }
    }

    // MARK: - Title

    private var titleRow: some View {
        HStack(spacing: 6) {
            Text(ralley.title)
                .font(.custom("Chillax-Semibold", size: 17))
                .foregroundColor(Color(hex: "#2C4F40"))
                .lineLimit(1)

            if ralley.isCaptain {
                Text("CAPTAIN")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(hex: "#2C4F40"))
                    .cornerRadius(4)
            }
        }
        .padding(.top, 7)
    }

    // MARK: - Location

    private var locationRow: some View {
        HStack(spacing: 5) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#5a7268"))
            Text(ralley.location.name)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#5a7268"))
                .lineLimit(1)
        }
        .padding(.top, 10)
    }

    // MARK: - Progress (joined count + bar)

    private var progressSection: some View {
        VStack(spacing: 7) {
            HStack {
                HStack(spacing: 3) {
                    Text("\(ralley.currentPlayers)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#2C4F40"))
                    Text("joined")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#7a9088"))
                }
                Spacer()
                Text("\(ralley.availableSpots) spots left \u{00B7} \(skillLabel)")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#7a9088"))
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "#E2E4D6"))
                        .frame(height: 4)
                    Capsule()
                        .fill(ralley.isFull ? Color(hex: "#b5bdb9") : Color(hex: "#2C4F40"))
                        .frame(width: geo.size.width * fillPercent, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.top, 13)
    }

    // MARK: - Host

    private var hostRow: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#2C4F40"))
                    .frame(width: 26, height: 26)
                Text(hostInitial)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#E2E4D6"))
            }
            Text("Hosted by ")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#7a9088"))
            + Text(ralley.organizer.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "#2C4F40"))
        }
        .padding(.top, 13)
    }

    // MARK: - Join Button

    @ViewBuilder
    private var joinButton: some View {
        if ralley.isCaptain {
            Button(action: { showingManagement = true }) {
                Text("Manage")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#E2E4D6"))
                    .padding(.vertical, 9)
                    .padding(.horizontal, 20)
                    .background(Color(hex: "#2C4F40"))
                    .clipShape(Capsule())
            }
        } else {
            Button(action: { Task { await handleJoinAction() } }) {
                Group {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .progressViewStyle(CircularProgressViewStyle(tint: joinButtonTextColor))
                    } else {
                        Text(joinButtonText)
                            .font(.system(size: 13, weight: .bold))
                    }
                }
                .foregroundColor(joinButtonTextColor)
                .padding(.vertical, 9)
                .padding(.horizontal, 20)
                .background(joinButtonBackground)
                .clipShape(Capsule())
            }
            .disabled(isLoading || participationStatus == .joined || (ralley.isFull && participationStatus != .joined))
        }
    }

    private var joinButtonText: String {
        switch participationStatus {
        case .notJoined:
            return ralley.isFull ? "Full" : "Join"
        case .pending:
            return "Pending"
        case .joined:
            return "Joined"
        }
    }

    private var joinButtonTextColor: Color {
        switch participationStatus {
        case .notJoined:
            return ralley.isFull ? Color(hex: "#7a8578") : Color(hex: "#E2E4D6")
        case .pending:
            return Color(hex: "#2C4F40")
        case .joined:
            return Color(hex: "#2C4F40")
        }
    }

    private var joinButtonBackground: Color {
        switch participationStatus {
        case .notJoined:
            return ralley.isFull ? Color(hex: "#c4cabe") : Color(hex: "#2C4F40")
        case .pending:
            return Color(hex: "#E2E4D6")
        case .joined:
            return Color(hex: "#E2E4D6")
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
                .fontDesign(.rounded)
                .foregroundColor(Color(hex: "#2C4F40"))
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

            Text(hasFilters ? "Try adjusting your filters or search" : "Be the first to create a pickup game in your area!")
                .font(.system(size: 16, weight: .regular))
                .fontDesign(.rounded)
                .foregroundColor(Color(hex: "#7a9088"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

            if !hasFilters, let onCreateRalley = onCreateRalley {
                Button(action: onCreateRalley) {
                    Text("Create Ralley")
                        .font(.system(size: 17, weight: .semibold))
                        .fontDesign(.rounded)
                        .foregroundColor(Color(hex: "#E2E4D6"))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#2C4F40"))
                        .clipShape(Capsule())
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

// MARK: - No Nearby Ralleys View

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
                .fontDesign(.rounded)
                .foregroundColor(Color(hex: "#2C4F40"))
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

            Text("Be the first to rally! Create a game and invite your friends.")
                .font(.system(size: 16))
                .fontDesign(.rounded)
                .foregroundColor(Color(hex: "#7a9088"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

            Button(action: onCreateRalley) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Create a Ralley")
                        .font(.system(size: 18, weight: .semibold))
                        .fontDesign(.rounded)
                }
                .foregroundColor(Color(hex: "#E2E4D6"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "#2C4F40"))
                .clipShape(Capsule())
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
