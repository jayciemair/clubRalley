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
                        isSigningOut = true
                        // Sign out from auth provider
                        try? await authService.signOut()
                        // Clear local Club Ralley session
                        await supabaseManager.signOut()
                        // Clear onboarding flag to show onboarding on next launch
                        UserDefaults.standard.removeObject(forKey: "hasCompletedClubRalleyOnboarding")
                        // Clear saved profile
                        UserDefaults.standard.removeObject(forKey: "currentUserProfile")
                        UserDefaults.standard.removeObject(forKey: "currentUserProfilePhoto")
                        isSigningOut = false
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        isDeletingAccount = true
                        do {
                            try await authService.deleteAccount()
                        } catch {
                            print("Failed to delete account: \(error)")
                        }
                        // Clear local Club Ralley session
                        await supabaseManager.signOut()
                        // Clear onboarding flag
                        UserDefaults.standard.removeObject(forKey: "hasCompletedClubRalleyOnboarding")
                        // Clear saved profile
                        UserDefaults.standard.removeObject(forKey: "currentUserProfile")
                        UserDefaults.standard.removeObject(forKey: "currentUserProfilePhoto")
                        isDeletingAccount = false
                        dismiss()
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

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditProfileViewModel()

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var instagramHandle: String = ""

    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingSaveError = false

    var body: some View {
        ScrollView {
            VStack(spacing: ClubRalleyTheme.Spacing.lg) {
                // Profile Photo Section
                profilePhotoSection

                // Name Section
                VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
                    Text("Name")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)

                    HStack(spacing: ClubRalleyTheme.Spacing.md) {
                        TextField("First Name", text: $firstName)
                            .textFieldStyle(ClubRalleyTextFieldStyle())

                        TextField("Last Name", text: $lastName)
                            .textFieldStyle(ClubRalleyTextFieldStyle())
                    }
                }

                // Username Section
                VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
                    Text("Username")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)

                    TextField("username", text: $username)
                        .textFieldStyle(ClubRalleyTextFieldStyle())
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    if let error = viewModel.usernameError {
                        Text(error)
                            .font(ClubRalleyTheme.Typography.caption)
                            .foregroundColor(ClubRalleyTheme.Colors.error)
                    }
                }

                // Bio Section
                VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
                    Text("Bio")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)

                    TextEditor(text: $bio)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(ClubRalleyTheme.Colors.sageGreen.opacity(0.3))
                        .cornerRadius(ClubRalleyTheme.CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: ClubRalleyTheme.CornerRadius.medium)
                                .stroke(ClubRalleyTheme.Colors.accent.opacity(0.3), lineWidth: 1)
                        )

                    Text("\(bio.count)/150 characters")
                        .font(ClubRalleyTheme.Typography.caption)
                        .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                }

                // Location Section
                VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
                    Text("Location")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)

                    HStack(spacing: ClubRalleyTheme.Spacing.md) {
                        TextField("City", text: $city)
                            .textFieldStyle(ClubRalleyTextFieldStyle())

                        TextField("State", text: $state)
                            .textFieldStyle(ClubRalleyTextFieldStyle())
                            .frame(width: 80)
                    }
                }

                // Instagram Section
                VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
                    Text("Instagram")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)

                    HStack {
                        Text("@")
                            .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                        TextField("username", text: $instagramHandle)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    .padding()
                    .background(ClubRalleyTheme.Colors.sageGreen.opacity(0.3))
                    .cornerRadius(ClubRalleyTheme.CornerRadius.medium)
                }

                Spacer(minLength: 100)
            }
            .padding(ClubRalleyTheme.Spacing.lg)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        await saveProfile()
                    }
                }
                .font(ClubRalleyTheme.Typography.bodyBold)
                .foregroundColor(ClubRalleyTheme.Colors.accent)
                .disabled(viewModel.isSaving)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .alert("Error Saving", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.saveError ?? "An error occurred while saving your profile.")
        }
        .overlay {
            if viewModel.isSaving {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView("Saving...")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
    }

    // MARK: - Profile Photo Section

    private var profilePhotoSection: some View {
        VStack(spacing: ClubRalleyTheme.Spacing.md) {
            ZStack(alignment: .bottomTrailing) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if let photoURL = viewModel.currentPhotoURL,
                          let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(ClubRalleyTheme.Colors.sageGreen)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(ClubRalleyTheme.Colors.accent)
                            )
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(ClubRalleyTheme.Colors.sageGreen)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(ClubRalleyTheme.Colors.accent)
                        )
                }

                Button(action: {
                    showingImagePicker = true
                }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(ClubRalleyTheme.Colors.accent)
                        .clipShape(Circle())
                }
            }

            Text("Tap to change photo")
                .font(ClubRalleyTheme.Typography.caption)
                .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
        }
    }

    // MARK: - Methods

    private func loadCurrentProfile() {
        if let profile = SavedUserProfile.loadFromStorage() {
            firstName = profile.firstName
            lastName = profile.lastName
            username = profile.username
            city = profile.locationCity
            state = profile.locationState
            viewModel.currentPhotoURL = profile.profilePhotoURL
        }
    }

    private func saveProfile() async {
        // Upload new photo if selected
        var photoURL: String? = viewModel.currentPhotoURL

        if let image = selectedImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            do {
                if let userId = AuthenticationService.shared.currentUserId {
                    photoURL = try await ImageUploadService.shared.uploadProfilePhoto(
                        imageData: imageData,
                        userId: userId
                    )
                }
            } catch {
                print("Failed to upload photo: \(error)")
            }
        }

        // Save profile
        let success = await viewModel.saveProfile(
            firstName: firstName,
            lastName: lastName,
            username: username,
            bio: bio,
            city: city,
            state: state,
            instagramHandle: instagramHandle,
            profilePhotoURL: photoURL
        )

        if success {
            dismiss()
        } else {
            showingSaveError = true
        }
    }
}

