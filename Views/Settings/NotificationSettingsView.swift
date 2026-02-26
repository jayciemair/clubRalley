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

    @ObservedObject private var pushService = PushNotificationService.shared
    @State private var hasLoadedFromServer = false

    var body: some View {
        List {
            // Push permission banner when denied
            if pushService.pushAuthorizationStatus == .denied {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.slash.fill")
                            .foregroundColor(.orange)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Push Notifications Disabled")
                                .font(.subheadline.weight(.semibold))
                            Text("Enable in Settings to receive notifications when the app is closed.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button("Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.subheadline.weight(.medium))
                    }
                    .padding(.vertical, 4)
                }
            }

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
        .task {
            // Load server-side settings on appear
            await pushService.refreshPermissionStatus()

            if let serverSettings = await NotificationSettingsService.shared.loadSettings() {
                ralleyInvites = serverSettings.ralley_invites
                ralleyUpdates = serverSettings.ralley_updates
                newFollowers = serverSettings.new_followers
                commentsLikes = serverSettings.comments_likes
                hasLoadedFromServer = true
            }
        }
        .onChange(of: ralleyInvites) { _ in syncToServer() }
        .onChange(of: ralleyUpdates) { _ in syncToServer() }
        .onChange(of: newFollowers) { _ in syncToServer() }
        .onChange(of: commentsLikes) { _ in syncToServer() }
    }

    private func syncToServer() {
        // Skip the initial load-triggered changes
        guard hasLoadedFromServer else { return }

        Task {
            await NotificationSettingsService.shared.syncSettings(
                pushEnabled: pushService.pushAuthorizationStatus == .authorized,
                ralleyInvites: ralleyInvites,
                ralleyUpdates: ralleyUpdates,
                newFollowers: newFollowers,
                commentsLikes: commentsLikes
            )
        }
    }
}
