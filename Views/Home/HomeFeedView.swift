//
//  HomeFeedView.swift
//  Club Ralley
//
//  Home feed view with Figma-styled posts, search header, and repost functionality.
//

import SwiftUI
import UIKit

// MARK: - Home Feed View

struct HomeFeedView: View {
    @EnvironmentObject var postManager: PostManager
    @EnvironmentObject var ralleyManager: RalleyManager
    @State private var showingNotifications = false
    @State private var showingMessages = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    FeedSearchHeader(searchText: $searchText, showingNotifications: $showingNotifications, showingMessages: $showingMessages)

                    // Loading state
                    if postManager.isLoading && postManager.posts.isEmpty {
                        FeedLoadingView()
                    } else if let error = postManager.error, postManager.posts.isEmpty {
                        FeedErrorView(error: error) {
                            Task {
                                await postManager.refreshPosts()
                            }
                        }
                    } else {
                        ForEach(postManager.posts) { post in
                            FigmaPostCard(post: post).environmentObject(postManager)
                        }
                        if postManager.posts.isEmpty { EmptyFeedView() }
                    }

                    Spacer(minLength: 100)
                }
            }
            .refreshable {
                await postManager.refreshPosts()
            }
            .background(Color.white).navigationBarHidden(true)
            .sheet(isPresented: $showingNotifications) { SimpleNotificationsView() }
        }
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
            // Header skeleton
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 16)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 180, height: 12)
                }

                Spacer()
            }
            .padding(.horizontal, 16)

            // Content skeleton
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 14)
            }
            .padding(.horizontal, 16)

            // Actions skeleton
            HStack {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 30, height: 20)
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

// MARK: - Feed Search Header

struct FeedSearchHeader: View {
    @Binding var searchText: String
    @Binding var showingNotifications: Bool
    @Binding var showingMessages: Bool

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 16, weight: .medium)).foregroundColor(Color(hex: "#2C4F40"))
                TextField("Search for teammates and leagues", text: $searchText).font(.system(size: 15))
            }.padding(.horizontal, 16).padding(.vertical, 12).background(Color(hex: "#F5F5F5")).cornerRadius(24)
            Button(action: { showingNotifications = true }) { Image(systemName: "bell").font(.system(size: 20, weight: .medium)).foregroundColor(.black) }
            Button(action: { showingMessages = true }) { Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 20, weight: .medium)).foregroundColor(.black) }
        }.padding(.horizontal, 16).padding(.vertical, 12)
    }
}

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

            // Visibility badge for non-everyone posts
            if post.visibility != .everyone {
                VisibilityBadge(visibility: post.visibility)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            // Repost indicator
            if post.isRepost, let originalAuthor = post.originalAuthorName {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: 12))
                    Text("Reposted from \(originalAuthor)")
                        .font(.system(size: 12))
                }
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            // Ralley completion badge
            if post.postType == .ralleyCompletion {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                    Text("Ralley Completed")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(Color(hex: "#2C4F40"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "#2C4F40").opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            if let title = post.title, !title.isEmpty {
                Text(title).font(.system(size: 20, weight: .bold)).foregroundColor(Color(hex: "#2C4F40")).padding(.horizontal, 16).padding(.top, 12)
            }

            // Quote comment (for reposts)
            if let quoteComment = post.repostComment, !quoteComment.isEmpty {
                Text(quoteComment)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // Original post preview
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
                .padding(.top, 8)
            } else {
                Text(post.content).font(.system(size: 16)).foregroundColor(.black).padding(.horizontal, 16).padding(.top, 8)
            }

            // Tagged users
            if !post.taggedUserIds.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12))
                    Text("\(post.taggedUserIds.count) people tagged")
                        .font(.system(size: 13))
                }
                .foregroundColor(Color(hex: "#2C4F40"))
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            FigmaSocialProof().padding(.horizontal, 16).padding(.top, 16)
            FigmaActionButtons(post: post, showingComments: $showingComments, showingRepost: $showingRepost, postManager: postManager).padding(.horizontal, 16).padding(.top, 12)
            if !post.images.isEmpty { FigmaPostImage(images: post.images).padding(.top, 16) }
            Divider().padding(.top, 16)
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
            // Profile avatar
            AsyncImage(url: URL(string: post.authorPhotoURL)) { image in image.resizable().aspectRatio(contentMode: .fill) } placeholder: { Circle().fill(Color(hex: "#2C4F40")) }
                .frame(width: 50, height: 50).clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                // Author name
                Text(post.authorName).font(.system(size: 16, weight: .bold)).foregroundColor(.black)

                Text(subtitleText).font(.system(size: 14)).foregroundColor(.gray)
                HStack(spacing: 4) {
                    Text(post.timeAgo).font(.system(size: 14)).foregroundColor(.gray)
                    Text("-").font(.system(size: 14)).foregroundColor(.gray)
                    Text(post.authorLocation ?? "Chicago, IL").font(.system(size: 14, weight: .medium)).italic().foregroundColor(Color(hex: "#2C4F40"))
                }
            }
            Spacer()
        }.padding(.horizontal, 16).padding(.top, 16)
    }
}

