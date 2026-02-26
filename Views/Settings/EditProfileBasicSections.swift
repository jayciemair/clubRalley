//
//  EditProfileBasicSections.swift
//  Club Ralley
//
//  Extracted basic profile sections for EditProfileView
//

import SwiftUI

// MARK: - Profile Photo

struct EditProfilePhotoSection: View {
    @Binding var showingImagePicker: Bool
    @Binding var selectedImage: UIImage?
    var currentPhotoURL: String?

    var body: some View {
        VStack(spacing: ClubRalleyTheme.Spacing.md) {
            ZStack(alignment: .bottomTrailing) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if let photoURL = currentPhotoURL,
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
}

// MARK: - Name

struct EditProfileNameSection: View {
    @Binding var firstName: String
    @Binding var lastName: String
    var nameError: String?

    var body: some View {
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

            if let nameError = nameError {
                Text(nameError)
                    .font(ClubRalleyTheme.Typography.caption)
                    .foregroundColor(ClubRalleyTheme.Colors.error)
            }
        }
    }
}

// MARK: - Username

struct EditProfileUsernameSection: View {
    @Binding var username: String
    var usernameError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
            Text("Username")
                .font(ClubRalleyTheme.Typography.headline)
                .foregroundColor(ClubRalleyTheme.Colors.text)

            TextField("username", text: $username)
                .textFieldStyle(ClubRalleyTextFieldStyle())
                .autocapitalization(.none)
                .autocorrectionDisabled()

            if let error = usernameError {
                Text(error)
                    .font(ClubRalleyTheme.Typography.caption)
                    .foregroundColor(ClubRalleyTheme.Colors.error)
            }
        }
    }
}

// MARK: - Bio

struct EditProfileBioSection: View {
    @Binding var bio: String
    var bioError: String?
    var maxBioLength: Int

    var body: some View {
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

            HStack {
                Text("\(bio.count)/\(maxBioLength) characters")
                    .font(ClubRalleyTheme.Typography.caption)
                    .foregroundColor(bio.count > maxBioLength ? ClubRalleyTheme.Colors.error : ClubRalleyTheme.Colors.secondaryText)
                Spacer()
                if bio.count > maxBioLength {
                    Text("Too long")
                        .font(ClubRalleyTheme.Typography.caption)
                        .foregroundColor(ClubRalleyTheme.Colors.error)
                }
            }

            if let bioError = bioError {
                Text(bioError)
                    .font(ClubRalleyTheme.Typography.caption)
                    .foregroundColor(ClubRalleyTheme.Colors.error)
            }
        }
    }
}

// MARK: - Location

struct EditProfileLocationSection: View {
    @Binding var city: String
    @Binding var state: String

    var body: some View {
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
    }
}

// MARK: - Instagram

struct EditProfileInstagramSection: View {
    @Binding var instagramHandle: String

    var body: some View {
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
    }
}

// MARK: - Privacy

struct EditProfilePrivacySection: View {
    @Binding var isPrivateAccount: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
            Text("Privacy")
                .font(ClubRalleyTheme.Typography.headline)
                .foregroundColor(ClubRalleyTheme.Colors.text)

            Toggle(isOn: $isPrivateAccount) {
                HStack(spacing: 12) {
                    Image(systemName: isPrivateAccount ? "lock.fill" : "lock.open.fill")
                        .foregroundColor(ClubRalleyTheme.Colors.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Private Account")
                            .font(ClubRalleyTheme.Typography.body)
                        Text(isPrivateAccount ? "Only approved followers can see your profile" : "Anyone can see your profile")
                            .font(ClubRalleyTheme.Typography.caption)
                            .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                    }
                }
            }
            .tint(ClubRalleyTheme.Colors.accent)
        }
    }
}

// MARK: - College Athlete

struct EditProfileCollegeSection: View {
    @Binding var playedCollegeSport: Bool
    @Binding var collegeSport: String
    @Binding var collegeSchool: String
    @Binding var collegeDivision: CollegeDivision
    @Binding var collegeYears: String
    @Binding var collegePosition: String

    var body: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.md) {
            Text("College Athlete")
                .font(ClubRalleyTheme.Typography.headline)
                .foregroundColor(ClubRalleyTheme.Colors.text)

            Toggle(isOn: $playedCollegeSport) {
                HStack(spacing: 12) {
                    Image(systemName: "graduationcap.fill")
                        .foregroundColor(ClubRalleyTheme.Colors.accent)
                    Text("I played a sport in college")
                        .font(ClubRalleyTheme.Typography.body)
                }
            }
            .tint(ClubRalleyTheme.Colors.accent)

            if playedCollegeSport {
                collegeFieldsSection
            }
        }
        .animation(.easeInOut(duration: 0.2), value: playedCollegeSport)
    }

    private var collegeFieldsSection: some View {
        VStack(spacing: ClubRalleyTheme.Spacing.md) {
            TextField("Sport (e.g., Tennis, Soccer)", text: $collegeSport)
                .textFieldStyle(ClubRalleyTextFieldStyle())
            TextField("School Name", text: $collegeSchool)
                .textFieldStyle(ClubRalleyTextFieldStyle())
            HStack {
                Text("Division")
                    .font(ClubRalleyTheme.Typography.body)
                    .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                Spacer()
                Picker("Division", selection: $collegeDivision) {
                    ForEach(CollegeDivision.allCases, id: \.self) { division in
                        Text(division.displayName).tag(division)
                    }
                }
                .pickerStyle(.menu)
                .tint(ClubRalleyTheme.Colors.accent)
            }
            .padding()
            .background(ClubRalleyTheme.Colors.sageGreen.opacity(0.3))
            .cornerRadius(ClubRalleyTheme.CornerRadius.medium)
            TextField("Position (optional)", text: $collegePosition)
                .textFieldStyle(ClubRalleyTextFieldStyle())
            TextField("Years played (e.g., 2019-2023)", text: $collegeYears)
                .textFieldStyle(ClubRalleyTextFieldStyle())
        }
        .padding(.leading, 8)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
