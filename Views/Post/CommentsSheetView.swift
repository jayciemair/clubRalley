//
//  CommentsSheetView.swift
//  Club Ralley
//
//  Sheet view for displaying and adding comments on posts
//

import SwiftUI

struct CommentsSheetView: View {
    let post: ClubRalleyPost
    @EnvironmentObject var postManager: PostManager
    @Environment(\.dismiss) private var dismiss

    @State private var newCommentText = ""
    @FocusState private var isInputFocused: Bool

    private let supabase = SupabaseManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Comments List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if postManager.isLoadingComments {
                            ProgressView()
                                .padding(.top, 40)
                        } else if postManager.selectedPostComments.isEmpty {
                            emptyCommentsView
                        } else {
                            ForEach(postManager.selectedPostComments) { comment in
                                CommentRow(
                                    comment: comment,
                                    isOwnComment: comment.userId == supabase.currentUser?.id,
                                    onDelete: {
                                        Task {
                                            await postManager.deleteComment(comment.id, from: post.id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100) // Space for input bar
                }

                // Input Bar
                commentInputBar
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
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

    private var emptyCommentsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.5))

            Text("No comments yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)

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
                    .focused($isInputFocused)

                Button(action: sendComment) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : Color(hex: "#2C4F40"))
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
            isInputFocused = false
        }
    }
}

// MARK: - Comment Row

struct CommentRow: View {
    let comment: PostComment
    let isOwnComment: Bool
    let onDelete: () -> Void

    @State private var showingDeleteConfirmation = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User Avatar
            AsyncImage(url: URL(string: comment.user?.profilePhotoURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color(hex: "#2C4F40"))
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                // User name and time
                HStack(spacing: 8) {
                    Text(comment.user?.displayName ?? "User")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)

                    Text(timeAgo(from: comment.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    Spacer()

                    if isOwnComment {
                        Button(action: { showingDeleteConfirmation = true }) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                }

                // Comment content
                Text(comment.content)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .lineSpacing(2)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .alert("Delete Comment?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This action cannot be undone.")
        }
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
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - User Extension for Display Name

extension User {
    var displayName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}
