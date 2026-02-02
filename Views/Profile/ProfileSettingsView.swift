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
    @State private var isSigningOut = false
    @State private var isDeletingAccount = false

    private let authService = AuthenticationService.shared
    private let supabaseManager = SupabaseManager.shared

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

                // Location Section
                Section {
                    NavigationLink(destination: LocationSettingsView()) {
                        SettingsRow(
                            icon: "location.circle",
                            title: "Location",
                            iconColor: ClubRalleyTheme.Colors.info
                        )
                    }
                } header: {
                    Text("Location")
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
                    Task {
                        await performSignOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await performDeleteAccount()
                    }
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
            .overlay {
                if isSigningOut || isDeletingAccount {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView(isSigningOut ? "Signing out..." : "Deleting account...")
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                }
            }
        }
    }

    // MARK: - Actions

    private func performSignOut() async {
        isSigningOut = true
        // Sign out from auth provider
        try? await authService.signOut()
        // Clear local Club Ralley session
        await supabaseManager.signOut()
        // Clear onboarding flag to show onboarding on next launch
        clearUserData()
        isSigningOut = false
        dismiss()
        // Post notification to trigger app state update
        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
    }

    private func performDeleteAccount() async {
        isDeletingAccount = true
        do {
            try await authService.deleteAccount()
        } catch {
            print("Failed to delete account: \(error)")
        }
        // Clear local Club Ralley session
        await supabaseManager.signOut()
        clearUserData()
        isDeletingAccount = false
        dismiss()
        // Post notification to trigger app state update
        NotificationCenter.default.post(name: NSNotification.Name("UserDidLogout"), object: nil)
    }

    private func clearUserData() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedClubRalleyOnboarding")
        UserDefaults.standard.removeObject(forKey: "currentUserProfile")
        UserDefaults.standard.removeObject(forKey: "currentUserProfilePhoto")
        UserDefaults.standard.removeObject(forKey: "joinedRalleyIds")
    }
}

// MARK: - Preview

struct ProfileSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileSettingsView()
    }
}
