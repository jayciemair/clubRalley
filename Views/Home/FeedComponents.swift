//
//  FeedComponents.swift
//  Club Ralley
//
//  Components for the home feed — top bar, upcoming ralleys, separators
//

import SwiftUI

// MARK: - Top Bar

struct HomeTopBar: View {
    @Binding var showingNotifications: Bool
    @State private var hasUnreadNotifications = true

    var body: some View {
        HStack {
            HStack(spacing: 7) {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#2C4F40"))

                Text("Your Upcoming Ralleys")
                    .font(.custom("Chillax-Bold", size: 22))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }

            Spacer()

            // Bell with red dot badge
            Button(action: { showingNotifications = true }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color(hex: "#2C4F40"))

                    if hasUnreadNotifications {
                        Circle()
                            .fill(Color(hex: "#E74C3C"))
                            .frame(width: 7, height: 7)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                            .offset(x: 2, y: -1)
                    }
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }
}

// MARK: - Upcoming Ralleys Section

struct HomeUpcomingSection: View {
    @EnvironmentObject var ralleyManager: RalleyManager
    @AppStorage("selectedTab") private var selectedTab: MainTab = .home

    private var upcomingRalleys: [ClubRalley] {
        ralleyManager.getJoinedUpcomingRalleys()
    }

    /// Count of players across all ralleys happening this week
    private var playersThisWeek: Int {
        let now = Date()
        let calendar = Calendar.current
        guard let endOfWeek = calendar.date(byAdding: .day, value: 7, to: now) else { return 0 }
        return ralleyManager.ralleys
            .filter { $0.dateTime > now && $0.dateTime <= endOfWeek }
            .reduce(0) { $0 + max(0, $1.currentPlayers - 1) } // exclude organizer
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if upcomingRalleys.isEmpty {
                // Empty state card
                VStack(alignment: .leading, spacing: 16) {
                    // Teammates pill
                    if playersThisWeek > 0 {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: "#4CAF50"))
                                .frame(width: 8, height: 8)
                            Text("\(playersThisWeek) \(playersThisWeek == 1 ? "PLAYER" : "PLAYERS") ACTIVE THIS WEEK")
                                .font(.system(size: 11, weight: .bold))
                                .fontDesign(.rounded)
                                .foregroundColor(.white.opacity(0.8))
                                .tracking(0.5)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(20)
                    }

                    // Title
                    Text("No upcoming Ralleys\n— yet. 👀")
                        .font(.custom("Chillax-Bold", size: 28))
                        .foregroundColor(.white)
                        .lineSpacing(2)

                    // Subtitle
                    Text("Your crew is already out there. Jump into a Ralley and get in on the action.")
                        .font(.system(size: 15, weight: .medium))
                        .fontDesign(.rounded)
                        .foregroundColor(.white.opacity(0.7))
                        .lineSpacing(3)

                    // CTA button
                    Button(action: { selectedTab = .ralleys }) {
                        HStack(spacing: 8) {
                            Text("Find Ralleys Near Me")
                                .font(.system(size: 16, weight: .bold))
                                .fontDesign(.rounded)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(Color(hex: "#2C4F40"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(28)
                    }
                    .padding(.top, 4)
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#2C4F40"))
                .cornerRadius(20)
                .padding(.horizontal, 22)
                .padding(.top, 10)
                .padding(.bottom, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(upcomingRalleys) { ralley in
                            NavigationLink(destination: RalleyDetailView(ralley: ralley)) {
                                HomeUpcomingCard(ralley: ralley)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// MARK: - Upcoming Ralley Card (Dark Green)

struct HomeUpcomingCard: View {
    let ralley: ClubRalley

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d 'at' h:mm a"
        return formatter.string(from: ralley.dateTime)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: sport pill + time badge
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: SportIconMapper.iconName(for: ralley.sport))
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))
                    Text(ralley.sport)
                        .font(.system(size: 11, weight: .semibold))
                        .fontDesign(.rounded)
                        .foregroundColor(.white.opacity(0.65))
                }

                Spacer()

                Text(ralley.timeUntilStart)
                    .font(.system(size: 11, weight: .bold))
                    .fontDesign(.rounded)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(6)
            }

            // Title
            Text(ralley.title)
                .font(.system(size: 15, weight: .bold))
                .fontDesign(.rounded)
                .foregroundColor(.white)
                .lineLimit(2)

            // Info rows
            VStack(alignment: .leading, spacing: 4) {
                infoRow(icon: "clock", text: formattedDate)
                infoRow(icon: "mappin", text: ralley.location.name)
                infoRow(icon: "person.2", text: "\(ralley.currentPlayers)/\(ralley.maxPlayers) joined")
            }
        }
        .padding(14)
        .frame(width: 230)
        .background(Color(hex: "#2C4F40"))
        .cornerRadius(16)
        .shadow(color: .green.opacity(0.25), radius: 12, x: 0, y: 6)
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .fontDesign(.rounded)
                .lineLimit(1)
        }
        .foregroundColor(.white.opacity(0.7))
    }
}

// MARK: - Feed Separator

struct FeedSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color(hex: "#ECE9E2"))
            .frame(height: 10)
    }
}

