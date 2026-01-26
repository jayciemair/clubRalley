//
//  ProfileSettingsView.swift
//  Club Ralley
//
//  Profile settings and account management
//

import SwiftUI

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    NavigationLink(destination: EditProfileView()) {
                        SettingsRow(
                            icon: "person.circle",
                            title: "Edit Profile",
                            iconColor: ClubRalleyTheme.Colors.accent
                        )
                    }
                    
                    NavigationLink(destination: AthleteVerificationView()) {
                        SettingsRow(
                            icon: "star.circle",
                            title: "Athlete Verification",
                            iconColor: ClubRalleyTheme.Colors.warning
                        )
                    }
                } header: {
                    Text("Profile")
                }
                
                // Privacy Section
                Section {
                    NavigationLink(destination: PrivacySettingsView()) {
                        SettingsRow(
                            icon: "lock.circle",
                            title: "Privacy",
                            iconColor: ClubRalleyTheme.Colors.info
                        )
                    }
                    
                    NavigationLink(destination: BlockedUsersView()) {
                        SettingsRow(
                            icon: "hand.raised.circle",
                            title: "Blocked Users",
                            iconColor: ClubRalleyTheme.Colors.error
                        )
                    }
                } header: {
                    Text("Privacy & Safety")
                }
                
                // Notifications Section
                Section {
                    NavigationLink(destination: NotificationSettingsView()) {
                        SettingsRow(
                            icon: "bell.circle",
                            title: "Notifications",
                            iconColor: ClubRalleyTheme.Colors.accent
                        )
                    }
                } header: {
                    Text("Notifications")
                }
                
                // Support Section
                Section {
                    Link(destination: URL(string: "mailto:support@clubralley.com")!) {
                        SettingsRow(
                            icon: "questionmark.circle",
                            title: "Help & Support",
                            iconColor: ClubRalleyTheme.Colors.info
                        )
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        SettingsRow(
                            icon: "info.circle",
                            title: "About Club Ralley",
                            iconColor: ClubRalleyTheme.Colors.accent
                        )
                    }
                } header: {
                    Text("Support")
                }
                
                // Account Section
                Section {
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        SettingsRow(
                            icon: "arrow.right.square",
                            title: "Sign Out",
                            iconColor: ClubRalleyTheme.Colors.warning,
                            showChevron: false
                        )
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: {
                        showingDeleteAccountAlert = true
                    }) {
                        SettingsRow(
                            icon: "trash.circle",
                            title: "Delete Account",
                            iconColor: ClubRalleyTheme.Colors.error,
                            showChevron: false
                        )
                    }
                    .foregroundColor(.primary)
                } header: {
                    Text("Account")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ClubRalleyTheme.Colors.accent)
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    // Handle sign out
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // Handle account deletion
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    var showChevron = true
    
    var body: some View {
        HStack(spacing: ClubRalleyTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(ClubRalleyTheme.Typography.body)
                .foregroundColor(ClubRalleyTheme.Colors.text)
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Placeholder Views

struct EditProfileView: View {
    var body: some View {
        Text("Edit Profile")
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AthleteVerificationView: View {
    var body: some View {
        Text("Athlete Verification")
            .navigationTitle("Verification")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct BlockedUsersView: View {
    var body: some View {
        Text("Blocked Users")
            .navigationTitle("Blocked Users")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Text("Notification Settings")
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.lg) {
                // App info
                VStack {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(ClubRalleyTheme.Colors.accent)
                    
                    Text("Club Ralley")
                        .font(ClubRalleyTheme.Typography.title1)
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                    
                    Text("GFTO - Get the F*** Outside")
                        .font(ClubRalleyTheme.Typography.subheadline)
                        .foregroundColor(ClubRalleyTheme.Colors.accent)
                    
                    Text("Version 1.0.0")
                        .font(ClubRalleyTheme.Typography.caption)
                        .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, ClubRalleyTheme.Spacing.xl)
                
                // Description
                VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.md) {
                    Text("About Club Ralley")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                    
                    Text("Club Ralley is a social platform designed for former athletes navigating post-grad life. Think of it as a LinkedIn-style network for the athletic side of your identity.")
                        .font(ClubRalleyTheme.Typography.body)
                        .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            .padding(ClubRalleyTheme.Spacing.lg)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

struct ProfileSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSettingsView()
    }
}