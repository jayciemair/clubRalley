//
//  RalleyDetailView.swift
//  Club Ralley
//
//  Detailed view for a single ralley with captain controls.
//

import SwiftUI

struct RalleyDetailView: View {
    let ralley: ClubRalley
    @EnvironmentObject var ralleyManager: RalleyManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingPendingRequests = false
    @State private var showingChat = false
    @State private var showingCompletionSheet = false
    @State private var pendingRequests: [PendingJoinRequest] = []
    @State private var hasPendingRequest = false
    @State private var isJoining = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                RalleyDetailHeader(ralley: ralley)
                RalleyInfoSection(ralley: ralley)
                RalleyParticipantsSection(ralley: ralley)

                if ralley.isCaptain {
                    RalleyCaptainControls(
                        ralley: ralley,
                        pendingRequests: pendingRequests,
                        showingPendingRequests: $showingPendingRequests,
                        showingCompletionSheet: $showingCompletionSheet
                    )
                }

                actionButtonSection

                Spacer(minLength: 100)
            }
        }
        .background(Color(hex: "#F5F5F5"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { /* TODO: Add ShareUtility.swift to Xcode project */ }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color(hex: "#2C4F40"))
                    }

                    if ralley.chatId != nil {
                        Button(action: { showingChat = true }) {
                            Image(systemName: "message.fill")
                                .foregroundColor(Color(hex: "#2C4F40"))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPendingRequests) {
            PendingRequestsSheet(
                ralley: ralley,
                requests: $pendingRequests
            )
            .environmentObject(ralleyManager)
        }
        .sheet(isPresented: $showingCompletionSheet) {
            RalleyCompletionSheet(ralley: ralley)
                .environmentObject(ralleyManager)
        }
        .task {
            await loadData()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingChat) {
            NavigationStack {
                GroupChatView(chat: createGroupChat())
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") {
                                showingChat = false
                            }
                            .foregroundColor(Color(hex: "#2C4F40"))
                        }
                    }
            }
        }
    }

    // MARK: - Helper Methods

    /// Creates a GroupChat object from the current ralley data
    private func createGroupChat() -> GroupChat {
        GroupChat(
            id: ralley.chatId ?? UUID(),
            ralleyId: ralley.id,
            ralleyTitle: ralley.title,
            ralleySport: ralley.sport,
            ralleyDateTime: ralley.dateTime,
            createdAt: ralley.createdAt ?? Date(),
            memberCount: ralley.currentPlayers,
            lastMessage: nil,
            lastMessageAt: nil,
            hasUnread: false,
            currentUserRole: ralley.isCaptain ? .admin : .member
        )
    }

    // MARK: - Action Button Section

    private var actionButtonSection: some View {
        VStack(spacing: 12) {
            if ralley.isCaptain {
                // Captain sees chat button
                if ralley.chatId != nil {
                    Button(action: { showingChat = true }) {
                        HStack {
                            Image(systemName: "message.fill")
                            Text("Open Group Chat")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#2C4F40"))
                        .cornerRadius(12)
                    }
                }
            } else if ralley.requiresApproval {
                // Private ralley - show request button
                Button(action: { Task { await requestToJoin() } }) {
                    HStack {
                        if isJoining {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: hasPendingRequest ? "clock" : "hand.raised")
                        }
                        Text(hasPendingRequest ? "Request Pending" : "Request to Join")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(hasPendingRequest ? Color.gray : Color(hex: "#2C4F40"))
                    .cornerRadius(12)
                }
                .disabled(hasPendingRequest || isJoining || ralley.isFull)
            } else {
                // Open ralley - join directly
                Button(action: { Task { await joinRalley() } }) {
                    HStack {
                        if isJoining {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text("Join Ralley")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ralley.isFull ? Color.gray : Color(hex: "#2C4F40"))
                    .cornerRadius(12)
                }
                .disabled(ralley.isFull || isJoining)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Actions

    private func loadData() async {
        if ralley.isCaptain {
            pendingRequests = await ralleyManager.loadPendingRequests(for: ralley.id)
        } else if ralley.requiresApproval {
            hasPendingRequest = await ralleyManager.hasPendingRequest(for: ralley.id)
        }
    }

    private func joinRalley() async {
        isJoining = true
        let previousError = ralleyManager.error
        await ralleyManager.joinRalley(ralley.id)
        // Check if error was set during operation
        if ralleyManager.error != nil && ralleyManager.error?.localizedDescription != previousError?.localizedDescription {
            errorMessage = "Failed to join ralley. Please check your connection and try again."
            showingError = true
        }
        isJoining = false
    }

    private func requestToJoin() async {
        isJoining = true
        let previousError = ralleyManager.error
        await ralleyManager.requestToJoin(ralley.id)
        // Check if error was set during operation
        if ralleyManager.error != nil && ralleyManager.error?.localizedDescription != previousError?.localizedDescription {
            errorMessage = "Failed to send join request. Please check your connection and try again."
            showingError = true
        } else {
            hasPendingRequest = true
        }
        isJoining = false
    }
}
