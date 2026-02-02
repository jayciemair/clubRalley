//
//  NotificationSettingsView.swift
//  Club Ralley
//
//  Notification preferences settings
//

import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("notifyRalleyInvites") private var ralleyInvites: Bool = true
    @AppStorage("notifyRalleyUpdates") private var ralleyUpdates: Bool = true
    @AppStorage("notifyNewFollowers") private var newFollowers: Bool = true
    @AppStorage("notifyCommentsLikes") private var commentsLikes: Bool = true

    var body: some View {
        List {
            Section {
                Toggle("Ralley Invites", isOn: $ralleyInvites)
                Toggle("Ralley Updates", isOn: $ralleyUpdates)
            } header: {
                Text("Ralleys")
            } footer: {
                Text("Get notified about ralley invites and changes to time or location.")
            }

            Section {
                Toggle("New Followers", isOn: $newFollowers)
                Toggle("Comments & Likes", isOn: $commentsLikes)
            } header: {
                Text("Social")
            } footer: {
                Text("Notifications about new followers and activity on your posts.")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
