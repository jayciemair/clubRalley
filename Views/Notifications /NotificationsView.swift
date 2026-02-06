//
//  NotificationsView.swift
//  Club Ralley
//
//  View displaying user notifications
//

import SwiftUI

struct NotificationsView: View {
    @StateObject private var notificationsService = NotificationsService()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if notificationsService.isLoading {
                    loadingView
                } else if notificationsService.notifications.isEmpty {
                    emptyView
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#2C4F40"))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if notificationsService.unreadCount > 0 {
                        Button("Mark All Read") {
                            Task {
                                await notificationsService.markAllAsRead()
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#2C4F40"))
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading notifications...")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 56))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.5))

            Text("No notifications yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)

            Text("When you get notifications, they'll show up here")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(notificationsService.notifications) { notification in
                    NotificationRow(
                        notification: notification,
                        onTap: {
                            Task {
                                await notificationsService.markAsRead(notification.id)
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Notification Row

struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Actor photo or notification icon
                ZStack(alignment: .bottomTrailing) {
                    if let photoURL = notification.actorPhotoURL {
                        AsyncImage(url: URL(string: photoURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color(hex: "#2C4F40").opacity(0.3))
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(notification.type.iconColor.opacity(0.2))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: notification.type.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(notification.type.iconColor)
                            )
                    }

                    // Notification type badge
                    if notification.actorPhotoURL != nil {
                        Circle()
                            .fill(notification.type.iconColor)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: notification.type.icon)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 2, y: 2)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Message
                    Text(notificationAttributedString)
                        .font(.system(size: 15))
                        .foregroundColor(.black)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)

                    // Time ago
                    Text(timeAgo(from: notification.createdAt))
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }

                Spacer()

                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(Color(hex: "#2C4F40"))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(notification.isRead ? Color.clear : Color(hex: "#2C4F40").opacity(0.05))
        }

        Divider()
            .padding(.leading, 76)
    }

    private var notificationAttributedString: AttributedString {
        var attributedString = AttributedString(notification.message)

        // Bold the actor name if present
        if let actorName = notification.actorName,
           let range = attributedString.range(of: actorName) {
            attributedString[range].font = .system(size: 15, weight: .semibold)
        }

        return attributedString
    }

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}
