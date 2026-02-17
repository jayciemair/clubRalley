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
    @State private var hasLoadedProfile = false

    var body: some View {
        NavigationStack {
            Group {
                if profileViewModel.isLoading {
                    ProfileTabLoadingView()
                } else if let profile = profileViewModel.currentUserProfile {
                    ProfileTabContentView(
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
            .sheet(isPresented: $showingEditProfile, onDismiss: {
                Task {
                    await profileViewModel.loadCurrentUserProfile()
                }
            }) {
                NavigationStack {
                    EditProfileView()
                }
            }
        }
        .task {
            guard !hasLoadedProfile else { return }
            hasLoadedProfile = true
            await profileViewModel.loadCurrentUserProfile()
        }
        .refreshable {
            await profileViewModel.loadCurrentUserProfile()
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

struct ProfileTabContentView: View {
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
                ProfileSportsSectionReal(profile: profile)
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

    private var ralleysPlayed: Int {
        profile.stats.ralleysAttended + profile.stats.ralleysHosted
    }

    var body: some View {
        VStack(spacing: 16) {
            // Photo + Name side-by-side
            HStack(alignment: .top, spacing: 16) {
                // Profile photo
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

                // Name, location, stats
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
                        .foregroundColor(.gray)

                    // Location
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        Text(profile.user.locationDisplay)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 2)
                }

                Spacer()

                // Settings gear
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 24)

            // Stats row
            HStack(spacing: 0) {
                ProfileStatItem(value: "\(profile.stats.followersCount)", label: "Followers")
                    .frame(maxWidth: .infinity)
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 30)
                ProfileStatItem(value: "\(ralleysPlayed)", label: "Ralleys Played")
                    .frame(maxWidth: .infinity)
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 30)
                ProfileStatItem(value: "\(profile.stats.wins)", label: "Wins")
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Profile Info Section (Real Data)

struct ProfileInfoSectionReal: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Bio
            if let bio = profile.user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .lineSpacing(2)
            }

            // College Athlete Info (clean text style, not a card)
            if profile.user.playedCollegeSport, let collegeInfo = profile.user.collegeAthleteInfo {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#2C4F40"))
                        Text("Former \(collegeInfo.division.shortName) \(collegeInfo.sport.lowercased()) at ")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary) +
                        Text(collegeInfo.school)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    if let years = collegeInfo.yearsPlayed, !years.isEmpty {
                        Text(years)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.leading, 19)
                    }
                }
            }

            // Social links row
            let hasInstagram = !(profile.socialInfo.instagramHandle ?? "").isEmpty
            let hasLinkedin = !(profile.socialInfo.linkedinHandle ?? "").isEmpty
            if hasInstagram || hasLinkedin {
                HStack(spacing: 16) {
                    if let instagram = profile.socialInfo.instagramHandle, !instagram.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12))
                            Text("@\(instagram)")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "#2C4F40"))
                    }
                    if let linkedin = profile.socialInfo.linkedinHandle, !linkedin.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.system(size: 12))
                            Text("@\(linkedin)")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "#2C4F40"))
                    }
                }
            }

            // Mutual friends row
            if !profile.mutualFriends.isEmpty {
                HStack(spacing: 8) {
                    // Overlapping avatars
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
                        .foregroundColor(.secondary)
                }
            }

            // Private account indicator
            if profile.user.isPrivateAccount {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                    Text("Private Account")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.secondary)
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

// MARK: - College Athlete Badge

