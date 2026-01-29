//
//  HomeFeedView.swift
//  Club Ralley
//
//  Home feed view displaying posts and upcoming ralleys.
//

import SwiftUI

// MARK: - Home Feed View

struct HomeFeedView: View {
    @EnvironmentObject var postManager: PostManager
    @EnvironmentObject var ralleyManager: RalleyManager

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Home")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                            Spacer()
                            Button(action: {}) {
                                Image(systemName: "bell")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(hex: "#2C4F40"))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }

                    // Upcoming Ralleys Section
                    if !ralleyManager.ralleys.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Upcoming Ralleys")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                Spacer()
                                Button(action: {}) {
                                    Text("View All")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "#2C4F40"))
                                }
                            }
                            .padding(.horizontal, 24)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(Array(ralleyManager.ralleys.prefix(3)), id: \.id) { ralley in
                                        CompactRalleyCard(ralley: ralley)
                                            .environmentObject(ralleyManager)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }

                    // Posts Feed
                    VStack(alignment: .leading, spacing: 16) {
                        if !postManager.posts.isEmpty {
                            HStack {
                                Text("Recent Posts")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                        }

                        if postManager.posts.isEmpty && ralleyManager.ralleys.isEmpty {
                            EmptyFeedView()
                        } else if postManager.posts.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "text.bubble")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))

                                Text("No posts yet")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)

                                Text("Follow athletes to see their posts here")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 40)
                            .padding(.vertical, 30)
                        } else {
                            ForEach(postManager.posts) { post in
                                PostCardView(post: post)
                                    .environmentObject(postManager)
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
                .padding(.top, 8)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Post Card View

struct PostCardView: View {
    let post: ClubRalleyPost
    @EnvironmentObject var postManager: PostManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: post.authorPhotoURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(hex: "#2C4F40"))
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    Text("\(post.authorUsername) • \(post.timeAgo)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            // Title (if exists)
            if let title = post.title {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }

            // Content
            Text(post.content)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .lineSpacing(4)

            // Images (if exist)
            if !post.images.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: post.images.count > 1 ? 2 : 1), spacing: 8) {
                    ForEach(post.images.indices, id: \.self) { index in
                        AsyncImage(url: URL(string: post.images[index])) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(height: post.images.count == 1 ? 200 : 150)
                        .clipped()
                        .cornerRadius(12)
                    }
                }
            }

            // Engagement Bar
            HStack(spacing: 24) {
                // Like Button
                Button(action: {
                    Task {
                        await postManager.toggleLike(for: post.id)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(post.isLiked ? .red : .gray)
                        Text("\(post.likes)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }

                // Comment Button
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "message")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        Text("\(post.comments)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }

                // Share Button
                Button(action: {}) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        Text("\(post.shares)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 24)
    }
}

// MARK: - Compact Ralley Card View

struct CompactRalleyCard: View {
    let ralley: ClubRalley
    @EnvironmentObject var ralleyManager: RalleyManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with sport icon
            HStack {
                Image(systemName: ralley.sport.lowercased() == "basketball" ? "basketball.fill" : "tennisball.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color(hex: "#2C4F40"))
                    .clipShape(Circle())

                Spacer()

                Text(ralley.cost == 0 ? "FREE" : "$\(ralley.cost)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#2C4F40"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#2C4F40").opacity(0.1))
                    .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(ralley.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)

                Text(ralley.dateTime.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)

                Text(ralley.location.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            // Player count and join
            HStack {
                Text("\(ralley.currentPlayers)/\(ralley.maxPlayers)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)

                Spacer()

                Button(action: {
                    Task {
                        await ralleyManager.joinRalley(ralley.id)
                    }
                }) {
                    Text("Join")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#2C4F40"))
                        .cornerRadius(8)
                }
                .disabled(ralley.currentPlayers >= ralley.maxPlayers)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .frame(width: 200)
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
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }
}
