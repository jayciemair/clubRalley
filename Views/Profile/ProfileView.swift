//
//  ProfileView.swift
//  Club Ralley
//
//  Main profile view implementing Figma design
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let userProfile = viewModel.currentUserProfile {
                    ProfileContentView(userProfile: userProfile)
                        .environmentObject(viewModel)
                } else if viewModel.isLoading {
                    ProfileLoadingView()
                } else {
                    ProfileErrorView {
                        Task { await viewModel.loadCurrentUserProfile() }
                    }
                }
            }
            .refreshable {
                await viewModel.loadCurrentUserProfile()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingSettings = true
                    }
                    .foregroundColor(ClubRalleyTheme.Colors.accent)
                }
            }
            .sheet(isPresented: $showingSettings) {
                ProfileSettingsView()
            }
        }
        .task {
            await viewModel.loadCurrentUserProfile()
        }
    }
}

struct ProfileContentView: View {
    let userProfile: UserProfile
    @EnvironmentObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: ClubRalleyTheme.Spacing.xl) {
            // Profile Header
            ProfileHeaderView(userProfile: userProfile)
            
            // Action Buttons (only show for other users)
            if !viewModel.isCurrentUser(userProfile.user.id) {
                ProfileActionButtonsView(userProfile: userProfile)
                    .environmentObject(viewModel)
            }
            
            // Teams Section
            if !userProfile.teams.isEmpty {
                ProfileTeamsSection(teams: userProfile.teams)
            }
            
            // Photos Section
            if !userProfile.photos.isEmpty {
                ProfilePhotosSection(photos: userProfile.photos)
            }
            
            Spacer(minLength: 100) // Bottom spacing for tab bar
        }
        .padding(.horizontal, ClubRalleyTheme.Spacing.md)
    }
}

// MARK: - Profile Header

struct ProfileHeaderView: View {
    let userProfile: UserProfile
    
    var body: some View {
        VStack(spacing: ClubRalleyTheme.Spacing.lg) {
            // Profile photo and location
            HStack {
                Spacer()
                
                VStack {
                    // Profile photo
                    AsyncImage(url: URL(string: userProfile.user.profilePhotoURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(ClubRalleyTheme.Colors.sageGreen)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(ClubRalleyTheme.Colors.accent)
                            )
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    
                    // Location
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(ClubRalleyTheme.Colors.accent)
                            .font(.caption)
                        Text(userProfile.user.displayLocation)
                            .font(ClubRalleyTheme.Typography.caption)
                            .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                    }
                }
                
                Spacer()
            }
            
            // Name and handles
            VStack(spacing: ClubRalleyTheme.Spacing.sm) {
                Text(userProfile.user.fullName)
                    .font(ClubRalleyTheme.Typography.title1)
                    .foregroundColor(ClubRalleyTheme.Colors.text)
                
                HStack(spacing: ClubRalleyTheme.Spacing.md) {
                    if let instagram = userProfile.socialInfo.instagramHandle {
                        SocialHandleView(platform: "instagram", handle: instagram)
                    }
                    
                    if let linkedin = userProfile.socialInfo.linkedinHandle {
                        SocialHandleView(platform: "linkedin", handle: linkedin)
                    }
                }
            }
            
            // Stats
            HStack {
                StatView(
                    number: userProfile.stats.followersCount,
                    label: "followers"
                )
                
                Spacer()
                
                StatView(
                    number: userProfile.stats.gamesPlayed,
                    label: "games played"
                )
                
                Spacer()
                
                StatView(
                    number: userProfile.stats.wins,
                    label: "wins"
                )
            }
            
            // Athlete credentials
            if let athleteInfo = userProfile.user.athleteInfo,
               userProfile.user.isVerifiedAthlete {
                AthleteCredentialsView(athleteInfo: athleteInfo)
            }
            
            // Mutual friends
            if !userProfile.mutualFriends.isEmpty {
                MutualFriendsView(mutualFriends: userProfile.mutualFriends)
            }
        }
    }
}

// MARK: - Supporting Views

struct SocialHandleView: View {
    let platform: String
    let handle: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .foregroundColor(ClubRalleyTheme.Colors.accent)
            Text("@\(handle)")
                .font(ClubRalleyTheme.Typography.caption)
                .foregroundColor(ClubRalleyTheme.Colors.accent)
        }
    }
    
    private var iconName: String {
        switch platform {
        case "instagram": return "camera.fill"
        case "linkedin": return "briefcase.fill"
        default: return "link"
        }
    }
}

struct StatView: View {
    let number: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(number)")
                .font(ClubRalleyTheme.Typography.title1)
                .foregroundColor(ClubRalleyTheme.Colors.text)
            
