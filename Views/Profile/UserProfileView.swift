//
//  UserProfileView.swift
//  Club Ralley
//
//  View for displaying other users' profiles — horizontal header with Follow/Message/Invite
//

import SwiftUI

struct UserProfileView: View {
    let userId: UUID
    @StateObject private var viewModel = ProfileViewModel()
    private var friendshipService: FriendshipService { ServiceContainer.shared.friendshipService }
    private var messagingService: MessagingService { ServiceContainer.shared.messagingService }

    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    @State private var isFollowing = false
    @State private var isLoadingFollow = false
    @State private var showingMessages = false

    private var isOwnProfile: Bool {
        SupabaseManager.shared.currentUser?.id == userId
    }

    var body: some View {
        ScrollView {
            if let profile = userProfile {
                VStack(spacing: 0) {
                    // Centered header (avatar, name, @username, stats)
                    ProfileHeaderRow(profile: profile)

                    // Bio (centered)
                    ProfileBioSection(profile: profile)
                        .padding(.bottom, 14)

                    // Mutual friends row
                    if !isOwnProfile && !profile.mutualFriends.isEmpty {
                        ProfileFriendsRow(mutualFriends: profile.mutualFriends)
                            .padding(.bottom, 16)
                    }

                    // Action buttons
                    if !isOwnProfile {
                        ProfileActionButtons(
                            isFollowing: $isFollowing,
                            isLoadingFollow: $isLoadingFollow,
                            onToggleFollow: { Task { await toggleFollow() } },
                            onMessage: { showingMessages = true },
                            onInvite: { /* TODO: Invite to ralley flow */ }
                        )
                    }

                    // Divider
                    ProfileDivider()
                        .padding(.top, 16)

                    // My Sports
                    SportCarouselSection(viewModel: viewModel)
                        .padding(.top, 16)

                    // Rally History
                    RalleyHistorySection(viewModel: viewModel)

                    // My Pics
                    if !profile.photos.isEmpty {
                        ProfilePhotosSection(photos: profile.photos)
                            .padding(.horizontal, 22)
                            .padding(.bottom, 24)
                    }

                    Spacer(minLength: 100)
                }
            } else if isLoading {
                ProfileTabLoadingView()
            } else {
                ProfileErrorView {
                    Task { await loadProfile() }
                }
            }
        }
        .background(Color(hex: "#f6f5f1"))
        .refreshable {
            await loadProfile()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {}) {
                        Label("Share Profile", systemImage: "square.and.arrow.up")
                    }

                    if !isOwnProfile {
                        Button(role: .destructive, action: {
                            Task { await viewModel.blockUser(userId) }
                        }) {
                            Label("Block User", systemImage: "hand.raised")
                        }

                        Button(role: .destructive, action: {}) {
                            Label("Report", systemImage: "exclamationmark.triangle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
        .sheet(isPresented: $showingMessages) {
            if let profile = userProfile {
                NavigationStack {
                    DirectMessageView(
                        conversation: createConversation(from: profile),
                        messagingService: messagingService
                    )
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") { showingMessages = false }
                                .foregroundColor(Color(hex: "#2C4F40"))
                        }
                    }
                }
            }
        }
        .task {
            await loadProfile()
            await checkFollowStatus()
        }
    }

    // MARK: - Helper Methods

    private func loadProfile() async {
        isLoading = true
        userProfile = await viewModel.loadUserProfile(userId)
        isLoading = false
    }

    private func checkFollowStatus() async {
        guard !isOwnProfile else { return }
        isFollowing = (try? await friendshipService.isFollowing(userId)) ?? false
    }

    private func toggleFollow() async {
        isLoadingFollow = true
        do {
            if isFollowing {
                try await friendshipService.unfollowUser(userId)
                isFollowing = false
            } else {
                try await friendshipService.followUser(userId)
                isFollowing = true
            }
        } catch {
            print("Failed to toggle follow: \(error)")
        }
        isLoadingFollow = false
    }

    private func createConversation(from profile: UserProfile) -> DirectConversation {
        DirectConversation(
            id: userId,
            otherUserId: userId,
            otherUserName: "\(profile.user.firstName) \(profile.user.lastName)",
            otherUserUsername: profile.user.username,
            otherUserPhotoURL: profile.user.profilePhotoURL,
            isVerified: profile.socialInfo.isVerifiedAthlete,
            lastMessage: nil,
            lastMessageAt: nil,
            unreadCount: 0,
            createdAt: Date()
        )
    }
}

// MARK: - Profile Error View

struct ProfileErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#7a8a81"))

            Text("Unable to load profile")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.black)

            Text("Please check your connection and try again")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "#7a8a81"))
                .multilineTextAlignment(.center)

            Button("Try Again") { onRetry() }
                .clubRalleyButtonStyle(.primary)
        }
        .padding(32)
    }
}

// MARK: - Tappable Profile Components

struct TappableProfileAvatar: View {
    let userId: UUID
    let imageURL: String?
    let size: CGFloat
    let showNavigationLink: Bool

    init(userId: UUID, imageURL: String?, size: CGFloat = 50, showNavigationLink: Bool = true) {
        self.userId = userId
        self.imageURL = imageURL
        self.size = size
        self.showNavigationLink = showNavigationLink
    }

    var body: some View {
        if showNavigationLink {
            NavigationLink(destination: UserProfileView(userId: userId)) {
                avatarContent
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            avatarContent
        }
    }

    private var avatarContent: some View {
        AsyncImage(url: URL(string: imageURL ?? "")) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle()
                .fill(Color(hex: "#2C4F40").opacity(0.15))
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundColor(Color(hex: "#2C4F40"))
                )
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

struct TappableProfileName: View {
    let userId: UUID
    let name: String
    let font: Font
    let color: Color

    init(userId: UUID, name: String, font: Font = .headline, color: Color = .black) {
        self.userId = userId
        self.name = name
        self.font = font
        self.color = color
    }

    var body: some View {
        NavigationLink(destination: UserProfileView(userId: userId)) {
            Text(name)
                .font(font)
                .foregroundColor(color)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TappableProfileHeader: View {
    let userId: UUID
    let name: String
    let subtitle: String?
    let imageURL: String?
    let avatarSize: CGFloat

    init(userId: UUID, name: String, subtitle: String? = nil, imageURL: String?, avatarSize: CGFloat = 50) {
        self.userId = userId
        self.name = name
        self.subtitle = subtitle
        self.imageURL = imageURL
        self.avatarSize = avatarSize
    }

    var body: some View {
        NavigationLink(destination: UserProfileView(userId: userId)) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: imageURL ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(hex: "#2C4F40").opacity(0.15))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: avatarSize * 0.4))
                                .foregroundColor(Color(hex: "#2C4F40"))
                        )
                }
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.black)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "#7a8a81"))
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(userId: UUID())
    }
}