// MARK: - Mutuals Row

struct HomeMutualsRow: View {
    var body: some View {
        HStack(spacing: 0) {
            // Overlapping avatar circles
            overlappingAvatars
                .frame(width: 48)

            Text("& your friends loved this post")
                .font(.system(size: 11, weight: .semibold))
                .fontDesign(.rounded)
                .foregroundColor(Color(hex: "#7A8A81"))
                .padding(.leading, 12)

            Spacer()
        }
    }

    private var overlappingAvatars: some View {
        ZStack(alignment: .leading) {
            mutualAvatar(index: 0)
            mutualAvatar(index: 1)
            mutualAvatar(index: 2)
        }
    }

    private func mutualAvatar(index: Int) -> some View {
        let opacity = 0.15 + Double(index) * 0.1
        return Circle()
            .fill(Color(hex: "#2C4F40").opacity(opacity))
            .frame(width: 20, height: 20)
            .overlay(Circle().stroke(Color(hex: "#F6F5F1"), lineWidth: 2))
            .offset(x: CGFloat(index) * 14)
    }
}

// MARK: - Feed Loading View

struct FeedLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                PostSkeletonView()
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - Post Skeleton View

struct PostSkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle().fill(Color.gray.opacity(0.2)).frame(width: 42, height: 42)
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)).frame(width: 120, height: 14)
                    RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.15)).frame(width: 80, height: 11)
                }
                Spacer()
            }
            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)).frame(height: 15)
            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.15)).frame(width: 220, height: 13)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .opacity(isAnimating ? 0.6 : 1.0)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Feed Error View

struct FeedErrorView: View {
    let error: Error
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))
            Text("Unable to load feed")
                .font(.system(size: 20, weight: .semibold))
                .fontDesign(.rounded)
                .foregroundColor(.black)
            Text("Check your internet connection and try again")
                .font(.system(size: 15))
                .fontDesign(.rounded)
                .foregroundColor(Color(hex: "#7A8A81"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button(action: onRetry) {
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
                .cornerRadius(12)
            }
        }
        .padding(.top, 60)
    }
}

// MARK: - Empty Feed View

struct EmptyFeedView: View {
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sportscourt")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))
                .scaleEffect(isVisible ? 1 : 0.5)
                .opacity(isVisible ? 1 : 0)

            Text("Welcome to Club Ralley!")
                .font(.system(size: 24, weight: .bold))
                .fontDesign(.rounded)
                .foregroundColor(.black)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

            Text("Start following athletes and join ralleys to see posts in your feed")
                .font(.system(size: 16))
                .fontDesign(.rounded)
                .foregroundColor(Color(hex: "#7A8A81"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)
        }
        .padding(.top, 60)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}
