//
//  SocialBioStep.swift
//  Club Ralley
//
//  Step 2: Social handles and bio for Power Up Profile
//

import SwiftUI

struct SocialBioStep: View {
    @EnvironmentObject var viewModel: PowerUpProfileViewModel
    @FocusState private var focusedField: Field?

    enum Field {
        case instagram, bio
    }

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text(PowerUpStep.socialBio.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)

                Text(PowerUpStep.socialBio.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)

            VStack(spacing: 24) {
                // Instagram handle
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instagram")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 0) {
                        Text("@")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)

                        TextField("username", text: $viewModel.data.instagramHandle)
                            .font(.system(size: 17))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .instagram)
                            .padding(.vertical, 14)
                            .padding(.trailing, 16)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                focusedField == .instagram ? ClubRalleyTheme.Colors.darkGreen : Color.clear,
                                lineWidth: 2
                            )
                    )

                    Text("Let teammates find you on Instagram")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)

                // Bio / Goals
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's something you're working on?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    TextEditor(text: $viewModel.data.bio)
                        .font(.system(size: 16))
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    focusedField == .bio ? ClubRalleyTheme.Colors.darkGreen : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .focused($focusedField, equals: .bio)
                        .overlay(alignment: .topLeading) {
                            if viewModel.data.bio.isEmpty {
                                Text("Training for a marathon, learning to surf, getting back into basketball...")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 20)
                                    .allowsHitTesting(false)
                            }
                        }

                    HStack {
                        Text("Share your fitness goals or what you're focused on")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(viewModel.data.bio.count)/150")
                            .font(.system(size: 12))
                            .foregroundColor(viewModel.data.bio.count > 150 ? .red : .secondary)
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
        .onTapGesture {
            focusedField = nil
        }
    }
}

// MARK: - Preview

struct SocialBioStep_Previews: PreviewProvider {
    static var previews: some View {
        SocialBioStep()
            .environmentObject(PowerUpProfileViewModel())
    }
}