struct CollegeAthleteBadge: View {
    let info: CollegeAthleteInfo
    let isVerified: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#2C4F40"))
                Text("College Athlete")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#2C4F40"))
                if isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }

            // Details card
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(info.sport)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                        Text(info.school)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    // Division badge
                    Text(info.division.shortName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(divisionColor(info.division))
                        .cornerRadius(16)
                }

                // Position and years if available
                HStack(spacing: 16) {
                    if let position = info.position, !position.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 11))
                            Text(position)
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.gray)
                    }
                    if let years = info.yearsPlayed, !years.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                            Text(years)
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.gray)
                    }
                    Spacer()
                }
            }
            .padding(16)
            .background(Color(hex: "#2C4F40").opacity(0.08))
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
    }

    private func divisionColor(_ division: CollegeDivision) -> Color {
        switch division {
        case .d1: return Color(hex: "#1976D2")  // Blue
        case .d2: return Color(hex: "#388E3C")  // Green
        case .d3: return Color(hex: "#7B1FA2")  // Purple
        case .naia: return Color(hex: "#F57C00")  // Orange
        case .juco: return Color(hex: "#0097A7")  // Teal
        case .club: return Color(hex: "#455A64")  // Blue Grey
        }
    }
}

// MARK: - Sports with Skill Levels

struct ProfileSportsWithSkills: View {
    let sports: [UserSportSkill]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sports")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Wrap sports in a flow layout
            FlowLayout(spacing: 8) {
                ForEach(sports) { sport in
                    SportSkillBadge(sport: sport)
                }
            }
        }
    }
}

struct SportSkillBadge: View {
    let sport: UserSportSkill

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: sportIcon(for: sport.sportName))
                .font(.system(size: 13))
            Text(sport.sportName)
                .font(.system(size: 14, weight: .medium))
            Text("•")
                .font(.system(size: 10))
                .foregroundColor(.gray)
            Text("\(sport.skillLevel.emoji) \(sport.skillLevel.displayName)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: sport.skillLevel.color))
        }
        .foregroundColor(Color(hex: "#2C4F40"))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(hex: "#2C4F40").opacity(0.1))
        .cornerRadius(20)
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
        case "pickleball": return "figure.pickleball"
        case "running": return "figure.run"
        case "cycling": return "figure.outdoor.cycle"
        case "hiking": return "figure.hiking"
        case "yoga": return "figure.yoga"
        case "crossfit", "fitness": return "dumbbell.fill"
        default: return "sportscourt.fill"
        }
    }
}

// MARK: - Flow Layout for wrapping badges

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Profile Sport Badges

struct ProfileSportBadges: View {
    let profile: UserProfile

    var body: some View {
        HStack(spacing: 12) {
            // Show primary sport if available
            if let athleteInfo = profile.user.athleteInfo {
                ProfileBadge(icon: sportIcon(for: athleteInfo.sport.name), text: athleteInfo.sport.name.capitalized)
                ProfileBadge(icon: "building.columns.fill", text: athleteInfo.school.name)
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

// MARK: - Profile Sports Section

struct ProfileSportsSectionReal: View {
    let profile: UserProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with green pill badge
            HStack(spacing: 8) {
                Text("My Sports")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#2C4F40"))
                    .cornerRadius(14)
                Spacer()
            }

            if profile.user.sportsWithSkills.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No sports added yet")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(profile.user.sportsWithSkills) { sport in
                            SportCard(sport: sport)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

// MARK: - Sport Card

struct SportCard: View {
    let sport: UserSportSkill

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: sportIcon(for: sport.sportName))
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "#2C4F40"))

            Text(sport.sportName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)

            Text(sport.skillLevel.displayName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(hex: sport.skillLevel.color))
        }
        .frame(width: 120, height: 100)
        .background(Color(hex: "#2C4F40").opacity(0.08))
        .cornerRadius(14)
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
        case "pickleball": return "figure.pickleball"
        case "running": return "figure.run"
        case "cycling": return "figure.outdoor.cycle"
        case "hiking": return "figure.hiking"
        case "yoga": return "figure.yoga"
        case "crossfit", "fitness": return "dumbbell.fill"
        default: return "sportscourt.fill"
        }
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
        VStack(alignment: .leading, spacing: 16) {
            // Section header with green pill badge
            HStack(spacing: 8) {
                Text("My Pics")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#2C4F40"))
                    .cornerRadius(14)
                Spacer()
            }

            if photos.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 30))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No pics yet")
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

// MARK: - Preview

struct ProfileTabView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileTabView()
    }
}
