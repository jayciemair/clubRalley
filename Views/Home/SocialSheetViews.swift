//
//  SocialSheetViews.swift
//  Club Ralley
//
//  Sheet views for social interactions: comments, reports, notifications
//

import SwiftUI

// MARK: - Comments Sheet View

struct CommentsSheetView: View {
    let post: ClubRalleyPost
    @EnvironmentObject var postManager: PostManager
    @Environment(\.dismiss) private var dismiss
    @State private var newCommentText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                commentsScrollView
                commentInputBar
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
        .onAppear {
            Task { await postManager.loadComments(for: post.id) }
        }
    }

    private var commentsScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if postManager.isLoadingComments {
                    ProgressView().padding(.top, 40)
                } else if postManager.selectedPostComments.isEmpty {
                    emptyCommentsView
                } else {
                    ForEach(postManager.selectedPostComments) { comment in
                        CommentRowView(comment: comment)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }

    private var emptyCommentsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.5))
            Text("No comments yet")
                .font(.system(size: 18, weight: .semibold))
            Text("Be the first to comment!")
                .font(.system(size: 15))
                .foregroundColor(.gray)
        }
        .padding(.top, 60)
    }

    private var commentInputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $newCommentText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(24)

                Button(action: sendComment) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(newCommentText.isEmpty ? .gray : Color(hex: "#2C4F40"))
                }
                .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
    }

    private func sendComment() {
        let content = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        Task {
            await postManager.addComment(to: post.id, content: content)
            newCommentText = ""
        }
    }
}

// MARK: - Comment Row View

struct CommentRowView: View {
    let comment: PostComment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(hex: "#2C4F40"))
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(comment.user?.firstName ?? "User")
                    .font(.system(size: 14, weight: .semibold))
                Text(comment.content)
                    .font(.system(size: 15))
            }
            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Report Sheet View

struct ReportSheetView: View {
    let postId: UUID
    @EnvironmentObject var postManager: PostManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: String?
    @State private var showingSuccess = false

    private let reasons = ["Spam", "Harassment", "Inappropriate Content", "Hate Speech", "Other"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                Divider()
                reasonsList
                submitButton
            }
            .navigationTitle("Report Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
            .alert("Report Submitted", isPresented: $showingSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Thank you for helping keep Club Ralley safe.")
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why are you reporting this post?")
                .font(.system(size: 18, weight: .semibold))
            Text("Your report is anonymous.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }

    private var reasonsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(reasons, id: \.self) { reason in
                    Button(action: { selectedReason = reason }) {
                        HStack {
                            Text(reason)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                            Spacer()
                            Image(systemName: selectedReason == reason ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedReason == reason ? Color(hex: "#2C4F40") : .gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    Divider().padding(.leading, 20)
                }
            }
        }
    }

    private var submitButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: submitReport) {
                Text("Submit Report")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedReason != nil ? Color(hex: "#2C4F40") : Color.gray.opacity(0.3))
                    .cornerRadius(12)
            }
            .disabled(selectedReason == nil)
            .padding(20)
        }
    }

    private func submitReport() {
        guard let reason = selectedReason else { return }
        Task {
            await postManager.reportPost(postId, reason: reason)
            showingSuccess = true
        }
    }
}

// MARK: - Notifications Sheet View

struct NotificationsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notifications: [AppNotificationItem] = AppNotificationItem.mockData

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if notifications.isEmpty {
                    emptyNotificationsView
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
    }

    private var emptyNotificationsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 56))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.5))
            Text("No notifications yet")
                .font(.system(size: 20, weight: .semibold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(notifications) { notification in
                    NotificationRowView(notification: notification)
                }
            }
        }
    }
}

// MARK: - Notification Row View

struct NotificationRowView: View {
    let notification: AppNotificationItem

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: notification.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#2C4F40"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#2C4F40").opacity(0.1))
                    .clipShape(Circle())

                Text(notification.message)
                    .font(.system(size: 15))
                    .foregroundColor(.black)

                Spacer()

                if !notification.isRead {
                    Circle()
                        .fill(Color(hex: "#2C4F40"))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(notification.isRead ? Color.clear : Color(hex: "#2C4F40").opacity(0.05))

            Divider().padding(.leading, 72)
        }
    }
}

// MARK: - App Notification Item Model

struct AppNotificationItem: Identifiable {
    let id: UUID
    let message: String
    let icon: String
    let isRead: Bool

    static let mockData: [AppNotificationItem] = [
        AppNotificationItem(id: UUID(), message: "Sarah Wilson started following you", icon: "person.badge.plus", isRead: false),
        AppNotificationItem(id: UUID(), message: "Mike Johnson commented on your post", icon: "message.fill", isRead: false),
        AppNotificationItem(id: UUID(), message: "Emily Chen liked your post", icon: "heart.fill", isRead: true),
        AppNotificationItem(id: UUID(), message: "Your basketball ralley starts in 1 hour", icon: "clock.fill", isRead: true)
    ]
}
