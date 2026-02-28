//
//  PostDetailView.swift
//  Club Ralley
//
//  Full post detail view with inline comments
//

import SwiftUI

struct PostDetailView: View {
    let post: ClubRalleyPost
    @EnvironmentObject var postManager: PostManager
    @Environment(\.dismiss) private var dismiss

    @State private var isLiked: Bool
    @State private var isReposted: Bool
    @State private var likeCount: Int
    @State private var commentCount: Int
    @State private var showingRepostSheet = false
    @State private var newCommentText = ""
    @State private var heartScale: CGFloat = 1.0
    @FocusState private var isInputFocused: Bool

    private let supabase = SupabaseManager.shared

    init(post: ClubRalleyPost) {
        self.post = post
        _isLiked = State(initialValue: post.isLiked)
        _isReposted = State(initialValue: post.isReposted)
        _likeCount = State(initialValue: post.likes)
        _commentCount = State(initialValue: post.comments)
    }

    private var initials: String {
        let parts = post.authorName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    private var subtitle: String {
        let location = post.authorLocation ?? ""
        if location.isEmpty {
            return post.timeAgo
        }
        return "\(post.timeAgo) · \(location)"
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Post Content

                    // Author row
                    HStack(alignment: .center, spacing: 12) {
                        Circle()
                            .fill(ClubRalleyTheme.Colors.darkGreen)
                            .frame(width: 46, height: 46)
                            .overlay(
                                Text(initials)
                                    .font(.system(size: 18, weight: .bold))
                                    .fontDesign(.rounded)
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(post.authorName)
                                .font(.system(size: 16, weight: .bold))
                                .fontDesign(.rounded)
                                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)

                            Text(subtitle)
                                .font(.system(size: 12, weight: .semibold))
                                .fontDesign(.rounded)
                                .foregroundColor(ClubRalleyTheme.Colors.darkGreen.opacity(0.55))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 18)

                    // Post title
                    if let title = post.title, !title.isEmpty {
                        Text(title)
                            .font(.custom("Chillax-Bold", size: 17))
                            .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                            .padding(.top, 14)
                            .padding(.bottom, 4)
                            .padding(.horizontal, 22)
                    }

                    // Post text
                    if !post.content.isEmpty {
                        Text(post.content)
                            .font(.system(size: 14, weight: .medium))
                            .fontDesign(.rounded)
                            .foregroundColor(ClubRalleyTheme.Colors.darkGreen.opacity(0.7))
                            .lineSpacing(2)
                            .padding(.bottom, 14)
                            .padding(.horizontal, 22)
                    }

                    // Photos
                    if !post.images.isEmpty {
                        PostPhotoCollage(photos: post.images)
                    }

                    // Mutuals row
                    if likeCount > 0 {
                        HomeMutualsRow()
                            .padding(.top, 10)
                            .padding(.horizontal, 22)
                    }

                    // Action bar separator
                    Rectangle()
                        .fill(ClubRalleyTheme.Colors.separator)
                        .frame(height: 1)
                        .padding(.top, 10)

                    // Action bar
                    PostActionBar(
                        post: post,
                        isLiked: $isLiked,
                        isReposted: $isReposted,
                        likeCount: $likeCount,
                        commentCount: $commentCount,
                        heartScale: heartScale,
                        onLike: handleLike,
                        onComment: { isInputFocused = true },
                        onRepost: { showingRepostSheet = true },
                        onShare: { ShareUtility.sharePost(post) }
                    )
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)

                    // MARK: - Comments Section

                    Rectangle()
                        .fill(ClubRalleyTheme.Colors.separator)
                        .frame(height: 6)

                    // Comments header
                    Text("Comments")
                        .font(.system(size: 16, weight: .bold))
                        .fontDesign(.rounded)
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                        .padding(.horizontal, 22)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                    if postManager.isLoadingComments {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                    } else if postManager.selectedPostComments.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 36))
                                .foregroundColor(ClubRalleyTheme.Colors.darkGreen.opacity(0.3))

                            Text("No comments yet")
                                .font(.system(size: 15, weight: .semibold))
                                .fontDesign(.rounded)
                                .foregroundColor(ClubRalleyTheme.Colors.darkGreen.opacity(0.5))

                            Text("Be the first to comment!")
                                .font(.system(size: 13))
                                .fontDesign(.rounded)
                                .foregroundColor(ClubRalleyTheme.Colors.inactiveIcon)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(postManager.selectedPostComments) { comment in
                                CommentRow(
                                    comment: comment,
                                    isOwnComment: comment.userId == supabase.currentUser?.id,
                                    onDelete: {
                                        Task {
                                            await postManager.deleteComment(comment.id, from: post.id)
                                            commentCount = max(0, commentCount - 1)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }

                    Spacer(minLength: 80)
                }
            }

            // MARK: - Comment Input Bar
            commentInputBar
        }
        .background(ClubRalleyTheme.Colors.warmBackground)
        .onTapGesture {
            isInputFocused = false
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Post")
        .sheet(isPresented: $showingRepostSheet) {
            RepostSheet(post: post)
                .environmentObject(postManager)
                .onDisappear {
                    if let index = postManager.indexOfPost(post.id) {
                        isReposted = postManager.posts[index].isReposted
                    }
                }
        }
        .onAppear {
            Task {
                await postManager.loadComments(for: post.id)
            }
        }
    }

    // MARK: - Comment Input

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
                        .foregroundColor(
                            newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? .gray
                                : ClubRalleyTheme.Colors.darkGreen
                        )
                }
                .pressableButton()
                .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
        }
    }

    // MARK: - Actions

    private func handleLike() {
        let willLike = !isLiked
        isLiked.toggle()
        likeCount += isLiked ? 1 : -1

        let impact = UIImpactFeedbackGenerator(style: willLike ? .medium : .light)
        impact.impactOccurred()

        if willLike {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                heartScale = 1.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    heartScale = 1.0
                }
            }
        }

        Task {
            await postManager.toggleLike(for: post.id)
            if let index = postManager.indexOfPost(post.id) {
                isLiked = postManager.posts[index].isLiked
                likeCount = postManager.posts[index].likes
            }
        }
    }

    private func sendComment() {
        let content = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        Task {
            await postManager.addComment(to: post.id, content: content)
            newCommentText = ""
            isInputFocused = false
            commentCount += 1
        }
    }
}
