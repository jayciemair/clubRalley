//
//  EditProfileBasicSections.swift
//  Club Ralley
//
//  Instagram-style profile editing sections
//

import SwiftUI

// MARK: - Profile Photo

struct EditProfilePhotoSection: View {
    @Binding var showingImagePicker: Bool
    @Binding var selectedImage: UIImage?
    var currentPhotoURL: String?

    var body: some View {
        Button(action: { showingImagePicker = true }) {
            VStack(spacing: 12) {
                ZStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                    } else if let photoURL = currentPhotoURL,
                              let url = URL(string: photoURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            profilePlaceholder
                        }
                        .frame(width: 96, height: 96)
                        .clipShape(Circle())
                    } else {
                        profilePlaceholder
                    }
                }

                Text("Edit picture")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var profilePlaceholder: some View {
        Circle()
            .fill(Color(.systemGray5))
            .frame(width: 96, height: 96)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color(.systemGray2))
            )
    }
}

// MARK: - Inline Field Row

struct ProfileFieldRow: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words
    var disableAutocorrection: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text(label)
                    .font(.system(size: 15))
                    .foregroundColor(ClubRalleyTheme.Colors.text)
                    .frame(width: 100, alignment: .leading)

                TextField(placeholder.isEmpty ? label : placeholder, text: $text)
                    .font(.system(size: 15))
                    .foregroundColor(ClubRalleyTheme.Colors.text)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled(disableAutocorrection)
                    .keyboardType(keyboardType)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            Divider()
                .padding(.leading, 16)
        }
    }
}

// MARK: - Name Section

struct EditProfileNameSection: View {
    @Binding var firstName: String
    @Binding var lastName: String
    var nameError: String?

    var body: some View {
        VStack(spacing: 0) {
            ProfileFieldRow(label: "First name", text: $firstName, placeholder: "First name")
            ProfileFieldRow(label: "Last name", text: $lastName, placeholder: "Last name")

            if let nameError = nameError {
                Text(nameError)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Username

struct EditProfileUsernameSection: View {
    @Binding var username: String
    var usernameError: String?

    var body: some View {
        VStack(spacing: 0) {
            ProfileFieldRow(
                label: "Username",
                text: $username,
                placeholder: "username",
                autocapitalization: .never,
                disableAutocorrection: true
            )

            if let error = usernameError {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
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
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text("Bio")
                        .font(.system(size: 15))
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                        .frame(width: 100, alignment: .leading)
                        .padding(.top, 8)

                    VStack(alignment: .trailing, spacing: 4) {
                        TextField("Write something about yourself...", text: $bio, axis: .vertical)
                            .font(.system(size: 15))
                            .foregroundColor(ClubRalleyTheme.Colors.text)
                            .lineLimit(3...6)

                        Text("\(bio.count)/\(maxBioLength)")
                            .font(.system(size: 11))
                            .foregroundColor(bio.count > maxBioLength ? .red : Color(.systemGray3))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
            }

            Divider()
                .padding(.leading, 16)

            if let bioError = bioError {
                Text(bioError)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - Location

struct EditProfileLocationSection: View {
    @Binding var city: String
    @Binding var state: String

    var body: some View {
        VStack(spacing: 0) {
            ProfileFieldRow(label: "City", text: $city, placeholder: "City")
            ProfileFieldRow(label: "State", text: $state, placeholder: "State")
        }
    }
}

// MARK: - Instagram

struct EditProfileInstagramSection: View {
    @Binding var instagramHandle: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("Instagram")
                    .font(.system(size: 15))
                    .foregroundColor(ClubRalleyTheme.Colors.text)
                    .frame(width: 100, alignment: .leading)

                HStack(spacing: 2) {
                    Text("@")
                        .font(.system(size: 15))
                        .foregroundColor(Color(.systemGray2))
                    TextField("username", text: $instagramHandle)
                        .font(.system(size: 15))
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            Divider()
                .padding(.leading, 16)
        }
    }
}

// MARK: - Privacy

struct EditProfilePrivacySection: View {
    @Binding var isPrivateAccount: Bool

    var body: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $isPrivateAccount) {
                HStack(spacing: 12) {
                    Image(systemName: isPrivateAccount ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Private account")
                            .font(.system(size: 15))
                            .foregroundColor(ClubRalleyTheme.Colors.text)
                        Text(isPrivateAccount ? "Only approved followers can see your posts" : "Anyone can see your profile and posts")
                            .font(.system(size: 12))
                            .foregroundColor(Color(.systemGray))
                    }
                }
            }
            .tint(ClubRalleyTheme.Colors.darkGreen)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()
                .padding(.leading, 16)
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
        VStack(spacing: 0) {
            Toggle(isOn: $playedCollegeSport) {
                HStack(spacing: 12) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                        .frame(width: 24)

                    Text("College athlete")
                        .font(.system(size: 15))
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                }
            }
            .tint(ClubRalleyTheme.Colors.darkGreen)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()
                .padding(.leading, 16)

            if playedCollegeSport {
                VStack(spacing: 0) {
                    ProfileFieldRow(label: "Sport", text: $collegeSport, placeholder: "e.g. Tennis")
                    ProfileFieldRow(label: "School", text: $collegeSchool, placeholder: "School name")

                    HStack {
                        Text("Division")
                            .font(.system(size: 15))
                            .foregroundColor(ClubRalleyTheme.Colors.text)
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                        Picker("Division", selection: $collegeDivision) {
                            ForEach(CollegeDivision.allCases, id: \.self) { division in
                                Text(division.displayName).tag(division)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(ClubRalleyTheme.Colors.darkGreen)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Divider()
                        .padding(.leading, 16)

                    ProfileFieldRow(label: "Position", text: $collegePosition, placeholder: "Optional")
                    ProfileFieldRow(label: "Years", text: $collegeYears, placeholder: "e.g. 2019-2023")
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: playedCollegeSport)
    }
}
