//
//  DirectMessageView.swift
//  Club Ralley
//
//  Chat view for direct messages between two users
//

import SwiftUI

struct DirectMessageView: View {
    let conversation: DirectConversation
    @ObservedObject var messagingService: MessagingService
    @Environment(\.dismiss) private var dismiss

    @State private var messages: [DirectMessage] = []
    @State private var messageText = ""
    @State private var isLoading = true
    @State private var isSending = false
    @State private var loadError: Error?
    @State private var showingSendError = false
    @State private var sendErrorMessage = ""

    // Realtime updates
    private let realtimeManager = RealtimeManager.shared
    private let supabaseManager = SupabaseManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .padding(.top, 40)
                        } else if let error = loadError {
                            messageLoadErrorView(error: error)
                        } else if messages.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: messages.count) { _, _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input Bar
            messageInputBar
        }
        .background(Color(hex: "#F5F5F5"))
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .navigationTitle(conversation.otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: UserProfileView(userId: conversation.otherUserId)) {
                    AsyncImage(url: URL(string: conversation.otherUserPhotoURL ?? "")) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color(hex: "#2C4F40").opacity(0.2))
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                }
            }
        }
        .task {
            await loadMessages()
            await messagingService.markAsRead(conversationId: conversation.id)
            subscribeToRealtime()
        }
        .onDisappear {
            Task {
                await realtimeManager.unsubscribeFromDirectMessages()
            }
        }
        .alert("Message Failed", isPresented: $showingSendError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(sendErrorMessage)
        }
    }

    // MARK: - Message Load Error View

    private func messageLoadErrorView(error: Error) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))

            Text("Unable to load messages")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)

            Text("Check your connection and try again")
                .font(.system(size: 14))
                .foregroundColor(.gray)

            Button(action: { Task { await loadMessages() } }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(hex: "#2C4F40"))
                .cornerRadius(10)
            }

            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            AsyncImage(url: URL(string: conversation.otherUserPhotoURL ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color(hex: "#2C4F40").opacity(0.2))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color(hex: "#2C4F40"))
                    )
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())

            Text("Start a conversation with \(conversation.otherUserName)")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.top, 60)
    }

    // MARK: - Message Input Bar

    private var messageInputBar: some View {
        HStack(spacing: 12) {
            TextField("Message...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(20)
                .lineLimit(1...4)

            Button(action: { Task { await sendMessage() } }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(canSend ? Color(hex: "#2C4F40") : Color.gray.opacity(0.5))
            }
            .disabled(!canSend || isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -4)
    }

    // MARK: - Helpers

    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadMessages() async {
        isLoading = true
        loadError = nil
        do {
            messages = try await messagingService.loadMessages(conversationId: conversation.id)
        } catch {
            loadError = error
            print("Failed to load messages: \(error)")
        }
        isLoading = false
    }

    private func sendMessage() async {
        guard canSend else { return }
        isSending = true

        let content = messageText
        messageText = ""

        do {
            let sentMessage = try await messagingService.sendMessage(
                conversationId: conversation.id,
                recipientId: conversation.otherUserId,
                content: content
            )
            messages.append(sentMessage)
        } catch {
            // Restore message text on failure
            messageText = content
            sendErrorMessage = "Failed to send message. Please check your connection and try again."
            showingSendError = true
            print("Failed to send message: \(error)")
        }

        isSending = false
    }

    private func subscribeToRealtime() {
        guard let currentUserId = supabaseManager.currentUser?.id else { return }

        realtimeManager.subscribeToDirectMessages(userId: currentUserId) { payload in
            // Only add messages from the other user in this conversation
            if payload.senderId == conversation.otherUserId {
                let newMessage = DirectMessage(
                    id: payload.id,
                    conversationId: conversation.id,
                    senderId: payload.senderId,
                    recipientId: payload.recipientId,
                    content: payload.content,
                    createdAt: payload.createdAt,
                    isRead: payload.isRead,
                    isFromCurrentUser: false
                )

                // Only add if not already present
                if !messages.contains(where: { $0.id == newMessage.id }) {
                    messages.append(newMessage)
                    // Mark as read since we're viewing the conversation
                    Task {
                        await messagingService.markMessageAsRead(messageId: newMessage.id)
                    }
                }
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: DirectMessage

    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 16))
                    .foregroundColor(message.isFromCurrentUser ? .white : ClubRalleyTheme.Colors.darkGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        message.isFromCurrentUser
                            ? Color(hex: "#2C4F40")
                            : Color.white
                    )
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)

                Text(message.formattedTime)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }

            if !message.isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DirectMessageView(
            conversation: DirectConversation(
                id: UUID(),
                otherUserId: UUID(),
                otherUserName: "Alex Johnson",
                otherUserUsername: "alexj",
                otherUserPhotoURL: "https://picsum.photos/100/100?random=301",
                isVerified: false,
                lastMessage: "See you at the game!",
                lastMessageAt: Date(),
                unreadCount: 0,
                createdAt: Date()
            ),
            messagingService: MessagingService()
        )
    }
}
