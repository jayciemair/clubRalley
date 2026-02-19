//
//  ProfileTabView.swift
//  Club Ralley
//
//  Profile tab with centered layout, sport carousel, rally history, and photos
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
        .background(Color(hex: "#F5F2EB"))
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
            VStack(spacing: 20) {
                // Centered avatar placeholder
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .padding(.top, 60)

                // Name placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 140, height: 20)

                // Username placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 100, height: 14)

                // Stats row
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 70)
                    }
                }
                .padding(.horizontal, 24)

                // Sport pills
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 110, height: 100)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)

                // Content cards
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 120)
                        .padding(.horizontal, 24)
                }
            }
        }
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
                .foregroundColor(Color(hex: "#2D4A3E"))
                .scaleEffect(isVisible ? 1 : 0.5)
                .opacity(isVisible ? 1 : 0)

            Text("No Profile Found")
                .font(.system(size: 22, weight: .bold))
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : 10)

            Text("Complete onboarding to set up your profile")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#6B7B6E"))
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
                    // Settings gear — top right
                    HStack {
                        Spacer()
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "#2D4A3E"))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    // Centered header
                    ProfileCenteredHeader(profile: profile)

                    // Stats row
                    ProfileStatsRow(profile: profile)
                        .padding(.top, 20)

                    // Bio + credentials + social links
                    ProfileBioSection(profile: profile)
                        .padding(.top, 16)

                    // Edit Profile button
                    ProfileEditButton(showingEditProfile: $showingEditProfile)
                        .padding(.top, 16)

                    // My Sports
                    SportCarouselSection(viewModel: profileViewModel)
                        .padding(.top, 24)

                    // Rally History
                    RalleyHistorySection(viewModel: profileViewModel)

                    // My Pics
                    if !profile.photos.isEmpty {
                        ProfilePhotosSection(photos: profile.photos)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                    } else {
                        ProfilePhotosEmptySection()
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                    }
                }
                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - Centered Header

struct ProfileCenteredHeader: View {
    let profile: UserProfile

    var body: some View {
        VStack(spacing: 8) {
            // Profile photo
            AsyncImage(url: URL(string: profile.user.profilePhotoURL ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color(hex: "#2D4A3E"))
                    .overlay(
                        Text(profile.user.initials)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 3))
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 3)

            // Name + verified badge
            HStack(spacing: 6) {
                Text(profile.user.fullName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#2D4A3E"))

                if profile.socialInfo.isVerifiedAthlete {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color(hex: "#2D4A3E"))
                        .font(.system(size: 16))
                }
            }

            // @username
            Text("@\(profile.user.username)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#6B7B6E"))

            // Location with pin
            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#2D4A3E"))
                Text(profile.user.locationDisplay)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#6B7B6E"))
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Stats Row (3 cards)

struct ProfileStatsRow: View {
    let profile: UserProfile

    private var ralleysPlayed: Int {
        profile.stats.ralleysAttended + profile.stats.ralleysHosted
    }

    var body: some View {
        HStack(spacing: 12) {
            ProfileStatCard(value: "\(profile.stats.followersCount)", label: "Followers")
            ProfileStatCard(value: "\(ralleysPlayed)", label: "Ralleys")
            ProfileStatCard(value: "\(profile.stats.wins)", label: "Wins")
        }
        .padding(.horizontal, 24)
    }
}

struct ProfileStatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#2D4A3E"))
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(hex: "#6B7B6E"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(hex: "#E8E4DA"))
        .cornerRadius(14)
    }
}

// MARK: - Bio Section

struct ProfileBioSection: View {
    let profile: UserProfile

    private var hasSocialLinks: Bool {
        profile.socialInfo.instagramHandle != nil || profile.socialInfo.linkedinHandle != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Bio text
            if let bio = profile.user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#2D4A3E"))
                    .lineSpacing(2)
            }

            // College credentials
            if profile.user.playedCollegeSport, let collegeInfo = profile.user.collegeAthleteInfo {
                HStack(spacing: 6) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#2D4A3E"))
                    Text("Former \(collegeInfo.division.shortName) \(collegeInfo.sport.lowercased()) at ")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#6B7B6E")) +
                    Text(collegeInfo.school)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "#2D4A3E"))
                }
            }

            // Social links
            if hasSocialLinks {
                HStack(spacing: 16) {
                    if let instagram = profile.socialInfo.instagramHandle {
                        ProfileSocialLink(platform: "instagram", handle: instagram)
                    }
                    if let linkedin = profile.socialInfo.linkedinHandle {
                        ProfileSocialLink(platform: "linkedin", handle: linkedin)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 24)
    }
}

struct ProfileSocialLink: View {
    let platform: String
    let handle: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#2D4A3E"))
            Text("@\(handle)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#6B7B6E"))
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
            .foregroundColor(Color(hex: "#2D4A3E"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: "#2D4A3E"), lineWidth: 2)
            )
            .cornerRadius(20)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - My Pics Empty State

struct ProfilePhotosEmptySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Pill badge header
            Text("My Pics")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(hex: "#2D4A3E"))
                .cornerRadius(20)

            HStack {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "#2D4A3E").opacity(0.3))
                    Text("Add your best moments")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#6B7B6E"))
                }
                .padding(.vertical, 24)
                Spacer()
            }
            .background(Color(hex: "#E8E4DA").opacity(0.5))
            .cornerRadius(14)
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
