//
//  FeedComponents.swift
//  Club Ralley
//
//  Components for the home feed
//

import SwiftUI

// MARK: - Feed Header

struct FeedHeader: View {
    @Binding var showingNotifications: Bool
    @Binding var showingMessages: Bool
    var unreadMessageCount: Int = 0
    var unreadNotificationCount: Int = 0

    var body: some View {
        HStack {
            Text("Home")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)

            Spacer()

            Button(action: { showingNotifications = true }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.black)

                    // Notification badge
                    if unreadNotificationCount > 0 {
                        NotificationBadge(count: unreadNotificationCount)
                            .offset(x: 8, y: -6)
                    }
                }
            }
            .padding(.trailing, 8)

            Button(action: { showingMessages = true }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.black)

                    // Unread messages badge
                    if unreadMessageCount > 0 {
                        NotificationBadge(count: unreadMessageCount)
                            .offset(x: 10, y: -6)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Notification Badge

struct NotificationBadge: View {
    let count: Int

    var body: some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, count > 9 ? 5 : 6)
            .padding(.vertical, 2)
            .background(Color.red)
            .clipShape(Capsule())
            .minimumScaleFactor(0.8)
    }
}

// MARK: - Upcoming Ralleys Section

struct UpcomingRalleysSection: View {
    let ralleys: [ClubRalley]
    @EnvironmentObject var ralleyManager: RalleyManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#2C4F40"))
                Text("Your Upcoming Ralleys")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ralleys) { ralley in
                        NavigationLink(destination: RalleyDetailView(ralley: ralley).environmentObject(ralleyManager)) {
                            UpcomingRalleyCard(ralley: ralley)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
        .background(Color(hex: "#F8F8F8"))
    }
}

// MARK: - Upcoming Ralley Card

struct UpcomingRalleyCard: View {
    let ralley: ClubRalley

    private var timeUntil: String {
        let now = Date()
        let interval = ralley.dateTime.timeIntervalSince(now)

        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "in \(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "in \(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "in \(days)d"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
        return formatter.string(from: ralley.dateTime)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(ralley.sport)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#2C4F40"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#2C4F40").opacity(0.1))
                    .cornerRadius(8)

                Spacer()

                Text(timeUntil)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#2C4F40"))
                    .cornerRadius(8)
            }

            Text(ralley.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .lineLimit(1)

            Text(formattedDate)
                .font(.system(size: 13))
                .foregroundColor(.gray)

            HStack(spacing: 4) {
                Image(systemName: "mappin").font(.system(size: 12))
                Text(ralley.location.name).font(.system(size: 13)).lineLimit(1)
            }
            .foregroundColor(.gray)

            HStack(spacing: 4) {
                Image(systemName: "person.2").font(.system(size: 12))
                Text("\(ralley.currentPlayers)/\(ralley.maxPlayers) joined").font(.system(size: 13))
            }
            .foregroundColor(Color(hex: "#2C4F40"))
        }
        .padding(12)
        .frame(width: 220)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
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
            HStack(spacing: 12) {
                Circle().fill(Color.gray.opacity(0.3)).frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3)).frame(width: 120, height: 16)
                    RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)).frame(width: 180, height: 12)
                }
                Spacer()
            }
            .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)).frame(height: 14)
                RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)).frame(width: 200, height: 14)
            }
            .padding(.horizontal, 16)

            HStack {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)).frame(width: 30, height: 20)
                    Spacer()
                }
            }
            .padding(.horizontal, 16)

            Divider()
        }
        .padding(.vertical, 16)
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
                .foregroundColor(.black)

            Text("Check your internet connection and try again")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 16, weight: .semibold))
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
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sportscourt")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))
            Text("Welcome to Club Ralley!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            Text("Start following athletes and join ralleys to see posts in your feed")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }
}
