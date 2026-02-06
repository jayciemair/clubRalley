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

                // MARK: - Save Button
                Button(action: {
                    Task {
                        await saveProfile()
                    }
                }) {
                    HStack {
                        if viewModel.isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        }
                        Text(viewModel.isSaving ? "Saving..." : "Save Profile")
                            .font(ClubRalleyTheme.Typography.bodyBold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ClubRalleyTheme.Colors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(ClubRalleyTheme.CornerRadius.large)
                }
                .disabled(viewModel.isSaving)
                .padding(.top, ClubRalleyTheme.Spacing.lg)

                Spacer(minLength: 50)
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
        print("🔵 helloWORLD EDIT_PROFILE loadCurrentProfile START")

        if let profile = SavedUserProfile.loadFromStorage() {
            print("🔵 helloWORLD EDIT_PROFILE - Found saved profile: \(profile.firstName) \(profile.lastName)")
            print("🔵 helloWORLD EDIT_PROFILE - username: \(profile.username), city: \(profile.locationCity)")

            firstName = profile.firstName
            lastName = profile.lastName
            username = profile.username
            city = profile.locationCity
            state = profile.locationState
            bio = profile.bio ?? ""
            instagramHandle = profile.instagramHandle ?? ""
            viewModel.currentPhotoURL = profile.profilePhotoURL

            print("🔵 helloWORLD EDIT_PROFILE - Fields populated from local storage")
        } else {
            print("🔴 helloWORLD EDIT_PROFILE - No saved profile found in local storage")
        }

        // Also try to load from Supabase for bio/instagram if not in local storage
        Task {
            await loadFromSupabase()
        }
    }

    private func loadFromSupabase() async {
        print("🔵 helloWORLD EDIT_PROFILE loadFromSupabase START")

        // Try to get userId from Supabase or fall back to saved profile
        var userId: UUID? = SupabaseManager.shared.currentUser?.id
        print("🔵 helloWORLD EDIT_PROFILE - Supabase userId: \(userId?.uuidString ?? "nil")")

        if userId == nil, let savedProfile = SavedUserProfile.loadFromStorage() {
            userId = savedProfile.id
            print("🔵 helloWORLD EDIT_PROFILE - Using SavedProfile userId: \(savedProfile.id)")
        }

        guard let userId = userId else {
            print("🔴 helloWORLD EDIT_PROFILE loadFromSupabase - No userId available from any source")
            return
        }

        print("🔵 helloWORLD EDIT_PROFILE loadFromSupabase - using userId: \(userId)")

        do {
            print("🔵 helloWORLD EDIT_PROFILE - Querying users table...")
            let users: [ClubUserProfileData] = try await SupabaseManager.shared.query("club_users")
                .select("bio, instagram_handle")
                .eq("id", value: userId)
                .execute()

            print("🔵 helloWORLD EDIT_PROFILE - Got \(users.count) results from Supabase")

            if let user = users.first {
                print("🟢 helloWORLD EDIT_PROFILE - Found user data: bio=\(user.bio ?? "nil"), instagram=\(user.instagram_handle ?? "nil")")
                if bio.isEmpty, let dbBio = user.bio {
                    bio = dbBio
                    print("🟢 helloWORLD EDIT_PROFILE - Updated bio from Supabase")
                }
                if instagramHandle.isEmpty, let dbInsta = user.instagram_handle {
                    instagramHandle = dbInsta
                    print("🟢 helloWORLD EDIT_PROFILE - Updated instagram from Supabase")
                }
            } else {
                print("🔴 helloWORLD EDIT_PROFILE - No user data found in Supabase")
            }
        } catch {
            print("🔴 helloWORLD EDIT_PROFILE loadFromSupabase FAILED: \(error)")
        }
    }

    private func saveProfile() async {
        print("🔵 helloWORLD EDIT_PROFILE saveProfile START")
        print("🔵 helloWORLD EDIT_PROFILE - firstName: \(firstName)")
        print("🔵 helloWORLD EDIT_PROFILE - lastName: \(lastName)")
        print("🔵 helloWORLD EDIT_PROFILE - username: \(username)")
        print("🔵 helloWORLD EDIT_PROFILE - bio: \(bio)")
        print("🔵 helloWORLD EDIT_PROFILE - city: \(city), state: \(state)")
        print("🔵 helloWORLD EDIT_PROFILE - instagramHandle: \(instagramHandle)")

        // Upload new photo if selected
        var photoURL: String? = viewModel.currentPhotoURL
        print("🔵 helloWORLD EDIT_PROFILE - existing photoURL: \(photoURL ?? "nil")")

        if let image = selectedImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            print("🔵 helloWORLD EDIT_PROFILE - Uploading new photo...")
            do {
                if let userId = SupabaseManager.shared.currentUser?.id {
                    photoURL = try await ImageUploadService.shared.uploadProfilePhoto(
                        imageData: imageData,
                        userId: userId
                    )
                    print("🟢 helloWORLD EDIT_PROFILE - Photo uploaded: \(photoURL ?? "nil")")
                }
            } catch {
                print("🔴 helloWORLD EDIT_PROFILE - Photo upload FAILED: \(error)")
            }
        }

        // Save profile
        print("🔵 helloWORLD EDIT_PROFILE - Calling viewModel.saveProfile...")
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
            print("🟢 helloWORLD EDIT_PROFILE saveProfile SUCCESS - dismissing")
            dismiss()
        } else {
            print("🔴 helloWORLD EDIT_PROFILE saveProfile FAILED")
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
        print("🔵 helloWORLD VIEWMODEL saveProfile START")
        print("🔵 helloWORLD VIEWMODEL - firstName: \(firstName), lastName: \(lastName)")
        print("🔵 helloWORLD VIEWMODEL - username: \(username)")
        print("🔵 helloWORLD VIEWMODEL - bio: \(bio.prefix(50))...")
        print("🔵 helloWORLD VIEWMODEL - city: \(city), state: \(state)")
        print("🔵 helloWORLD VIEWMODEL - instagramHandle: \(instagramHandle)")
        print("🔵 helloWORLD VIEWMODEL - profilePhotoURL: \(profilePhotoURL ?? "nil")")

        isSaving = true
        saveError = nil

        defer {
            isSaving = false
            print("🔵 helloWORLD VIEWMODEL saveProfile END - isSaving set to false")
        }

        // Validate username
        if username.count < 3 {
            print("🔴 helloWORLD VIEWMODEL - Username validation failed: too short")
            usernameError = "Username must be at least 3 characters"
            return false
        }

        // Update local storage
        print("🔵 helloWORLD VIEWMODEL - Updating local storage...")
        if let profile = SavedUserProfile.loadFromStorage() {
            print("🔵 helloWORLD VIEWMODEL - Found existing profile in local storage")
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
                createdAt: profile.createdAt,
                bio: bio.isEmpty ? nil : bio,
                instagramHandle: instagramHandle.isEmpty ? nil : instagramHandle
            )

            // Save to UserDefaults
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(updatedProfile) {
                UserDefaults.standard.set(data, forKey: "currentUserProfile")
                print("🟢 helloWORLD VIEWMODEL - Saved to UserDefaults successfully")
            } else {
                print("🔴 helloWORLD VIEWMODEL - Failed to encode profile for UserDefaults")
            }
        } else {
            print("🔴 helloWORLD VIEWMODEL - No existing profile in local storage")
        }

        // Update Supabase (if connected)
        print("🔵 helloWORLD VIEWMODEL - Checking Supabase connection...")
        print("🔵 helloWORLD VIEWMODEL - supabase.isAuthenticated: \(supabase.isAuthenticated)")
        print("🔵 helloWORLD VIEWMODEL - supabase.currentUser: \(supabase.currentUser?.id.uuidString ?? "nil")")
        print("🔵 helloWORLD VIEWMODEL - supabase.currentUser email: \(supabase.currentUser?.email ?? "nil")")

        // Also check saved profile for userId
        var userIdForSupabase: UUID? = SupabaseManager.shared.currentUser?.id
        if let savedProfile = SavedUserProfile.loadFromStorage() {
            print("🔵 helloWORLD VIEWMODEL - SavedProfile userId: \(savedProfile.id)")
            print("🔵 helloWORLD VIEWMODEL - SavedProfile email: \(savedProfile.email)")
            // Use saved profile's ID as fallback if Supabase currentUser is nil
            if userIdForSupabase == nil {
                userIdForSupabase = savedProfile.id
                print("🔵 helloWORLD VIEWMODEL - Using SavedProfile userId as fallback")
            }
        } else {
            print("🔴 helloWORLD VIEWMODEL - No SavedProfile found!")
        }

        if let userId = userIdForSupabase {
            print("🔵 helloWORLD VIEWMODEL - Updating Supabase for userId: \(userId)")
            do {
                let update = DatabaseUserProfileUpdate(
                    first_name: firstName,
                    last_name: lastName,
                    username: username,
                    bio: bio.isEmpty ? nil : bio,
                    city: city.isEmpty ? nil : city,
                    state: state.isEmpty ? nil : state,
                    instagram_handle: instagramHandle.isEmpty ? nil : instagramHandle,
                    profile_photo_url: profilePhotoURL
                )

                print("🔵 helloWORLD VIEWMODEL - Calling supabase.update...")
                try await supabase.update(update, in: "club_users", where: "id = '\(userId)'")
                print("🟢 helloWORLD VIEWMODEL - Supabase update SUCCESS")
            } catch {
                print("🔴 helloWORLD VIEWMODEL - Supabase update FAILED: \(error)")
                // Don't fail - local update succeeded
            }
        } else {
            print("🔴 helloWORLD VIEWMODEL - No userId available for Supabase update")
        }

        // Update SupabaseManager current user
        if let currentUser = supabase.currentUser {
            print("🔵 helloWORLD VIEWMODEL - Updating SupabaseManager.currentUser")
            supabase.currentUser = SupabaseUser(
                id: currentUser.id,
                email: currentUser.email,
                firstName: firstName,
                lastName: lastName
            )
            print("🟢 helloWORLD VIEWMODEL - SupabaseManager.currentUser updated")
        }

        print("🟢 helloWORLD VIEWMODEL saveProfile returning TRUE")
        return true
    }
}

// MARK: - Helper struct for loading from Supabase

private struct ClubUserProfileData: Codable {
    let bio: String?
    let instagram_handle: String?
}
