//
//  UserProfileView.swift
//  Club Ralley
//
//  View for displaying other users' profiles — centered layout with Follow/Message
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
                    // Centered header
                    ProfileCenteredHeader(profile: profile)
                        .padding(.top, 16)

                    // Stats row
                    ProfileStatsRow(profile: profile)
                        .padding(.top, 20)

                    // Bio + credentials
                    ProfileBioSection(profile: profile)
                        .padding(.top, 16)

                    // Mutual friends (only on other profiles)
                    if !isOwnProfile && !profile.mutualFriends.isEmpty {
                        OtherProfileMutualFriends(mutualFriends: profile.mutualFriends)
                            .padding(.top, 12)
                            .padding(.horizontal, 24)
                    }

                    // Action buttons
                    if !isOwnProfile {
                        OtherProfileActionButtons(
                            isFollowing: $isFollowing,
                            isLoadingFollow: $isLoadingFollow,
                            onToggleFollow: { Task { await toggleFollow() } },
                            onMessage: { showingMessages = true }
                        )
                        .padding(.top, 16)
                    }

                    // My Sports (reuse from own profile)
                    SportCarouselSection(viewModel: viewModel)
                        .padding(.top, 24)

                    // Rally History
                    RalleyHistorySection(viewModel: viewModel)

                    // My Pics
                    if !profile.photos.isEmpty {
                        ProfilePhotosSection(photos: profile.photos)
                            .padding(.horizontal, 24)
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
        .background(Color(hex: "#F5F2EB"))
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
                        .foregroundColor(Color(hex: "#2D4A3E"))
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
                                .foregroundColor(Color(hex: "#2D4A3E"))
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

// MARK: - Mutual Friends Row (Other Profiles Only)

struct OtherProfileMutualFriends: View {
    let mutualFriends: [MutualFriend]

    var body: some View {
        HStack(spacing: 8) {
            // Overlapping avatar circles
            HStack(spacing: -8) {
                ForEach(Array(mutualFriends.prefix(3).enumerated()), id: \.offset) { index, friend in
                    AsyncImage(url: URL(string: friend.profileImageURL ?? "")) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color(hex: "#2D4A3E").opacity(0.2))
                            .overlay(
                                Text(String(friend.displayName.prefix(1)).uppercased())
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color(hex: "#2D4A3E"))
                            )
                    }
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    .zIndex(Double(3 - index))
                }
            }

            mutualFriendsText
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#6B7B6E"))

            Spacer()
        }
    }

    private var mutualFriendsText: Text {
        let friends = mutualFriends
        if friends.count == 1 {
            return Text("Also friends with ") + Text(friends[0].displayName).bold()
        } else if friends.count == 2 {
            return Text("Also friends with ") + Text(friends[0].displayName).bold() + Text(" and ") + Text(friends[1].displayName).bold()
        } else {
            let remaining = friends.count - 2
            return Text("Also friends with ") + Text(friends[0].displayName).bold() + Text(", ") + Text(friends[1].displayName).bold() + Text(", and ") + Text("\(remaining) others").bold()
        }
    }
}

// MARK: - Follow + Message Buttons (Other Profiles)

struct OtherProfileActionButtons: View {
    @Binding var isFollowing: Bool
    @Binding var isLoadingFollow: Bool
    let onToggleFollow: () -> Void
    let onMessage: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Follow / Following button
            Button(action: onToggleFollow) {
                HStack(spacing: 8) {
                    if isLoadingFollow {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: isFollowing ? Color(hex: "#2D4A3E") : .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isFollowing ? "checkmark" : "plus")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(isFollowing ? Color(hex: "#2D4A3E") : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isFollowing ? Color.clear : Color(hex: "#2D4A3E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "#2D4A3E"), lineWidth: 2)
                )
                .cornerRadius(20)
            }
            .disabled(isLoadingFollow)

            // Message button
            Button(action: onMessage) {
                HStack(spacing: 8) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 14))
                    Text("Message")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color(hex: "#2D4A3E"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "#2D4A3E"), lineWidth: 2)
                )
                .cornerRadius(20)
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Profile Error View

struct ProfileErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#6B7B6E"))

            Text("Unable to load profile")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#2D4A3E"))

            Text("Please check your connection and try again")
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "#6B7B6E"))
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
                .fill(Color(hex: "#2D4A3E").opacity(0.15))
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundColor(Color(hex: "#2D4A3E"))
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
                        .fill(Color(hex: "#2D4A3E").opacity(0.15))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: avatarSize * 0.4))
                                .foregroundColor(Color(hex: "#2D4A3E"))
                        )
                }
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#2D4A3E"))

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#6B7B6E"))
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
