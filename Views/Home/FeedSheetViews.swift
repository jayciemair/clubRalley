//
//  FeedSheetViews.swift
//  Club Ralley
//
//  Sheet views for the home feed: notifications, comments, reports
//

import SwiftUI

// MARK: - Simple Notifications View

struct SimpleNotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    private let notifications = [
        ("Sarah Wilson started following you", "person.badge.plus", false),
        ("Mike Johnson commented on your post", "message.fill", false),
        ("Emily Chen liked your post", "heart.fill", true),
        ("Your basketball ralley starts in 1 hour", "clock.fill", true)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(notifications.indices, id: \.self) { i in
                        HStack(spacing: 12) {
                            Image(systemName: notifications[i].1)
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "#2C4F40"))
                                .frame(width: 44, height: 44)
                                .background(Color(hex: "#2C4F40").opacity(0.1))
                                .clipShape(Circle())
                            Text(notifications[i].0).font(.system(size: 15))
                            Spacer()
                            if !notifications[i].2 {
                                Circle().fill(Color(hex: "#2C4F40")).frame(width: 10, height: 10)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(notifications[i].2 ? Color.clear : Color(hex: "#2C4F40").opacity(0.05))
                        Divider().padding(.leading, 72)
                    }
                }
            }
            .navigationTitle("Notifications").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() }.foregroundColor(Color(hex: "#2C4F40")) } }
        }
    }
}

// MARK: - Simple Comments Sheet

struct SimpleCommentsSheet: View {
    let post: ClubRalleyPost
    @EnvironmentObject var postManager: PostManager
    @Environment(\.dismiss) private var dismiss
    @State private var newComment = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if postManager.isLoadingComments {
                            ProgressView().padding(.top, 40)
                        } else if postManager.selectedPostComments.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 48)).foregroundColor(Color(hex: "#2C4F40").opacity(0.5))
                                Text("No comments yet").font(.system(size: 18, weight: .semibold))
                                Text("Be the first to comment!").font(.system(size: 15)).foregroundColor(.gray)
                            }.padding(.top, 60)
                        } else {
                            ForEach(postManager.selectedPostComments) { comment in
                                HStack(alignment: .top, spacing: 12) {
                                    Circle().fill(Color(hex: "#2C4F40")).frame(width: 36, height: 36)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(comment.user?.firstName ?? "User").font(.system(size: 14, weight: .semibold))
                                        Text(comment.content).font(.system(size: 15))
                                    }
                                    Spacer()
                                }.padding(12).background(Color.gray.opacity(0.05)).cornerRadius(12)
                            }
                        }
                    }.padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 100)
                }
                commentInputBar
            }
            .navigationTitle("Comments").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() }.foregroundColor(Color(hex: "#2C4F40")) } }
        }
        .onAppear { Task { await postManager.loadComments(for: post.id) } }
    }

    private var commentInputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                TextField("Add a comment...", text: $newComment)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1)).cornerRadius(24)
                Button(action: sendComment) {
                    Image(systemName: "paperplane.fill").font(.system(size: 20))
                        .foregroundColor(newComment.isEmpty ? .gray : Color(hex: "#2C4F40"))
                }.disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }.padding(.horizontal, 16).padding(.vertical, 12).background(Color.white)
        }
    }

    private func sendComment() {
        let content = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        Task { await postManager.addComment(to: post.id, content: content); newComment = "" }
    }
}

// MARK: - Simple Report Sheet

struct SimpleReportSheet: View {
    let postId: UUID
    @EnvironmentObject var postManager: PostManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: String?
    @State private var showingSuccess = false
    private let reasons = ["Spam", "Harassment", "Inappropriate Content", "Hate Speech", "Other"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why are you reporting this post?").font(.system(size: 18, weight: .semibold))
                    Text("Your report is anonymous.").font(.system(size: 14)).foregroundColor(.gray)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
                Divider()
                reasonsList
                submitSection
            }
            .navigationTitle("Report Post").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(Color(hex: "#2C4F40")) } }
            .alert("Report Submitted", isPresented: $showingSuccess) { Button("OK") { dismiss() } } message: { Text("Thank you for helping keep Club Ralley safe.") }
        }
    }

    private var reasonsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(reasons, id: \.self) { reason in
                    Button(action: { selectedReason = reason }) {
                        HStack {
                            Text(reason).font(.system(size: 16)).foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                            Spacer()
                            Image(systemName: selectedReason == reason ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedReason == reason ? Color(hex: "#2C4F40") : .gray)
                        }.padding(.horizontal, 20).padding(.vertical, 16)
                    }
                    Divider().padding(.leading, 20)
                }
            }
        }
    }

    private var submitSection: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: {
                guard let reason = selectedReason else { return }
                Task { await postManager.reportPost(postId, reason: reason); showingSuccess = true }
            }) {
                Text("Submit Report").font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(selectedReason != nil ? Color(hex: "#2C4F40") : Color.gray.opacity(0.3)).cornerRadius(12)
            }.disabled(selectedReason == nil).padding(20)
        }
    }
}
