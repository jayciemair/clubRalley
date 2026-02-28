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
    @State private var showingMembers = false

    init(chat: GroupChat) {
        _viewModel = StateObject(wrappedValue: GroupChatViewModel(chat: chat))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            messagesScrollView
                .onTapGesture {
                    isInputFocused = false
                }

            // Input bar
            messageInputBar
        }
        .navigationTitle(viewModel.chat.ralleyTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingMembers = true }) {
                    Image(systemName: "person.2")
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
        .sheet(isPresented: $showingMembers) {
            GroupChatMembersSheet(members: viewModel.members, ralleyTitle: viewModel.chat.ralleyTitle)
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

// MARK: - Members Sheet

struct GroupChatMembersSheet: View {
    let members: [GroupChatMember]
    let ralleyTitle: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(members) { member in
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: member.photoURL ?? "")) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color(hex: "#2C4F40").opacity(0.2))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "#2C4F40"))
                            )
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(member.name)
                                .font(.system(size: 16, weight: .medium))

                            if member.isAdmin {
                                Text("Host")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: "#2C4F40"))
                                    .cornerRadius(4)
                            }
                        }

                        Text("@\(member.username)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    if member.isCurrentUser {
                        Text("You")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
            .navigationTitle("Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
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
