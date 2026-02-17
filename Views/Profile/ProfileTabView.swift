//
//  ProfileTabView.swift
//  Club Ralley
//
//  Profile tab with sport carousel and rally history
//

import SwiftUI

// MARK: - Profile Tab View

struct ProfileTabView: View {
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showingSettings = false
    @State private var showingEditProfile = false

    var body: some View {
        NavigationStack {
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
            .background(ClubRalleyTheme.Colors.sageBackground)
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
        }
        .task {
            await profileViewModel.loadCurrentUserProfile()
        }
        .refreshable {
            await profileViewModel.loadCurrentUserProfile(force: true)
        }
    }
}

// MARK: - Profile Loading View

struct ProfileTabLoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading profile...")
                .font(.system(size: 16))
                .foregroundColor(Color.black.opacity(0.5))
                .padding(.top, 16)
            Spacer()
        }
    }
}

// MARK: - Profile Empty View

struct ProfileEmptyView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#2C4F40"))
            Text("No Profile Found")
                .font(.system(size: 22, weight: .bold))
            Text("Complete onboarding to set up your profile")
                .font(.system(size: 16))
                .foregroundColor(Color.black.opacity(0.5))
            Spacer()
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
                    ProfileHeaderSectionReal(
                        profile: profile,
                        showingSettings: $showingSettings
                    )
                    ProfileInfoSectionReal(profile: profile)
                    ProfileEditButton(showingEditProfile: $showingEditProfile)
                    SportCarouselSection(viewModel: profileViewModel)
                    RalleyHistorySection(viewModel: profileViewModel)
                }
                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - Profile Header Section

struct ProfileHeaderSectionReal: View {
    let profile: UserProfile
    @Binding var showingSettings: Bool

    private var ralleysPlayed: Int {
        profile.stats.ralleysAttended + profile.stats.ralleysHosted
    }

    var body: some View {
        VStack(spacing: 16) {
            // Photo + Name
            HStack(alignment: .top, spacing: 16) {
                AsyncImage(url: URL(string: profile.user.profilePhotoURL ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(hex: "#2C4F40"))
                        .overlay(
                            Text(profile.user.initials)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 90, height: 90)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 3)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(profile.user.fullName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                            .lineLimit(1)
                        if profile.socialInfo.isVerifiedAthlete {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(Color(hex: "#2C4F40"))
                                .font(.system(size: 16))
                        }
                    }

                    Text("@\(profile.user.username)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.black.opacity(0.5))

                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.black.opacity(0.5))
                        Text(profile.user.locationDisplay)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.black.opacity(0.5))
                    }
                    .padding(.top, 2)
                }

                Spacer()

                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 24)

            // Enhanced Stats Row
            HStack(spacing: 12) {
                EnhancedStatCard(value: "\(profile.stats.followersCount)", label: "Teammates")
                EnhancedStatCard(value: "\(ralleysPlayed)", label: "Ralleys")
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 16)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [Color(hex: "#E2E4D6").opacity(0.4), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Enhanced Stat Card

struct EnhancedStatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(Color(hex: "#2C4F40"))
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.black.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(hex: "#E2E4D6"))
        .cornerRadius(14)
    }
}

// MARK: - Profile Info Section

struct ProfileInfoSectionReal: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let bio = profile.user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .lineSpacing(2)
            }

            if profile.user.playedCollegeSport, let collegeInfo = profile.user.collegeAthleteInfo {
                HStack(spacing: 6) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#2C4F40"))
                    Text("Former \(collegeInfo.division.shortName) \(collegeInfo.sport.lowercased()) at ")
                        .font(.system(size: 14))
                        .foregroundColor(Color.black.opacity(0.5)) +
                    Text(collegeInfo.school)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                }
            }

            // Mutual friends
            if !profile.mutualFriends.isEmpty {
                HStack(spacing: 8) {
                    HStack(spacing: -8) {
                        ForEach(profile.mutualFriends.prefix(3)) { friend in
                            Circle()
                                .fill(Color(hex: "#2C4F40").opacity(0.2))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text(String(friend.displayName.prefix(1)).uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color(hex: "#2C4F40"))
                                )
                                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        }
                    }
                    mutualFriendsText
                        .font(.system(size: 13))
                        .foregroundColor(Color.black.opacity(0.5))
                }
            }

        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    private var mutualFriendsText: Text {
        let friends = profile.mutualFriends
        if friends.count == 1 {
            return Text("Friends with ") + Text(friends[0].displayName).bold()
        } else if friends.count == 2 {
            return Text("Friends with ") + Text(friends[0].displayName).bold() + Text(" and ") + Text(friends[1].displayName).bold()
        } else {
            let remaining = friends.count - 2
            return Text("Friends with ") + Text(friends[0].displayName).bold() + Text(", ") + Text(friends[1].displayName).bold() + Text(" +\(remaining)")
        }
    }
}

// MARK: - Profile Edit Button

struct ProfileEditButton: View {
    @Binding var showingEditProfile: Bool

    var body: some View {
        Button(action: { showingEditProfile = true }) {
            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .medium))
                Text("Edit Profile")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(Color(hex: "#2C4F40"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#2C4F40"), lineWidth: 2)
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
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
