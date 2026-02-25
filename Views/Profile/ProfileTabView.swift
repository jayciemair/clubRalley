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
                    showingSettings: $showingSettings,
                    showingEditProfile: $showingEditProfile
                )
            } else {
                ProfileEmptyView()
            }
        }
        .background(Color(hex: "#f6f5f1"))
        .navigationBarHidden(true)
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
            VStack(spacing: 0) {
                // Top bar skeleton
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 100, height: 14)
                    Spacer()
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 22, height: 22)
                }
                .padding(.horizontal, 22)
                .padding(.top, 6)
                .padding(.bottom, 10)

                // Avatar skeleton centered
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 96, height: 96)
                    .padding(.top, 10)
                    .padding(.bottom, 12)

                // Name skeleton centered
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 160, height: 24)
                    .padding(.bottom, 6)

                // Username skeleton centered
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 100, height: 13)
                    .padding(.bottom, 18)

                // Stats skeleton
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { i in
                        if i > 0 {
                            Rectangle()
                                .fill(Color.gray.opacity(0.12))
                                .frame(width: 1, height: 36)
                        }
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 32, height: 28)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.12))
                                .frame(width: 44, height: 10)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 18)

                // Bio skeleton centered
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 260, height: 13)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.12))
                        .frame(width: 120, height: 13)
                }
                .padding(.bottom, 14)

                // Button skeleton
                RoundedRectangle(cornerRadius: 50)
                    .fill(Color.gray.opacity(0.12))
                    .frame(height: 46)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 16)

                // Divider skeleton
                Rectangle()
                    .fill(Color.gray.opacity(0.08))
                    .frame(height: 1)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 16)

                // Sport cards skeleton
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.gray.opacity(0.12))
                            .frame(width: 130, height: 150)
                    }
                }
                .padding(.horizontal, 22)
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
    @Binding var showingSettings: Bool
    @Binding var showingEditProfile: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let profile = profileViewModel.currentUserProfile {
                    // Custom top bar (location + gear)
                    ProfileCustomTopBar(
                        location: profile.user.locationDisplay,
                        showingSettings: $showingSettings
                    )

                    // Centered header (avatar, name, @username, stats)
                    ProfileHeaderRow(profile: profile)

                    // Bio (centered)
                    ProfileBioSection(profile: profile)
                        .padding(.bottom, 14)

                    // Mutual friends
                    if !profile.mutualFriends.isEmpty {
                        ProfileFriendsRow(mutualFriends: profile.mutualFriends)
                            .padding(.bottom, 16)
                    }

                    // Edit Profile button
                    ProfileEditButton(showingEditProfile: $showingEditProfile)

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

// MARK: - Custom Top Bar (Location + Gear)

struct ProfileCustomTopBar: View {
    let location: String
    @Binding var showingSettings: Bool

    var body: some View {
        HStack {
            HStack(spacing: 5) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#2C4F40"))
                Text(location)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }

            Spacer()

            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }
}

// MARK: - Profile Header (Centered: Avatar, Name, Username, Stats)

struct ProfileHeaderRow: View {
    let profile: UserProfile

    var body: some View {
        VStack(spacing: 0) {
            // Avatar — centered, 96pt
            AsyncImage(url: URL(string: profile.user.profilePhotoURL ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color(hex: "#2C4F40"))
                    .overlay(
                        Text(profile.user.initials)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())
            .padding(.top, 10)
            .padding(.bottom, 12)

            // Name
            Text(profile.user.fullName)
                .font(.custom("Chillax-Bold", size: 26))
                .foregroundColor(Color(hex: "#2C4F40"))
                .multilineTextAlignment(.center)

            // @username
            Text("@\(profile.user.username)")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "#7a8a81"))
                .padding(.top, 2)
                .padding(.bottom, 18)

            // Stats row with dividers
            ProfileStatsRow(profile: profile)
                .padding(.horizontal, 32)
                .padding(.bottom, 18)
        }
    }
}

// MARK: - Stats Row (Centered with Vertical Dividers)

