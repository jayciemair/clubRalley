//
//  EditProfileView.swift
//  Club Ralley
//
//  View for editing user profile information
//

import SwiftUI

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
                if let userId = SupabaseManager.shared.currentUser?.id {
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
        if let profile = SavedUserProfile.loadFromStorage() {
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
        if let userId = SupabaseManager.shared.currentUser?.id {
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