            Text(label)
                .font(ClubRalleyTheme.Typography.caption)
                .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
        }
    }
}

struct AthleteCredentialsView: View {
    let athleteInfo: AthleteInfo
    
    var body: some View {
        VStack(spacing: ClubRalleyTheme.Spacing.sm) {
            HStack {
                if athleteInfo.verificationStatus == .verified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(ClubRalleyTheme.Colors.success)
                }
                
                Text("Former \(athleteInfo.sport.name) player at **\(athleteInfo.school.name)**")
                    .font(ClubRalleyTheme.Typography.subheadline)
                    .foregroundColor(ClubRalleyTheme.Colors.text)
                    .multilineTextAlignment(.center)
            }
            
            Text("Class of 2025") // This would come from athlete info
                .font(ClubRalleyTheme.Typography.footnote)
                .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
        }
    }
}

struct MutualFriendsView: View {
    let mutualFriends: [MutualFriend]
    
    var body: some View {
        HStack {
            Text("Also friends with:")
                .font(ClubRalleyTheme.Typography.footnote)
                .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
            
            HStack(spacing: -8) {
                ForEach(Array(mutualFriends.prefix(3).enumerated()), id: \.offset) { index, friend in
                    AsyncImage(url: URL(string: friend.profileImageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(ClubRalleyTheme.Colors.sageGreen)
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(ClubRalleyTheme.Colors.white, lineWidth: 2)
                    )
                    .zIndex(Double(3 - index))
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Action Buttons

struct ProfileActionButtonsView: View {
    let userProfile: UserProfile
    @EnvironmentObject var viewModel: ProfileViewModel
    @StateObject private var messagingService = MessagingService()
    @State private var showingDirectMessage = false
    @State private var conversation: DirectConversation?
    @State private var isLoadingMessage = false

    var body: some View {
        HStack(spacing: ClubRalleyTheme.Spacing.md) {
            // Follow/Following Button
            Button(action: {
                Task {
                    await viewModel.toggleFollow(userProfile.user.id)
                }
            }) {
                Text(followButtonText)
                    .frame(maxWidth: .infinity)
            }
            .clubRalleyButtonStyle(followButtonStyle)

            // Message Button
            Button(action: {
                Task { await openDirectMessage() }
            }) {
                HStack {
                    if isLoadingMessage {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text("Message")
                }
                .frame(maxWidth: .infinity)
            }
            .clubRalleyButtonStyle(.outline)
            .disabled(isLoadingMessage)
        }
        .sheet(isPresented: $showingDirectMessage) {
            if let conversation = conversation {
                NavigationStack {
                    DirectMessageView(conversation: conversation, messagingService: messagingService)
                }
            }
        }
    }

    private var followButtonText: String {
        userProfile.isFollowedByCurrentUser == true ? "Following" : "Follow"
    }

    private var followButtonStyle: ClubRalleyButtonStyle {
        userProfile.isFollowedByCurrentUser == true ? .secondary : .primary
    }

    private func openDirectMessage() async {
        isLoadingMessage = true
        do {
            conversation = try await messagingService.getOrCreateConversation(with: userProfile.user.id)
            showingDirectMessage = true
        } catch {
            print("Failed to open conversation: \(error)")
        }
        isLoadingMessage = false
    }
}

// MARK: - Loading View

struct ProfileLoadingView: View {
    var body: some View {
        VStack(spacing: ClubRalleyTheme.Spacing.lg) {
            // Profile photo placeholder
            Circle()
                .fill(ClubRalleyTheme.Colors.sageGreen)
                .frame(width: 120, height: 120)
                .shimmer()
            
            // Name placeholder
            RoundedRectangle(cornerRadius: ClubRalleyTheme.CornerRadius.small)
                .fill(ClubRalleyTheme.Colors.sageGreen)
                .frame(width: 200, height: 24)
                .shimmer()
            
            // Stats placeholder
            HStack {
                ForEach(0..<3) { _ in
                    VStack {
                        Circle()
                            .fill(ClubRalleyTheme.Colors.sageGreen)
                            .frame(width: 40, height: 40)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(ClubRalleyTheme.Colors.sageGreen)
                            .frame(width: 60, height: 12)
                    }
                    .shimmer()
                    
                    if let _ = [0, 1].first(where: { $0 == 0 }) {
                        Spacer()
                    }
                }
            }
            
            Text("Loading profile...")
                .font(ClubRalleyTheme.Typography.body)
                .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
        }
        .padding(ClubRalleyTheme.Spacing.lg)
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 300
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Preview

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}