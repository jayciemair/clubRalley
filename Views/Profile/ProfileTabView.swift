//
//  ProfileTabView.swift
//  Club Ralley
//
//  Profile tab view displaying user profile information
//  Now connected to real user data from ProfileViewModel
//

import SwiftUI

struct ProfileTabView: View {
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var showingSettings = false
    @State private var showingEditProfile = false

    var body: some View {
        NavigationStack {
            Group {
                if profileViewModel.isLoading {
                    ProfileLoadingView()
                } else if let profile = profileViewModel.currentUserProfile {
                    ProfileContentView(
                        profile: profile,
                        showingSettings: $showingSettings,
                        showingEditProfile: $showingEditProfile
                    )
                } else {
                    ProfileEmptyView()
                }
            }
            .background(Color(hex: "#F5F5F5"))
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                ProfileSettingsView()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
        }
        .task {
            await profileViewModel.loadCurrentUserProfile()
        }
    }
}

// MARK: - Profile Loading View

struct ProfileLoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading profile...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
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
                .foregroundColor(.gray)
            Spacer()
        }
    }
}

// MARK: - Profile Content View

struct ProfileContentView: View {
    let profile: UserProfile
    @Binding var showingSettings: Bool
    @Binding var showingEditProfile: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ProfileHeaderSectionReal(
                    profile: profile,
                    showingSettings: $showingSettings
                )
                ProfileInfoSectionReal(profile: profile)
                ProfileEditButton(showingEditProfile: $showingEditProfile)
                ProfileTeamsSectionReal(profile: profile)
                ProfilePhotosSectionReal(photos: profile.photos)
                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - Profile Header Section (Real Data)

struct ProfileHeaderSectionReal: View {
    let profile: UserProfile
    @Binding var showingSettings: Bool

    var body: some View {
        VStack(spacing: 20) {
            // Top bar with location and settings
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(profile.user.locationDisplay)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
            .padding(.horizontal, 24)

            // Profile photo
            AsyncImage(url: URL(string: profile.user.profilePhotoURL ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color(hex: "#2C4F40"))
                    .overlay(
                        Text(profile.user.initials)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 110, height: 110)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)

            // Name and username
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(profile.user.displayName)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.black)
                    if profile.socialInfo.isVerifiedAthlete {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(Color(hex: "#2C4F40"))
                            .font(.system(size: 18))
                    }
                }
                Text("@\(profile.user.username)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
}

// MARK: - Profile Info Section (Real Data)

struct ProfileInfoSectionReal: View {
    let profile: UserProfile

    var body: some View {
        VStack(spacing: 24) {
            // Stats row
            HStack(spacing: 32) {
                ProfileStatItem(value: "\(profile.stats.followersCount)", label: "Followers")
                ProfileStatItem(value: "\(profile.stats.followingCount)", label: "Following")
                ProfileStatItem(value: "\(profile.stats.ralleysHosted + profile.stats.ralleysAttended)", label: "Ralleys")
            }

            // Bio
            if let bio = profile.user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Sports badges (if available from athlete info or sports)
            ProfileSportBadges(profile: profile)

            // Instagram link
            if let instagram = profile.socialInfo.instagramHandle, !instagram.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14))
                    Text("@\(instagram)")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(Color(hex: "#2C4F40"))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

// MARK: - Profile Sport Badges

struct ProfileSportBadges: View {
    let profile: UserProfile

    var body: some View {
        HStack(spacing: 12) {
            // Show primary sport if available
            if let athleteInfo = profile.user.athleteInfo {
                ProfileBadge(icon: sportIcon(for: athleteInfo.sport), text: athleteInfo.sport.capitalized)
                if let school = athleteInfo.college {
                    ProfileBadge(icon: "building.columns.fill", text: school)
                }
            }
        }
    }

    private func sportIcon(for sport: String) -> String {
        switch sport.lowercased() {
        case "tennis": return "tennisball.fill"
        case "basketball": return "basketball.fill"
        case "soccer", "football": return "soccerball"
        case "volleyball": return "volleyball.fill"
        case "baseball": return "baseball.fill"
        case "golf": return "figure.golf"
        case "swimming": return "figure.pool.swim"
        default: return "sportscourt.fill"
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

// MARK: - Profile Teams Section (Real Data)

struct ProfileTeamsSectionReal: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("My Teams")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                if !profile.teams.isEmpty {
                    Button(action: {}) {
                        Text("View All")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#2C4F40"))
                    }
                }
            }

            if profile.teams.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.3")
                            .font(.system(size: 30))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No teams yet")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(profile.teams) { team in
                            ProfileTeamCard(
                                imageUrl: team.imageUrl ?? "https://picsum.photos/180/140",
                                name: team.name,
                                sport: team.sport
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

// MARK: - Profile Photos Section (Real Data)

struct ProfilePhotosSectionReal: View {
    let photos: [UserPhoto]

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Posts")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                if !photos.isEmpty {
                    Button(action: {}) {
                        Text("View All")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#2C4F40"))
                    }
                }
            }

            if photos.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 30))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No posts yet")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(photos) { photo in
                        AsyncImage(url: URL(string: photo.imageURL)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle().fill(Color.gray.opacity(0.2))
                        }
                        .frame(height: 110)
                        .clipped()
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - User Extensions for Display

extension User {
    var displayName: String {
        "\(firstName) \(lastName)"
    }

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

// MARK: - Profile Stat Item

struct ProfileStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Profile Badge

struct ProfileBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
            Text(text)
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(Color(hex: "#2C4F40"))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(hex: "#2C4F40").opacity(0.1))
        .cornerRadius(20)
    }
}

// MARK: - Profile Team Card

struct ProfileTeamCard: View {
    let imageUrl: String
    let name: String
    let sport: String

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.2))
                }
                .frame(width: 160, height: 100)
                .clipped()
            }
            .cornerRadius(12, corners: [.topLeft, .topRight])

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                Text(sport)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            .frame(width: 160, alignment: .leading)
            .padding(12)
            .background(Color.white)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

struct ProfileTabView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileTabView()
    }
}
