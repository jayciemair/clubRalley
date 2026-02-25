//
//  PostCardViews.swift
//  Club Ralley
//
//  Post card components for the home feed — author row, photo collage, action bar
//

import SwiftUI
import UIKit

// MARK: - Home Feed Post Card

struct HomeFeedPostCard: View {
    let post: ClubRalleyPost
    @EnvironmentObject var postManager: PostManager
    @State private var isLiked: Bool
    @State private var isReposted: Bool
    @State private var likeCount: Int
    @State private var commentCount: Int
    @State private var showingComments = false
    @State private var showingRepostSheet = false
    @State private var heartScale: CGFloat = 1.0

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
        VStack(alignment: .leading, spacing: 0) {
            // 1. Author row
            HStack(alignment: .center, spacing: 12) {
                // Avatar — 46pt green circle with initials
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

            // 2. Post title
            if let title = post.title, !title.isEmpty {
                Text(title)
                    .font(.custom("Chillax-Bold", size: 17))
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                    .padding(.top, 14)
                    .padding(.bottom, 4)
            }

            // 3. Post text
            if !post.content.isEmpty {
                Text(post.content)
                    .font(.system(size: 14, weight: .medium))
                    .fontDesign(.rounded)
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen.opacity(0.7))
                    .lineSpacing(2)
                    .padding(.bottom, 14)
            }

            // 4. Photos (full bleed)
            if !post.images.isEmpty {
                PostPhotoCollage(photos: post.images)
                    .padding(.horizontal, -22)
            }

            // 5. Mutuals row
            if likeCount > 0 {
                HomeMutualsRow()
                    .padding(.top, 10)
            }

            // 6. Action bar separator (full bleed)
            Rectangle()
                .fill(ClubRalleyTheme.Colors.separator)
                .frame(height: 1)
                .padding(.horizontal, -22)
                .padding(.top, 10)

            // 7. Action bar
            PostActionBar(
                post: post,
                isLiked: $isLiked,
                isReposted: $isReposted,
                likeCount: $likeCount,
                commentCount: $commentCount,
                heartScale: heartScale,
                onLike: handleLike,
                onComment: { showingComments = true },
                onRepost: { showingRepostSheet = true },
                onShare: { ShareUtility.sharePost(post) }
            )
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .sheet(isPresented: $showingComments) {
            CommentsSheetView(post: post)
                .environmentObject(postManager)
                .onDisappear {
                    // Sync comment count after sheet dismisses
                    if let index = postManager.indexOfPost(post.id) {
                        commentCount = postManager.posts[index].comments
                    }
                }
        }
        .sheet(isPresented: $showingRepostSheet) {
            RepostSheet(post: post)
                .environmentObject(postManager)
                .onDisappear {
                    // Sync repost state after sheet dismisses
                    if let index = postManager.indexOfPost(post.id) {
                        isReposted = postManager.posts[index].isReposted
                    }
                }
        }
    }

    private func handleLike() {
        let willLike = !isLiked
        isLiked.toggle()
        likeCount += isLiked ? 1 : -1

        // Haptic
        let impact = UIImpactFeedbackGenerator(style: willLike ? .medium : .light)
        impact.impactOccurred()

        // Heart bounce animation
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
}

// MARK: - Photo Collage

struct PostPhotoCollage: View {
    let photos: [String]

    var body: some View {
        Group {
            switch photos.count {
            case 1:
                singlePhoto
            case 2:
                twoPhotos
            default:
                fivePhotoGrid
            }
        }
    }

    // 1 photo — full width, 240pt
    private var singlePhoto: some View {
        photoImage(photos[0])
            .frame(height: 240)
            .clipped()
    }

    // 2 photos — side by side, 210pt, 2pt gap
    private var twoPhotos: some View {
        HStack(spacing: 2) {
            photoImage(photos[0])
                .frame(height: 210)
                .clipped()
            photoImage(photos[1])
                .frame(height: 210)
                .clipped()
        }
    }

    // 5-photo collage — 290pt total
    // Left column: 1 tall photo (top) + 2 small photos side by side (bottom)
    // Right column: 2 stacked photos spanning full height
    private var fivePhotoGrid: some View {
        let p = Array(photos.prefix(5))
        return HStack(spacing: 2) {
            // Left column
            VStack(spacing: 2) {
                photoImage(p[0])
                    .frame(height: 144)
                    .clipped()

                HStack(spacing: 2) {
                    photoImage(p.count > 1 ? p[1] : p[0])
                        .frame(height: 144)
                        .clipped()
                    photoImage(p.count > 2 ? p[2] : p[0])
                        .frame(height: 144)
                        .clipped()
                }
            }

            // Right column
            VStack(spacing: 2) {
                photoImage(p.count > 3 ? p[3] : p[0])
                    .frame(height: 144)
                    .clipped()
                photoImage(p.count > 4 ? p[4] : p[0])
                    .frame(height: 144)
                    .clipped()
            }
        }
        .frame(height: 290)
    }

    private func photoImage(_ url: String) -> some View {
        AsyncImage(url: URL(string: url)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(ClubRalleyTheme.Colors.sageGreen.opacity(0.5))
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen.opacity(0.3))
                )
        }
    }
}

// MARK: - Action Bar

struct PostActionBar: View {
    let post: ClubRalleyPost
    @Binding var isLiked: Bool
    @Binding var isReposted: Bool
    @Binding var likeCount: Int
    @Binding var commentCount: Int
    var heartScale: CGFloat = 1.0
    var onLike: () -> Void
    var onComment: () -> Void
    var onRepost: () -> Void
    var onShare: () -> Void

    var body: some View {
        HStack {
            // Heart
            Button(action: onLike) {
                HStack(spacing: 5) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isLiked ? ClubRalleyTheme.Colors.badgeRed : ClubRalleyTheme.Colors.inactiveIcon)
                        .scaleEffect(heartScale)
                    if likeCount > 0 {
                        Text("\(likeCount)")
                            .font(.system(size: 12, weight: .bold))
                            .fontDesign(.rounded)
                            .foregroundColor(isLiked ? ClubRalleyTheme.Colors.badgeRed : ClubRalleyTheme.Colors.inactiveIcon)
                    }
                }
            }

            Spacer()

            // Repost
            Button(action: onRepost) {
                Image(systemName: "arrow.2.squarepath")
                    .font(.system(size: 20))
                    .foregroundColor(isReposted ? ClubRalleyTheme.Colors.darkGreen : ClubRalleyTheme.Colors.inactiveIcon)
            }

            Spacer()

            // Comment
            Button(action: onComment) {
                HStack(spacing: 5) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 20))
                        .foregroundColor(ClubRalleyTheme.Colors.inactiveIcon)
                    if commentCount > 0 {
                        Text("\(commentCount)")
                            .font(.system(size: 12, weight: .bold))
                            .fontDesign(.rounded)
                            .foregroundColor(ClubRalleyTheme.Colors.inactiveIcon)
                    }
                }
            }

            Spacer()

            // Share
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20))
                    .foregroundColor(ClubRalleyTheme.Colors.inactiveIcon)
            }
        }
    }
}

