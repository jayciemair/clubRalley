//
//  PrivacySettingsView.swift
//  Club Ralley
//
//  Privacy and blocked users settings
//

import SwiftUI

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
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.slash")
                .font(.system(size: 60))
                .foregroundColor(ClubRalleyTheme.Colors.secondaryText)

            Text("No Blocked Users")
                .font(ClubRalleyTheme.Typography.headline)
                .foregroundColor(ClubRalleyTheme.Colors.text)

            Text("When you block someone, they won't be able to see your profile or contact you.")
                .font(ClubRalleyTheme.Typography.body)
                .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
    }
}