// MARK: - Edit Profile ViewModel

@MainActor
class EditProfileViewModel: ObservableObject {
    @Published var isSaving = false
    @Published var saveError: String?
    @Published var usernameError: String?
    @Published var currentPhotoURL: String?

    private let supabase = SupabaseManager.shared

    func saveProfile(
        firstName: String,
        lastName: String,
        username: String,
        bio: String,
        city: String,
        state: String,
        instagramHandle: String,
        profilePhotoURL: String?
    ) async -> Bool {
        isSaving = true
        saveError = nil

        defer { isSaving = false }

        // Validate username
        if username.count < 3 {
            usernameError = "Username must be at least 3 characters"
            return false
        }

        // Update local storage
        if var profile = SavedUserProfile.loadFromStorage() {
            let updatedProfile = SavedUserProfile(
                id: profile.id,
                email: profile.email,
                firstName: firstName,
                lastName: lastName,
                username: username,
                phoneNumber: profile.phoneNumber,
                locationCity: city,
                locationState: state,
                profilePhotoURL: profilePhotoURL,
                selectedSports: profile.selectedSports,
                createdAt: profile.createdAt
            )

            // Save to UserDefaults
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(updatedProfile) {
                UserDefaults.standard.set(data, forKey: "currentUserProfile")
            }
        }

        // Update Supabase (if connected)
        if let userId = AuthenticationService.shared.currentUserId {
            do {
                let update = DatabaseUserProfileUpdate(
                    bio: bio.isEmpty ? nil : bio,
                    instagram_handle: instagramHandle.isEmpty ? nil : instagramHandle,
                    profile_photo_url: profilePhotoURL
                )

                try await supabase.update(update, in: "club_users", where: "id = '\(userId)'")
                print("EditProfileViewModel: Profile updated in Supabase")
            } catch {
                print("EditProfileViewModel: Failed to update Supabase: \(error)")
                // Don't fail - local update succeeded
            }
        }

        // Update SupabaseManager current user
        if let currentUser = supabase.currentUser {
            supabase.currentUser = SupabaseUser(
                id: currentUser.id,
                email: currentUser.email,
                firstName: firstName,
                lastName: lastName
            )
        }

        return true
    }
}

// MARK: - Custom Text Field Style

struct ClubRalleyTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(ClubRalleyTheme.Colors.sageGreen.opacity(0.3))
            .cornerRadius(ClubRalleyTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ClubRalleyTheme.CornerRadius.medium)
                    .stroke(ClubRalleyTheme.Colors.accent.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.editedImage] as? UIImage {
                parent.image = image
            } else if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
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
    @AppStorage("profileVisibility") private var profileVisibility: String = "everyone"
    @AppStorage("showLocation") private var showLocation: Bool = true
    @AppStorage("showAge") private var showAge: Bool = true
    @AppStorage("allowFriendRequests") private var allowFriendRequests: Bool = true

    var body: some View {
        List {
            Section {
                Picker("Profile Visibility", selection: $profileVisibility) {
                    Text("Everyone").tag("everyone")
                    Text("Friends Only").tag("friends_only")
                    Text("Private").tag("private")
                }

                Toggle("Show Location", isOn: $showLocation)
                Toggle("Show Age", isOn: $showAge)
                Toggle("Allow Friend Requests", isOn: $allowFriendRequests)
            } header: {
                Text("Profile Privacy")
            } footer: {
                Text("Control who can see your profile information.")
            }

            Section {
                NavigationLink(destination: BlockedUsersView()) {
                    HStack {
                        Text("Blocked Users")
                        Spacer()
                        Text("0")
                            .foregroundColor(.gray)
                    }
                }
            } header: {
                Text("Blocked Users")
            }
        }
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
    @AppStorage("notifyRalleyInvites") private var ralleyInvites: Bool = true
    @AppStorage("notifyFriendRequests") private var friendRequests: Bool = true
    @AppStorage("notifyRalleyReminders") private var ralleyReminders: Bool = true
    @AppStorage("notifySocialUpdates") private var socialUpdates: Bool = true
    @AppStorage("notifyNewMatches") private var newMatches: Bool = true
    @AppStorage("notifyMessages") private var messages: Bool = true

    var body: some View {
        List {
            Section {
                Toggle("Ralley Invites", isOn: $ralleyInvites)
                Toggle("Friend Requests", isOn: $friendRequests)
                Toggle("Direct Messages", isOn: $messages)
            } header: {
                Text("Social")
            } footer: {
                Text("Notifications for social activity on Club Ralley.")
            }

            Section {
                Toggle("Ralley Reminders", isOn: $ralleyReminders)
                Toggle("New Matches", isOn: $newMatches)
            } header: {
                Text("Ralleys")
            } footer: {
                Text("Get reminded about upcoming ralleys and new matches in your area.")
            }

            Section {
                Toggle("Social Updates", isOn: $socialUpdates)
            } header: {
                Text("Activity")
            } footer: {
                Text("Notifications about likes, comments, and other activity on your posts.")
            }
        }
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