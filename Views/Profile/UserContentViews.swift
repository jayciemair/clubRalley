//
//  UserContentViews.swift
//  Club Ralley
//
//  Views for displaying user's posts and ralleys in profile sections.
//

import SwiftUI

// MARK: - User Posts Section

struct UserPostsSection: View {
    @EnvironmentObject var postManager: PostManager
    @EnvironmentObject var ralleyManager: RalleyManager

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // My Ralleys Section
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("My Ralleys")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(ralleyManager.getUserRalleys().count)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#2C4F40"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#2C4F40").opacity(0.1))
                        .cornerRadius(12)
                }

                if ralleyManager.getUserRalleys().isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "sportscourt")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))

                        Text("No ralleys created yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)

                        Text("Create your first pickup game to see it here")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(16)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(ralleyManager.getUserRalleys()) { ralley in
                            UserRalleyPreview(ralley: ralley)
                        }
                    }
                }
            }

            // My Posts Section
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("My Posts")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(postManager.getUserPosts().count)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#2C4F40"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#2C4F40").opacity(0.1))
                        .cornerRadius(12)
                }

                if postManager.getUserPosts().isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))

                        Text("No posts yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)

                        Text("Share your athletic journey to see your posts here")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(16)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(postManager.getUserPosts()) { post in
                            UserPostPreview(post: post)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - User Ralley Preview

struct UserRalleyPreview: View {
    let ralley: ClubRalley

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: ralley.sport.lowercased() == "basketball" ? "basketball.fill" : "tennisball.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#2C4F40"))

                Text(ralley.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)

                Spacer()

                Text(ralley.cost == 0 ? "FREE" : "$\(ralley.cost)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#2C4F40"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#2C4F40").opacity(0.1))
                    .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(ralley.dateTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)

                Text(ralley.location.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }

            HStack {
                Text(ralley.timeUntilStart)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)

                Spacer()

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.system(size: 12))
                        Text("\(ralley.currentPlayers)/\(ralley.maxPlayers)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.gray)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - User Post Preview

struct UserPostPreview: View {
    let post: ClubRalleyPost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = post.title {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
            }

            Text(post.content)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.black)
                .lineLimit(3)

            HStack {
                Text(post.timeAgo)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)

                Spacer()

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.system(size: 12))
                        Text("\(post.likes)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.gray)

                    HStack(spacing: 4) {
                        Image(systemName: "message")
                            .font(.system(size: 12))
                        Text("\(post.comments)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.gray)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
