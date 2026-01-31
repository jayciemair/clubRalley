//
//  ChatsListView.swift
//  Club Ralley
//
//  List view showing user's group chats.
//

import SwiftUI

struct ChatsListView: View {
    @StateObject private var viewModel = ChatsListViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.chats.isEmpty {
                loadingView
            } else if viewModel.chats.isEmpty {
                emptyState
            } else {
                chatsList
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.badge.circle")
                .font(.system(size: 56))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.5))

            Text("No Group Chats")
                .font(.system(size: 20, weight: .semibold))

            Text("When you join or create a ralley, you'll be added to its group chat.")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Chats List

    private var chatsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.chats) { chat in
                    NavigationLink(destination: GroupChatView(chat: chat)) {
                        ChatListRow(chat: chat)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if chat.id != viewModel.chats.last?.id {
                        Divider()
                            .padding(.leading, 76)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
}

// MARK: - Chat List Row

private struct ChatListRow: View {
    let chat: GroupChat

    var body: some View {
        HStack(spacing: 12) {
            // Chat icon with sport
            ZStack {
                Circle()
                    .fill(Color(hex: "#2C4F40").opacity(0.1))
                    .frame(width: 52, height: 52)

                Image(systemName: sportIcon)
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }

            // Chat info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.ralleyTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .lineLimit(1)

                    Spacer()

                    if let timeAgo = chat.lastMessageTimeAgo {
                        Text(timeAgo)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }

                HStack {
                    if let lastMessage = chat.lastMessage {
                        Text(lastMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    } else {
                        Text("No messages yet")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .italic()
                    }

                    Spacer()

                    if chat.hasUnread {
                        Circle()
                            .fill(Color(hex: "#2C4F40"))
                            .frame(width: 10, height: 10)
                    }
                }

                // Member count and role
                HStack(spacing: 8) {
                    Text("\(chat.memberCount) members")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    if chat.isAdmin {
                        Text("Admin")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "#2C4F40"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#2C4F40").opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var sportIcon: String {
        switch chat.ralleySport.lowercased() {
        case "basketball", "sports": return "basketball.fill"
        case "tennis": return "tennisball.fill"
        case "soccer", "football": return "soccerball"
        case "fitness": return "figure.run"
        case "outdoor": return "mountain.2.fill"
        default: return "sportscourt.fill"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ChatsListView()
    }
}
