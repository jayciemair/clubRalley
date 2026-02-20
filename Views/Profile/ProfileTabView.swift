//
//  ProfileTabView.swift
//  Club Ralley
//
//  Profile tab — horizontal header layout, sport carousel, photo grid
//

import SwiftUI

// MARK: - Profile Tab View

struct ProfileTabView: View {
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showingSettings = false
    @State private var showingEditProfile = false

    var body: some View {
        Group {
            if profileViewModel.isLoading && profileViewModel.currentUserProfile == nil {
                ProfileTabLoadingView()
            } else if profileViewModel.currentUserProfile != nil {
                ProfileTabContentView(
                    profileViewModel: profileViewModel,
                    showingEditProfile: $showingEditProfile
                )
            } else {
                ProfileEmptyView()
            }
        }
        .background(Color(hex: "#f6f5f1"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            ProfileSettingsView()
        }
        .sheet(isPresented: $showingEditProfile, onDismiss: {
            Task {
                await profileViewModel.loadCurrentUserProfile(force: true)
            }
        }) {
            NavigationStack {
                EditProfileView()
            }
        }
        .task {
            await profileViewModel.loadCurrentUserProfile()
        }
        .refreshable {
            await profileViewModel.loadCurrentUserProfile(force: true)
        }
    }
}

// MARK: - Profile Loading View (Skeleton)

struct ProfileTabLoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header skeleton — horizontal
                HStack(alignment: .top, spacing: 14) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 86, height: 86)

                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 140, height: 22)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 90, height: 14)

                        HStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { _ in
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 28, height: 22)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.12))
                                        .frame(width: 40, height: 10)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.top, 4)
                    }
                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)

                // Bio skeleton
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 13)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 120, height: 13)
                }
                .padding(.horizontal, 22)

                // Button skeleton
                RoundedRectangle(cornerRadius: 50)
                    .fill(Color.gray.opacity(0.12))
                    .frame(height: 46)
                    .padding(.horizontal, 22)

                // Sport cards skeleton
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.gray.opacity(0.12))
                            .frame(width: 130, height: 150)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
            }
        }
        .background(Color(hex: "#f6f5f1"))
        .opacity(isAnimating ? 0.6 : 1.0)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Profile Empty View

struct ProfileEmptyView: View {
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#2C4F40"))
                .scaleEffect(isVisible ? 1 : 0.5)
                .opacity(isVisible ? 1 : 0)

            Text("No Profile Found")
                .font(.system(size: 22, weight: .bold))
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

            Text("Complete onboarding to set up your profile")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#7a8a81"))
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

            Button(action: {}) {
                Text("Complete Setup")
            }
            .clubRalleyButtonStyle(.primary)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Profile Content View

struct ProfileTabContentView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var showingEditProfile: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let profile = profileViewModel.currentUserProfile {
                    // Horizontal header (avatar + name + stats)
                    ProfileHeaderRow(profile: profile)

                    // Bio
                    ProfileBioSection(profile: profile)
                        .padding(.top, 16)

                    // Edit Profile button
                    ProfileEditButton(showingEditProfile: $showingEditProfile)
                        .padding(.top, 14)

                    // Divider
                    ProfileDivider()
                        .padding(.top, 16)

                    // My Sports
                    SportCarouselSection(viewModel: profileViewModel)
                        .padding(.top, 16)

                    // Rally History
                    RalleyHistorySection(viewModel: profileViewModel)

                    // My Pics
                    if !profile.photos.isEmpty {
                        ProfilePhotosSection(photos: profile.photos)
                            .padding(.horizontal, 22)
                            .padding(.bottom, 24)
                    } else {
                        ProfilePhotosEmptySection()
                            .padding(.horizontal, 22)
                            .padding(.bottom, 24)
                    }
                }
                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - Profile Header Row (Horizontal: Avatar Left, Info Right)

struct ProfileHeaderRow: View {
    let profile: UserProfile

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Avatar
            AsyncImage(url: URL(string: profile.user.profilePhotoURL ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color(hex: "#2C4F40"))
                    .overlay(
                        Text(profile.user.initials)
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 86, height: 86)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(hex: "#2C4F40"), lineWidth: 3))

            // Name + Location + Stats
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.user.fullName)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: "#2C4F40"))

                Text(profile.user.locationDisplay)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#7a8a81"))

                // Stats row
                ProfileStatsRow(profile: profile)
                    .padding(.top, 12)
            }
            .padding(.top, 6)

            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }
}

// MARK: - Stats Row (Inline — Friends | Ralleys | Posts)

struct ProfileStatsRow: View {
    let profile: UserProfile

    var body: some View {
        HStack(spacing: 0) {
            ProfileStat(value: profile.stats.followersCount, label: "Friends")
                .frame(maxWidth: .infinity)
            ProfileStat(value: profile.stats.ralleysAttended, label: "Ralleys")
                .frame(maxWidth: .infinity)
            ProfileStat(value: profile.stats.postsCount, label: "Posts")
                .frame(maxWidth: .infinity)
        }
    }
}

struct ProfileStat: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(Color(hex: "#2C4F40"))
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#7a8a81"))
        }
    }
}