struct ProfileStatsRow: View {
    let profile: UserProfile

    var body: some View {
        HStack(spacing: 0) {
            ProfileStat(value: profile.stats.followersCount, label: "Friends")
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color(hex: "#d5d7cb"))
                .frame(width: 1, height: 36)

            ProfileStat(value: profile.stats.ralleysAttended, label: "Ralleys")
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color(hex: "#d5d7cb"))
                .frame(width: 1, height: 36)

            ProfileStat(value: profile.stats.postsCount, label: "Posts")
                .frame(maxWidth: .infinity)
        }
    }
}

struct ProfileStat: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(Color(hex: "#2C4F40"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#7a8a81"))
                .textCase(.uppercase)
                .tracking(0.3)
        }
    }
}

// MARK: - Bio Section (Centered)

struct ProfileBioSection: View {
    let profile: UserProfile

    var body: some View {
        VStack(spacing: 3) {
            // College credentials as inline text
            if profile.user.playedCollegeSport, let collegeInfo = profile.user.collegeAthleteInfo {
                (Text("Former \(collegeInfo.division.shortName) \(collegeInfo.sport.lowercased()) player at ")
                    .font(.system(size: 13.5, weight: .regular, design: .rounded))
                    .foregroundColor(Color(hex: "#3a3a3a"))
                +
                Text(collegeInfo.school)
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#1a1a1a")))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            }

            // Bio text
            if let bio = profile.user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 13.5, weight: .regular, design: .rounded))
                    .foregroundColor(Color(hex: "#3a3a3a"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .padding(.horizontal, 36)
    }
}

// MARK: - Friends Row (Overlapping Avatars + Text)

struct ProfileFriendsRow: View {
    let mutualFriends: [MutualFriend]

    private let avatarColors: [String] = ["#a8c4b8", "#7a9e8e", "#5a8070"]

    var body: some View {
        HStack(spacing: 8) {
            // Overlapping avatar circles
            ZStack(alignment: .leading) {
                ForEach(Array(mutualFriends.prefix(3).enumerated()), id: \.offset) { index, friend in
                    if let url = friend.profileImageURL, !url.isEmpty {
                        AsyncImage(url: URL(string: url)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color(hex: avatarColors[index % avatarColors.count]))
                        }
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: CGFloat(index) * 18)
                        .zIndex(Double(3 - index))
                    } else {
                        Circle()
                            .fill(Color(hex: avatarColors[index % avatarColors.count]))
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .offset(x: CGFloat(index) * 18)
                            .zIndex(Double(3 - index))
                    }
                }
            }
            .frame(width: CGFloat(min(mutualFriends.count, 3)) * 18 + 10, alignment: .leading)

            friendsText
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(Color(hex: "#7a8a81"))
                .lineSpacing(2)

            Spacer()
        }
        .padding(.horizontal, 22)
    }

    private var friendsText: Text {
        let friends = mutualFriends
        let boldFont = Font.system(size: 12, weight: .bold, design: .rounded)
        let boldColor = Color(hex: "#5a5a5a")
        if friends.count == 1 {
            return Text("Friends with ") + Text(friends[0].displayName).font(boldFont).foregroundColor(boldColor)
        } else if friends.count == 2 {
            return Text("Friends with ") +
                Text(friends[0].displayName).font(boldFont).foregroundColor(boldColor) +
                Text(" and ") +
                Text(friends[1].displayName).font(boldFont).foregroundColor(boldColor)
        } else {
            let remaining = friends.count - 2
            return Text("Friends with ") +
                Text(friends[0].displayName).font(boldFont).foregroundColor(boldColor) +
                Text(", ") +
                Text(friends[1].displayName).font(boldFont).foregroundColor(boldColor) +
                Text(", and ") +
                Text("\(remaining) others").font(boldFont).foregroundColor(boldColor)
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
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
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
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
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
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
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
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#1a1a1a"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
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
            .font(.custom("Chillax-Semibold", size: 13))
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