// MARK: - Figma Social Proof

struct FigmaSocialProof: View {
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle().fill(Color.gray.opacity(0.3)).frame(width: 24, height: 24)
                        .overlay(AsyncImage(url: URL(string: "https://picsum.photos/50/50?random=\(301+i)")) { img in img.resizable().aspectRatio(contentMode: .fill) } placeholder: { Circle().fill(Color.gray) })
                        .clipShape(Circle()).overlay(Circle().stroke(Color.white, lineWidth: 2)).offset(x: CGFloat(i * 16))
                }
            }.frame(width: 64)
            Text("& your friends loved this post").font(.system(size: 14)).foregroundColor(.gray)
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
            // Like Button
            Button(action: { Task { await postManager.toggleLike(for: post.id) } }) {
                HStack(spacing: 4) {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(post.isLiked ? .red : Color(hex: "#2C4F40"))
                    if post.likes > 0 {
                        Text("\(post.likes)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }.frame(maxWidth: .infinity)

            // Repost Button
            Button(action: { showingRepost = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(post.isReposted ? Color(hex: "#2C4F40") : Color(hex: "#2C4F40"))
                    if post.shares > 0 {
                        Text("\(post.shares)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }.frame(maxWidth: .infinity)

            // Comment Button
            Button(action: { showingComments = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color(hex: "#2C4F40"))
                    if post.comments > 0 {
                        Text("\(post.comments)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }.frame(maxWidth: .infinity)

            // Share Button
            Button(action: { ShareHelper.sharePost(post) }) {
                Image(systemName: "arrowshape.turn.up.right")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }.frame(maxWidth: .infinity)
        }.padding(.vertical, 8)
    }
}

// MARK: - Figma Post Image

struct FigmaPostImage: View {
    let images: [String]
    var body: some View {
        if let first = images.first {
            AsyncImage(url: URL(string: first)) { image in image.resizable().aspectRatio(contentMode: .fill) } placeholder: { Rectangle().fill(Color.gray.opacity(0.2)) }
            .frame(height: 280).clipped()
        }
    }
}

// MARK: - Empty Feed View

struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sportscourt").font(.system(size: 60)).foregroundColor(Color(hex: "#2C4F40").opacity(0.6))
            Text("Welcome to Club Ralley!").font(.system(size: 24, weight: .bold)).foregroundColor(.black)
            Text("Start following athletes and join ralleys to see posts in your feed").font(.system(size: 16)).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 40)
        }.padding(.top, 60)
    }
}

// MARK: - Share Helper

enum ShareHelper {
    static func sharePost(_ post: ClubRalleyPost) {
        var content = ""; if let title = post.title, !title.isEmpty { content += "\(title)\n\n" }
        content += post.content + "\n\nShared from Club Ralley"
        let activityVC = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let root = scene.windows.first?.rootViewController else { return }
            var top = root; while let presented = top.presentedViewController { top = presented }
            if let popover = activityVC.popoverPresentationController { popover.sourceView = top.view; popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0) }
            top.present(activityVC, animated: true)
        }
    }
}

// MARK: - Notifications Sheet

struct SimpleNotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    private let items = [("Sarah Wilson started following you", "person.badge.plus", false), ("Mike Johnson commented on your post", "message.fill", false), ("Emily Chen liked your post", "heart.fill", true), ("Your ralley starts in 1 hour", "clock.fill", true)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items.indices, id: \.self) { i in
                        HStack(spacing: 12) {
                            Image(systemName: items[i].1).font(.system(size: 20)).foregroundColor(Color(hex: "#2C4F40")).frame(width: 44, height: 44).background(Color(hex: "#2C4F40").opacity(0.1)).clipShape(Circle())
                            Text(items[i].0).font(.system(size: 15)); Spacer()
                            if !items[i].2 { Circle().fill(Color(hex: "#2C4F40")).frame(width: 10, height: 10) }
                        }.padding(.horizontal, 16).padding(.vertical, 14).background(items[i].2 ? Color.clear : Color(hex: "#2C4F40").opacity(0.05))
                        Divider().padding(.leading, 72)
                    }
                }
            }.navigationTitle("Notifications").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() }.foregroundColor(Color(hex: "#2C4F40")) } }
        }
    }
}

