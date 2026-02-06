//
//  FeedSheets.swift
//  Club Ralley
//
//  Sheet views for the home feed (notifications, comments, reports)
//

import SwiftUI

// MARK: - Notifications Sheet

struct SimpleNotificationsView: View {
    @Environment(\.dismiss) private var dismiss

    private let items = [
        ("Sarah Wilson started following you", "person.badge.plus", false),
        ("Mike Johnson commented on your post", "message.fill", false),
        ("Emily Chen liked your post", "heart.fill", true),
        ("Your ralley starts in 1 hour", "clock.fill", true)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items.indices, id: \.self) { i in
                        HStack(spacing: 12) {
                            Image(systemName: items[i].1)
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "#2C4F40"))
                                .frame(width: 44, height: 44)
                                .background(Color(hex: "#2C4F40").opacity(0.1))
                                .clipShape(Circle())

                            Text(items[i].0)
                                .font(.system(size: 15))

                            Spacer()

                            if !items[i].2 {
                                Circle()
                                    .fill(Color(hex: "#2C4F40"))
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(items[i].2 ? Color.clear : Color(hex: "#2C4F40").opacity(0.05))

                        Divider().padding(.leading, 72)
                    }
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
}

// MARK: - Comments Sheet

struct SimpleCommentsSheet: View {
    let post: ClubRalleyPost
    @EnvironmentObject var postManager: PostManager
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if postManager.isLoadingComments {
                            ProgressView().padding(.top, 40)
                        } else if postManager.selectedPostComments.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(hex: "#2C4F40").opacity(0.5))
                                Text("No comments yet")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Be the first!")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 60)
                        } else {
                            ForEach(postManager.selectedPostComments) { comment in
                                CommentRow(comment: comment)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }

                // Comment Input
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 12) {
                        TextField("Add a comment...", text: $text)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(24)

                        Button(action: {
                            let content = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !content.isEmpty else { return }
                            Task {
                                await postManager.addComment(to: post.id, content: content)
                                text = ""
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 20))
                                .foregroundColor(text.isEmpty ? .gray : Color(hex: "#2C4F40"))
                        }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                }
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
            Task {
                await postManager.loadComments(for: post.id)
            }
        }
    }
}

// MARK: - Report Sheet

struct SimpleReportSheet: View {
    let postId: UUID
    @EnvironmentObject var postManager: PostManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: String?
    @State private var showingConfirmation = false

    private let reasons = ["Spam", "Harassment", "Inappropriate Content", "Other"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why are you reporting this?")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Your report is anonymous.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)

                Divider()

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

                VStack(spacing: 0) {
                    Divider()
                    Button(action: {
                        guard let reason = selectedReason else { return }
                        Task {
                            await postManager.reportPost(postId, reason: reason)
                            showingConfirmation = true
                        }
                    }) {
                        Text("Submit")
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
            .navigationTitle("Report Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
            .alert("Submitted", isPresented: $showingConfirmation) {
                Button("OK") { dismiss() }
            } message: {
                Text("Thank you for your report.")
            }
        }
    }
}

// MARK: - Comment Row

struct CommentRow: View {
    let comment: PostComment

    private var userName: String {
        if let user = comment.user {
            return "\(user.firstName) \(user.lastName)"
        }
        return "User"
    }

    private var userPhotoURL: String? {
        comment.user?.profilePhotoURL
    }

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(comment.createdAt)

        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: comment.createdAt)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User avatar with navigation
            if let userId = comment.user?.id {
                NavigationLink(destination: UserProfileView(userId: userId)) {
                    userAvatar
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                userAvatar
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    // Tappable username
                    if let userId = comment.user?.id {
                        NavigationLink(destination: UserProfileView(userId: userId)) {
                            Text(userName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Text(userName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                    }

                    Text(timeAgo)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }

                Text(comment.content)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private var userAvatar: some View {
        Group {
            if let photoURL = userPhotoURL {
                AsyncImage(url: URL(string: photoURL)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(hex: "#2C4F40"))
                        .overlay(
                            Text(String(userName.prefix(1)).uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            } else {
                Circle()
                    .fill(Color(hex: "#2C4F40"))
                    .overlay(
                        Text(String(userName.prefix(1)).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
    }
}
