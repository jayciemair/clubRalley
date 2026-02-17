//
//  ProfileSwitcherView.swift
//  Club Ralley
//
//  UI for switching between saved user profiles
//

import SwiftUI

struct ProfileSwitcherView: View {
    @ObservedObject private var profileManager = MultiProfileManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showAddAccount = false
    @State private var showRemoveConfirmation = false
    @State private var profileToRemove: MultiProfile?

    var body: some View {
        NavigationStack {
            List {
                // Saved Profiles Section
                Section {
                    ForEach(profileManager.sortedProfiles) { profile in
                        ProfileRow(
                            profile: profile,
                            isActive: profileManager.isActiveProfile(profile),
                            onSelect: {
                                switchToProfile(profile)
                            }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if !profileManager.isActiveProfile(profile) {
                                Button(role: .destructive) {
                                    profileToRemove = profile
                                    showRemoveConfirmation = true
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Text("Saved Accounts")
                } footer: {
                    Text("Tap an account to switch. Swipe left to remove.")
                }

                // Add Account Section
                Section {
                    Button {
                        showAddAccount = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(hex: "#2C4F40"))
                                .font(.title2)

                            Text("Add Account")
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Switch Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Remove Account?", isPresented: $showRemoveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    if let profile = profileToRemove {
                        profileManager.removeProfile(profile.id)
                    }
                }
            } message: {
                if let profile = profileToRemove {
                    Text("Remove \(profile.email) from this device? You can sign back in anytime.")
                }
            }
            .sheet(isPresented: $showAddAccount) {
                AddAccountView {
                    showAddAccount = false
                }
            }
        }
    }

    private func switchToProfile(_ profile: MultiProfile) {
        Task {
            do {
                try await profileManager.switchToProfile(profile)
                dismiss()
            } catch {
                print("Failed to switch profile: \(error)")
            }
        }
    }
}

// MARK: - Profile Row

struct ProfileRow: View {
    let profile: MultiProfile
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Profile Photo
                ProfilePhotoView(
                    photoURL: profile.profilePhotoURL,
                    initials: profile.initials,
                    size: 50
                )

                // Profile Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(profile.fullName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color(hex: "#2C4F40"))
                                .font(.caption)
                        }
                    }

                    Text("@\(profile.username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if !profile.displayLocation.isEmpty {
                        Text(profile.displayLocation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isActive {
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "#2C4F40"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#2C4F40").opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Photo View

struct ProfilePhotoView: View {
    let photoURL: String?
    let initials: String
    let size: CGFloat

    var body: some View {
        Group {
            if let urlString = photoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        InitialsView(initials: initials, size: size)
                    @unknown default:
                        InitialsView(initials: initials, size: size)
                    }
                }
            } else {
                InitialsView(initials: initials, size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

struct InitialsView: View {
    let initials: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#2C4F40"))

            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Add Account View

struct AddAccountView: View {
    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "#2C4F40"))
                        .frame(width: 80, height: 80)

                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
                .padding(.top, 32)

                // Title
                Text("Add Account")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Sign in to an existing account or create a new one")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Sign in with phone
                Button {
                    // Sign out and go to phone auth flow
                    UserDefaults.standard.set(false, forKey: "hasCompletedClubRalleyOnboarding")
                    NotificationCenter.default.post(
                        name: NSNotification.Name("UserDidLogout"),
                        object: nil
                    )
                    onComplete()
                } label: {
                    Text("Sign in with phone number")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#2C4F40"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onComplete()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileSwitcherView()
}