// MARK: - Comments Sheet

struct SimpleCommentsSheet: View {
    let post: ClubRalleyPost; @EnvironmentObject var postManager: PostManager; @Environment(\.dismiss) private var dismiss; @State private var text = ""
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if postManager.isLoadingComments { ProgressView().padding(.top, 40) }
                        else if postManager.selectedPostComments.isEmpty {
                            VStack(spacing: 16) { Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 48)).foregroundColor(Color(hex: "#2C4F40").opacity(0.5)); Text("No comments yet").font(.system(size: 18, weight: .semibold)); Text("Be the first!").font(.system(size: 15)).foregroundColor(.gray) }.padding(.top, 60)
                        } else {
                            ForEach(postManager.selectedPostComments) { c in
                                HStack(alignment: .top, spacing: 12) { Circle().fill(Color(hex: "#2C4F40")).frame(width: 36, height: 36); VStack(alignment: .leading, spacing: 4) { Text(c.user?.firstName ?? "User").font(.system(size: 14, weight: .semibold)); Text(c.content).font(.system(size: 15)) }; Spacer() }.padding(12).background(Color.gray.opacity(0.05)).cornerRadius(12)
                            }
                        }
                    }.padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 100)
                }
                VStack(spacing: 0) { Divider(); HStack(spacing: 12) { TextField("Add a comment...", text: $text).padding(.horizontal, 16).padding(.vertical, 12).background(Color.gray.opacity(0.1)).cornerRadius(24); Button(action: { let c = text.trimmingCharacters(in: .whitespacesAndNewlines); guard !c.isEmpty else { return }; Task { await postManager.addComment(to: post.id, content: c); text = "" } }) { Image(systemName: "paperplane.fill").font(.system(size: 20)).foregroundColor(text.isEmpty ? .gray : Color(hex: "#2C4F40")) }.disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }.padding(.horizontal, 16).padding(.vertical, 12).background(Color.white) }
            }.navigationTitle("Comments").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() }.foregroundColor(Color(hex: "#2C4F40")) } }
        }.onAppear { Task { await postManager.loadComments(for: post.id) } }
    }
}

// MARK: - Report Sheet

struct SimpleReportSheet: View {
    let postId: UUID; @EnvironmentObject var postManager: PostManager; @Environment(\.dismiss) private var dismiss; @State private var sel: String?; @State private var done = false
    private let reasons = ["Spam", "Harassment", "Inappropriate Content", "Other"]
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) { Text("Why are you reporting this?").font(.system(size: 18, weight: .semibold)); Text("Your report is anonymous.").font(.system(size: 14)).foregroundColor(.gray) }.frame(maxWidth: .infinity, alignment: .leading).padding(20); Divider()
                ScrollView { VStack(spacing: 0) { ForEach(reasons, id: \.self) { r in Button(action: { sel = r }) { HStack { Text(r).font(.system(size: 16)).foregroundColor(.black); Spacer(); Image(systemName: sel == r ? "checkmark.circle.fill" : "circle").foregroundColor(sel == r ? Color(hex: "#2C4F40") : .gray) }.padding(.horizontal, 20).padding(.vertical, 16) }; Divider().padding(.leading, 20) } } }
                VStack(spacing: 0) { Divider(); Button(action: { guard let r = sel else { return }; Task { await postManager.reportPost(postId, reason: r); done = true } }) { Text("Submit").font(.system(size: 17, weight: .semibold)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16).background(sel != nil ? Color(hex: "#2C4F40") : Color.gray.opacity(0.3)).cornerRadius(12) }.disabled(sel == nil).padding(20) }
            }.navigationTitle("Report Post").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(Color(hex: "#2C4F40")) } }.alert("Submitted", isPresented: $done) { Button("OK") { dismiss() } } message: { Text("Thank you for your report.") }
        }
    }
}
