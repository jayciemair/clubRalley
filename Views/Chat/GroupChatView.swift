//
//  GroupChatView.swift
//  Club Ralley
//
//  Chat messaging interface for ralley group chats.
//

import SwiftUI

struct GroupChatView: View {
    @StateObject private var viewModel: GroupChatViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool

    init(chat: GroupChat) {
        _viewModel = StateObject(wrappedValue: GroupChatViewModel(chat: chat))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            messagesScrollView

            // Input bar
            messageInputBar
        }
        .navigationTitle(viewModel.chat.ralleyTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {}) {
                        Label("View Members", systemImage: "person.2")
                    }

                    if viewModel.chat.isAdmin {
                        Button(action: {}) {
                            Label("Manage Chat", systemImage: "gearshape")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
    }

    // MARK: - Messages Scroll View

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    // Chat header
                    chatHeader

                    // Messages
                    ForEach(viewModel.messages) { message in
                        GroupChatMessageRow(message: message)
                            .id(message.id)
                    }

                    // Loading indicator at bottom
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                // Scroll to bottom on new messages
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(hex: "#F5F5F5"))
    }

    // MARK: - Chat Header

    private var chatHeader: some View {
        VStack(spacing: 12) {
            // Sport icon
            ZStack {
                Circle()
                    .fill(Color(hex: "#2C4F40").opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }

            Text(viewModel.chat.ralleyTitle)
                .font(.system(size: 18, weight: .semibold))

            Text("\(viewModel.chat.memberCount) members")
                .font(.system(size: 14))
                .foregroundColor(.gray)

            Text("Chat created for this ralley")
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .padding(.top, 4)
        }
        .padding(.vertical, 24)
    }

    // MARK: - Message Input Bar

    private var messageInputBar: some View {
        HStack(spacing: 12) {
            // Text field
            TextField("Message...", text: $viewModel.messageText, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
                .lineLimit(1...5)
                .focused($isInputFocused)

            // Send button
            Button(action: { Task { await viewModel.sendMessage() } }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(viewModel.canSend ? Color(hex: "#2C4F40") : Color.gray.opacity(0.5))
            }
            .disabled(!viewModel.canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: -2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GroupChatView(chat: GroupChat(
            id: UUID(),
            ralleyId: UUID(),
            ralleyTitle: "Basketball Pickup",
            ralleySport: "Basketball",
            ralleyDateTime: Date().addingTimeInterval(3600),
            createdAt: Date(),
            memberCount: 6,
            lastMessage: nil,
            lastMessageAt: nil,
            hasUnread: false,
            currentUserRole: .member
        ))
    }
}
