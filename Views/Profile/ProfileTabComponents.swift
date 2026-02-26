//
//  ProfileTabComponents.swift
//  Club Ralley
//
//  Extracted from ProfileTabView.swift — reusable profile UI components
//

import SwiftUI

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