// MARK: - Bio Section

struct ProfileBioSection: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            // College credentials as inline text
            if profile.user.playedCollegeSport, let collegeInfo = profile.user.collegeAthleteInfo {
                (Text("Former \(collegeInfo.division.shortName) \(collegeInfo.sport.lowercased()) player at ")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#3a3a3a"))
                +
                Text(collegeInfo.school)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "#3a3a3a")))
                .lineSpacing(4)
            }

            // Bio text
            if let bio = profile.user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#3a3a3a"))
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 22)
    }
}

// MARK: - Friends Row (Overlapping Avatars + Text)

struct ProfileFriendsRow: View {
    let mutualFriends: [MutualFriend]

    var body: some View {
        HStack(spacing: 10) {
            // Overlapping avatar circles
            HStack(spacing: -8) {
                ForEach(Array(mutualFriends.prefix(3).enumerated()), id: \.offset) { index, friend in
                    AsyncImage(url: URL(string: friend.profileImageURL ?? "")) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color(hex: "#2C4F40").opacity(0.2))
                            .overlay(
                                Text(String(friend.displayName.prefix(1)).uppercased())
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#2C4F40"))
                            )
                    }
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(hex: "#f6f5f1"), lineWidth: 2))
                    .zIndex(Double(3 - index))
                }
            }

            friendsText
                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "#7a8a81"))

            Spacer()
        }
        .padding(.horizontal, 22)
    }

    private var friendsText: Text {
        let friends = mutualFriends
        if friends.count == 1 {
            return Text("Friends with ") + Text(friends[0].displayName).font(.system(size: 11.5, weight: .black, design: .rounded)).foregroundColor(.black)
        } else if friends.count == 2 {
            return Text("Friends with ") +
                Text(friends[0].displayName).font(.system(size: 11.5, weight: .black, design: .rounded)).foregroundColor(.black) +
                Text(" and ") +
                Text(friends[1].displayName).font(.system(size: 11.5, weight: .black, design: .rounded)).foregroundColor(.black)
        } else {
            let remaining = friends.count - 2
            return Text("Friends with ") +
                Text(friends[0].displayName).font(.system(size: 11.5, weight: .black, design: .rounded)).foregroundColor(.black) +
                Text(", ") +
                Text(friends[1].displayName).font(.system(size: 11.5, weight: .black, design: .rounded)).foregroundColor(.black) +
                Text(", and ") +
                Text("\(remaining) others").font(.system(size: 11.5, weight: .black, design: .rounded)).foregroundColor(.black)
        }
    }
}

// MARK: - Action Buttons (Follow / Message / Invite — for other profiles)

struct ProfileActionButtons: View {
    @Binding var isFollowing: Bool
    @Binding var isLoadingFollow: Bool
    let onToggleFollow: () -> Void
    let onMessage: () -> Void
    let onInvite: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Follow
            Button(action: onToggleFollow) {
                if isLoadingFollow {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                } else {
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }
            }
            .background(Color(hex: "#E2E4D6"))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(hex: "#E2E4D6"), lineWidth: 2))
            .disabled(isLoadingFollow)

            // Message
            Button(action: onMessage) {
                Text("Message")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
            .background(Color(hex: "#E2E4D6"))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(hex: "#E2E4D6"), lineWidth: 2))

            // Invite to Ralley
            Button(action: onInvite) {
                Text("Invite to Ralley")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
            .background(Color(hex: "#E2E4D6"))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(hex: "#E2E4D6"), lineWidth: 2))
        }
        .padding(.horizontal, 22)
    }
}

// MARK: - Profile Edit Button (Own profile — full-width sage pill)

struct ProfileEditButton: View {
    @Binding var showingEditProfile: Bool

    var body: some View {
        Button(action: { showingEditProfile = true }) {
            Text("Edit Profile")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
        }
        .background(Color(hex: "#E2E4D6"))
        .clipShape(Capsule())
        .padding(.horizontal, 22)
    }
}

// MARK: - Divider

struct ProfileDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color(hex: "#d5d7cb"))
            .frame(height: 1)
            .padding(.horizontal, 22)
    }
}

// MARK: - Section Header (Green Pill)

struct ProfileSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hex: "#2C4F40"))
            .clipShape(Capsule())
    }
}

// MARK: - My Pics Empty State

struct ProfilePhotosEmptySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProfileSectionHeader(title: "My Pics")

            HStack {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "#2C4F40").opacity(0.3))
                    Text("Add your best moments")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#7a8a81"))
                }
                .padding(.vertical, 24)
                Spacer()
            }
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - User Extensions for Display

extension User {
    var locationDisplay: String {
        if !locationCity.isEmpty && !locationState.isEmpty {
            return "\(locationCity), \(locationState)"
        } else if !locationCity.isEmpty {
            return locationCity
        } else if !locationState.isEmpty {
            return locationState
        }
        return "Location not set"
    }

    var initials: String {
        let first = firstName.first.map(String.init) ?? ""
        let last = lastName.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
}

// MARK: - Preview

struct ProfileTabView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileTabView()
    }
}
