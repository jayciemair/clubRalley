//
//  ProfileTabView.swift
//  Club Ralley
//
//  Profile tab view displaying user profile information
//

import SwiftUI

struct ProfileTabView: View {
    @State private var isFollowing = false
    @State private var showingMessageComingSoon = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ProfileHeaderSection()
                    ProfileInfoSection()
                    ProfileActionButtons(
                        isFollowing: $isFollowing,
                        showingMessageComingSoon: $showingMessageComingSoon
                    )
                    ProfileTeamsSection()
                    ProfilePhotosSection()
                    Spacer(minLength: 100)
                }
            }
            .background(Color(hex: "#F5F5F5"))
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Profile Header Section

struct ProfileHeaderSection: View {
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.black)
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text("Chicago, IL")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 24)

            AsyncImage(url: URL(string: "https://picsum.photos/100/100?random=50")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle().fill(Color(hex: "#2C4F40"))
            }
            .frame(width: 110, height: 110)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text("Gracie King")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.black)
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color(hex: "#2C4F40"))
                        .font(.system(size: 18))
                }
                Text("@gking")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
}

// MARK: - Profile Info Section

struct ProfileInfoSection: View {
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 32) {
                ProfileStatItem(value: "130", label: "Followers")
                ProfileStatItem(value: "95", label: "Following")
                ProfileStatItem(value: "15", label: "Ralleys")
            }

            Text("Former D1 tennis player passionate about fitness and meeting new people!")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            HStack(spacing: 12) {
                ProfileBadge(icon: "tennisball.fill", text: "Tennis")
                ProfileBadge(icon: "building.columns.fill", text: "Bucknell")
            }

            HStack(spacing: 16) {
                MutualFriendBubble(imageUrl: "https://picsum.photos/30/30?random=301")
                MutualFriendBubble(imageUrl: "https://picsum.photos/30/30?random=302")
                Text("Sarah + 4 mutual friends")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
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

// MARK: - Mutual Friend Bubble

struct MutualFriendBubble: View {
    let imageUrl: String

    var body: some View {
        AsyncImage(url: URL(string: imageUrl)) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle().fill(Color.gray.opacity(0.3))
        }
        .frame(width: 30, height: 30)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Profile Action Buttons

struct ProfileActionButtons: View {
    @Binding var isFollowing: Bool
    @Binding var showingMessageComingSoon: Bool

    var body: some View {
        HStack(spacing: 20) {
            ProfileFollowButton(isFollowing: $isFollowing)
            ProfileMessageButton(showingAlert: $showingMessageComingSoon)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .alert("Coming Soon", isPresented: $showingMessageComingSoon) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Direct messaging will be available in a future update.")
        }
    }
}

// MARK: - Profile Follow Button

struct ProfileFollowButton: View {
    @Binding var isFollowing: Bool

    var body: some View {
        Button(action: { isFollowing.toggle() }) {
            HStack(spacing: 8) {
                Image(systemName: isFollowing ? "checkmark" : "person.badge.plus")
                    .font(.system(size: 16, weight: .medium))
                Text(isFollowing ? "Following" : "Follow")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(isFollowing ? Color(hex: "#2C4F40") : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(followButtonBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#2C4F40"), lineWidth: isFollowing ? 2 : 0)
            )
            .shadow(color: Color(hex: "#2C4F40").opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }

    @ViewBuilder
    private var followButtonBackground: some View {
        if isFollowing {
            Color.white
        } else {
            LinearGradient(
                colors: [Color(hex: "#2C4F40"), Color(hex: "#3A6B4F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Profile Message Button

struct ProfileMessageButton: View {
    @Binding var showingAlert: Bool

    var body: some View {
        Button(action: { showingAlert = true }) {
            HStack(spacing: 8) {
                Image(systemName: "message")
                    .font(.system(size: 16, weight: .medium))
                Text("Message")
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
    }
}

// MARK: - Profile Teams Section

struct ProfileTeamsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("My Teams")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Button(action: {}) {
                    Text("View All")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }

            HStack(spacing: 16) {
                ProfileTeamCard(
                    imageUrl: "https://picsum.photos/180/140?random=201",
                    name: "AVS Club",
                    sport: "Volleyball"
                )
                ProfileTeamCard(
                    imageUrl: "https://picsum.photos/180/140?random=202",
                    name: "Basketball Club",
                    sport: "Basketball"
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
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
                .frame(height: 100)
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.white)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Profile Photos Section

struct ProfilePhotosSection: View {
    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Photos")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                Button(action: {}) {
                    Text("View All")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(1...9, id: \.self) { index in
                    AsyncImage(url: URL(string: "https://picsum.photos/150/150?random=\(index + 400)")) { image in
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
        .padding(.horizontal, 24)
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
