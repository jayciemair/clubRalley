//
//  UserProfileView.swift
//  Club Ralley
//
//  View for displaying other users' profiles
//

import SwiftUI

struct UserProfileView: View {
    let userId: UUID
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var friendshipService = FriendshipService()
    @StateObject private var messagingService = MessagingService()

    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    @State private var isFollowing = false
    @State private var isLoadingFollow = false
    @State private var showingMessages = false

    // Check if this is the current user's profile
    private var isOwnProfile: Bool {
        SupabaseManager.shared.currentUser?.id == userId
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile = userProfile {
                    VStack(spacing: 0) {
                        ProfileContentView(userProfile: profile)
                            .environmentObject(viewModel)

                        // Action buttons (only for other users' profiles)
                        if !isOwnProfile {
                            profileActionButtons
                        }
                    }
                } else if isLoading {
                    ProfileLoadingView()
                } else {
                    ProfileErrorView {
                        Task {
                            await loadProfile()
                        }
                    }
                }
            }
            .refreshable {
                await loadProfile()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            // TODO: Add ShareUtility.swift to Xcode project to enable sharing
                        }) {
                            Label("Share Profile", systemImage: "square.and.arrow.up")
                        }

                        if !isOwnProfile {
                            Button(role: .destructive, action: {
                                Task {
                                    await viewModel.blockUser(userId)
                                }
                            }) {
                                Label("Block User", systemImage: "hand.raised")
                            }

                            Button(role: .destructive, action: {
                                // Report user
                            }) {
                                Label("Report", systemImage: "exclamationmark.triangle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(ClubRalleyTheme.Colors.accent)
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
                                Button("Close") {
                                    showingMessages = false
                                }
                                .foregroundColor(ClubRalleyTheme.Colors.accent)
                            }
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

    // MARK: - Profile Action Buttons

    private var profileActionButtons: some View {
        HStack(spacing: 12) {
            // Follow/Unfollow button
            Button(action: { Task { await toggleFollow() } }) {
                HStack(spacing: 8) {
                    if isLoadingFollow {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: isFollowing ? Color(hex: "#2C4F40") : .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isFollowing ? "checkmark" : "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(isFollowing ? Color(hex: "#2C4F40") : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    isFollowing
                        ? Color.clear
                        : Color(hex: "#2C4F40")
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#2C4F40"), lineWidth: 2)
                )
                .cornerRadius(12)
            }
            .disabled(isLoadingFollow)

            // Message button
            Button(action: { showingMessages = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Message")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color(hex: "#2C4F40"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#2C4F40"), lineWidth: 2)
                )
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 32)
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

struct ProfileErrorView: View {
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: ClubRalleyTheme.Spacing.lg) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
            
            Text("Unable to load profile")
                .font(ClubRalleyTheme.Typography.headline)
                .foregroundColor(ClubRalleyTheme.Colors.text)
            
            Text("Please check your connection and try again")
                .font(ClubRalleyTheme.Typography.body)
                .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                onRetry()
            }
            .clubRalleyButtonStyle(.primary)
        }
        .padding(ClubRalleyTheme.Spacing.xl)
    }
}

// MARK: - Tappable Profile Avatar

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
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle()
                .fill(ClubRalleyTheme.Colors.sageGreen)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.4))
                        .foregroundColor(ClubRalleyTheme.Colors.accent)
                )
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Tappable Profile Name

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

// MARK: - Tappable Profile Header (combines avatar and name)

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
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(ClubRalleyTheme.Colors.sageGreen)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: avatarSize * 0.4))
                                .foregroundColor(ClubRalleyTheme.Colors.accent)
                        )
                }
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
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