//
//  MessagesView.swift
//  Club Ralley
//
//  Main messages list showing all direct conversations
//

import SwiftUI

struct MessagesView: View {
    @StateObject private var messagingService = MessagingService()
    @State private var searchText = ""

    var filteredConversations: [DirectConversation] {
        if searchText.isEmpty {
            return messagingService.conversations
        }
        return messagingService.conversations.filter {
            $0.otherUserName.localizedCaseInsensitiveContains(searchText) ||
            $0.otherUserUsername.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerSection

                // Content
                if messagingService.isLoading && messagingService.conversations.isEmpty {
                    loadingView
                } else if let error = messagingService.error, messagingService.conversations.isEmpty {
                    errorView(error: error)
                } else if messagingService.conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationsList
                }
            }
            .background(Color(hex: "#F5F5F5"))
            .navigationBarHidden(true)
        }
        .task {
            await messagingService.loadConversations()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Messages")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: "#2C4F40"))

                Spacer()

                if messagingService.totalUnreadCount > 0 {
                    Text("\(messagingService.totalUnreadCount) unread")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#2C4F40"))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)

                TextField("Search conversations...", text: $searchText)
                    .font(.system(size: 16))

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
        .background(Color.white)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading messages...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Spacer()
        }
    }

    // MARK: - Error View

    private func errorView(error: Error) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))

            Text("Unable to load messages")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)

            Text("Check your internet connection and try again")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                Task {
                    await messagingService.loadConversations()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: "#2C4F40"))
                .cornerRadius(12)
            }

            Spacer()
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "message.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.5))

            Text("No Messages Yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)

            Text("Start a conversation by tapping the message button on someone's profile or in the roster.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Conversations List

    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredConversations) { conversation in
                    NavigationLink(destination: DirectMessageView(conversation: conversation, messagingService: messagingService)) {
                        ConversationRow(conversation: conversation)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Divider()
                        .padding(.leading, 80)
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer(minLength: 100)
        }
        .refreshable {
            await messagingService.loadConversations()
        }
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: DirectConversation

    var body: some View {
        HStack(spacing: 12) {
            // Profile photo
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: conversation.otherUserPhotoURL ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(hex: "#2C4F40").opacity(0.2))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "#2C4F40"))
                        )
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())

                if conversation.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#2C4F40"))
                        .background(Circle().fill(.white).frame(width: 18, height: 18))
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUserName)
                        .font(.system(size: 16, weight: conversation.hasUnread ? .bold : .semibold))
                        .foregroundColor(.black)

                    Spacer()

                    if let timeAgo = conversation.lastMessageTimeAgo {
                        Text(timeAgo)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }

                HStack {
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage)
                            .font(.system(size: 14, weight: conversation.hasUnread ? .semibold : .regular))
                            .foregroundColor(conversation.hasUnread ? .black : .gray)
                            .lineLimit(1)
                    } else {
                        Text("No messages yet")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .italic()
                    }

                    Spacer()

                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Color(hex: "#2C4F40"))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(conversation.hasUnread ? Color(hex: "#2C4F40").opacity(0.05) : Color.clear)
    }
}

// MARK: - Preview

#Preview {
    MessagesView()
}
