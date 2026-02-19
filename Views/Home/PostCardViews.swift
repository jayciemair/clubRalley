//
//  PostCardViews.swift
//  Club Ralley
//
//  Post card components for the home feed
//

import SwiftUI
import UIKit

// MARK: - Figma Post Card

struct FigmaPostCard: View {
    let post: ClubRalleyPost
    @EnvironmentObject var postManager: PostManager
    @State private var showingComments = false
    @State private var showingReport = false
    @State private var showingRepost = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FigmaPostHeader(post: post)

            if post.visibility != .everyone {
                VisibilityBadge(visibility: post.visibility)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
            }

            if post.isRepost, let originalAuthor = post.originalAuthorName {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.2.squarepath").font(.system(size: 12))
                    Text("Reposted from \(originalAuthor)").font(.system(size: 12))
                }
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }

            if post.postType == .ralleyCompletion {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 14))
                    Text("Ralley Completed").font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(Color(hex: "#2C4F40"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "#2C4F40").opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }

            if let title = post.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#2C4F40"))
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
            }

            if let quoteComment = post.repostComment, !quoteComment.isEmpty {
                Text(quoteComment)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 4) {
                    Text(post.content)
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.7))
                        .lineLimit(3)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 6)
            } else {
                Text(post.content)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
            }

            if !post.taggedUserIds.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill").font(.system(size: 12))
                    Text("\(post.taggedUserIds.count) people tagged").font(.system(size: 13))
                }
                .foregroundColor(Color(hex: "#2C4F40"))
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }

            if !post.images.isEmpty {
                FigmaPostImage(images: post.images).padding(.top, 12)
            }

            FigmaActionButtons(post: post, showingComments: $showingComments, showingRepost: $showingRepost, postManager: postManager)
                .padding(.horizontal, 16).padding(.top, 10)

            Divider().padding(.top, 12)
        }
        .background(Color.white)
        .sheet(isPresented: $showingComments) { SimpleCommentsSheet(post: post).environmentObject(postManager) }
        .sheet(isPresented: $showingReport) { SimpleReportSheet(postId: post.id).environmentObject(postManager) }
        .sheet(isPresented: $showingRepost) { RepostSheet(post: post).environmentObject(postManager) }
    }
}

// MARK: - Figma Post Header

struct FigmaPostHeader: View {
    let post: ClubRalleyPost

    private var subtitleText: String {
        "Former D1 \(post.authorSport ?? "athlete") player at \(post.authorSchool ?? "University")"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Tappable profile photo
            if let authorId = post.authorId {
                NavigationLink(destination: UserProfileView(userId: authorId)) {
                    profileImage
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                profileImage
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    // Tappable author name
                    if let authorId = post.authorId {
                        NavigationLink(destination: UserProfileView(userId: authorId)) {
                            Text(post.authorName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Text(post.authorName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                    }

                    Spacer()

                    Text(post.timeAgo)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }

                Text(subtitleText)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    private var profileImage: some View {
        AsyncImage(url: URL(string: post.authorPhotoURL)) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle().fill(Color(hex: "#2C4F40"))
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }
}

// MARK: - Figma Social Proof

struct FigmaSocialProof: View {
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .overlay(
                            AsyncImage(url: URL(string: "https://picsum.photos/50/50?random=\(301+i)")) { img in
                                img.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle().fill(Color.gray)
                            }
                        )
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: CGFloat(i * 16))
                }
            }
            .frame(width: 64)

            Text("& your friends loved this post")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
        }
    }
}

// MARK: - Figma Action Buttons

struct FigmaActionButtons: View {
    let post: ClubRalleyPost
    @Binding var showingComments: Bool
    @Binding var showingRepost: Bool
    var postManager: PostManager

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { Task { await postManager.toggleLike(for: post.id) } }) {
                HStack(spacing: 4) {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(post.isLiked ? .red : .gray)
                    if post.likes > 0 {
                        Text("\(post.likes)").font(.system(size: 13)).foregroundColor(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            Button(action: { showingComments = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    if post.comments > 0 {
                        Text("\(post.comments)").font(.system(size: 13)).foregroundColor(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            Button(action: { showingRepost = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    if post.shares > 0 {
                        Text("\(post.shares)").font(.system(size: 13)).foregroundColor(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            Button(action: { ShareHelper.sharePost(post) }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Figma Post Image

struct FigmaPostImage: View {
    let images: [String]

    var body: some View {
        if let first = images.first {
            AsyncImage(url: URL(string: first)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.2))
            }
            .frame(height: 280)
            .clipped()
        }
    }
}

// MARK: - Share Helper

enum ShareHelper {
    static func sharePost(_ post: ClubRalleyPost) {
        var content = ""
        if let title = post.title, !title.isEmpty { content += "\(title)\n\n" }
        content += post.content + "\n\nShared from Club Ralley"

        let activityVC = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = scene.windows.first?.rootViewController else { return }
            var top = root
            while let presented = top.presentedViewController { top = presented }
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = top.view
                popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
            }
            top.present(activityVC, animated: true)
        }
    }
}
