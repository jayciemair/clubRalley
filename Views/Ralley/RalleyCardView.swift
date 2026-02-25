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
    @State private var joinSuccess = false
    @State private var animatedFillPercent: Double = 0

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
        .background(ClubRalleyTheme.Colors.sageGreen)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .contextMenu {
            Button {
                ShareUtility.shareRalley(ralley)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
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
                            .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                        Text(ralley.sport)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                    }
                    .padding(.vertical, 4)
                    .padding(.leading, 7)
                    .padding(.trailing, 10)
                    .background(ClubRalleyTheme.Colors.sageGreen)
                    .clipShape(Capsule())

                    Text(formattedTime)
                        .font(.system(size: 12))
                        .foregroundColor(ClubRalleyTheme.Colors.mutedText)
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
                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                .lineLimit(1)

            if ralley.isCaptain {
                Text("CAPTAIN")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ClubRalleyTheme.Colors.darkGreen)
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
                .foregroundColor(ClubRalleyTheme.Colors.subtleText)
            Text(ralley.location.name)
                .font(.system(size: 13))
                .foregroundColor(ClubRalleyTheme.Colors.subtleText)
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
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                    Text("joined")
                        .font(.system(size: 12))
                        .foregroundColor(ClubRalleyTheme.Colors.mutedText)
                }
                Spacer()
                Text("\(ralley.availableSpots) spots left \u{00B7} \(skillLabel)")
                    .font(.system(size: 12))
                    .foregroundColor(ClubRalleyTheme.Colors.mutedText)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ClubRalleyTheme.Colors.sageGreen)
                        .frame(height: 4)
                    Capsule()
                        .fill(ralley.isFull ? ClubRalleyTheme.Colors.disabledButton : ClubRalleyTheme.Colors.darkGreen)
                        .frame(width: geo.size.width * animatedFillPercent, height: 4)
                        .animation(.easeInOut(duration: ClubRalleyTheme.Animation.slow), value: animatedFillPercent)
                }
            }
            .frame(height: 4)
            .onAppear { animatedFillPercent = fillPercent }
            .onChange(of: ralley.currentPlayers) { _, _ in animatedFillPercent = fillPercent }
        }
        .padding(.top, 13)
    }

    // MARK: - Host

    private var hostRow: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(ClubRalleyTheme.Colors.darkGreen)
                    .frame(width: 26, height: 26)
                Text(hostInitial)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(ClubRalleyTheme.Colors.sageGreen)
            }
            Text("Hosted by ")
                .font(.system(size: 12))
                .foregroundColor(ClubRalleyTheme.Colors.mutedText)
            + Text(ralley.organizer.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
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
                    .foregroundColor(ClubRalleyTheme.Colors.sageGreen)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 20)
                    .background(ClubRalleyTheme.Colors.darkGreen)
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
            return ralley.isFull ? ClubRalleyTheme.Colors.mutedText : ClubRalleyTheme.Colors.sageGreen
        case .pending:
            return ClubRalleyTheme.Colors.darkGreen
        case .joined:
            return ClubRalleyTheme.Colors.darkGreen
        }
    }

    private var joinButtonBackground: Color {
        switch participationStatus {
        case .notJoined:
            return ralley.isFull ? ClubRalleyTheme.Colors.disabledButton : ClubRalleyTheme.Colors.darkGreen
        case .pending:
            return ClubRalleyTheme.Colors.sageGreen
        case .joined:
            return ClubRalleyTheme.Colors.sageGreen
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

        // Haptic + flash on successful join
        if participationStatus == .joined || participationStatus == .pending {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            joinSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                joinSuccess = false
            }
            animatedFillPercent = fillPercent
        }
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
                .foregroundColor(ClubRalleyTheme.Colors.darkGreen.opacity(0.6))
                .scaleEffect(isVisible ? 1 : 0.5)
                .opacity(isVisible ? 1 : 0)

            Text(hasFilters ? "No matching ralleys" : "No ralleys nearby")
                .font(.system(size: 20, weight: .bold))
                .fontDesign(.rounded)
                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

            Text(hasFilters ? "Try adjusting your filters or search" : "Be the first to create a pickup game in your area!")
                .font(.system(size: 16, weight: .regular))
                .fontDesign(.rounded)
                .foregroundColor(ClubRalleyTheme.Colors.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

            if !hasFilters, let onCreateRalley = onCreateRalley {
                Button(action: onCreateRalley) {
                    Text("Create Ralley")
                        .font(.system(size: 17, weight: .semibold))
                        .fontDesign(.rounded)
                        .foregroundColor(ClubRalleyTheme.Colors.sageGreen)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(ClubRalleyTheme.Colors.darkGreen)
                        .clipShape(Capsule())
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
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
                .foregroundColor(ClubRalleyTheme.Colors.darkGreen.opacity(0.7))
                .scaleEffect(isVisible ? 1 : 0.5)
                .opacity(isVisible ? 1 : 0)

            Text("No Ralleys near you yet")
                .font(.system(size: 22, weight: .bold))
                .fontDesign(.rounded)
                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

            Text("Be the first to rally! Create a game and invite your friends.")
                .font(.system(size: 16))
                .fontDesign(.rounded)
                .foregroundColor(ClubRalleyTheme.Colors.mutedText)
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(ClubRalleyTheme.Colors.darkGreen)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)

            Button(action: onNotifyMe) {
                Text("Notify me when Ralleys appear nearby")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}
