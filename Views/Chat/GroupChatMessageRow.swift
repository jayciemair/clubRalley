//
//  GroupChatMessageRow.swift
//  Club Ralley
//
//  Individual message bubble for group chat.
//

import SwiftUI

struct GroupChatMessageRow: View {
    let message: GroupChatMessage

    var body: some View {
        if message.isSystemMessage {
            systemMessageView
        } else if message.isFromCurrentUser {
            outgoingMessageView
        } else {
            incomingMessageView
        }
    }

    // MARK: - System Message

    private var systemMessageView: some View {
        HStack {
            Spacer()

            Text(message.content)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Outgoing Message (Current User)

    private var outgoingMessageView: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Spacer(minLength: 60)

            VStack(alignment: .trailing, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#2C4F40"))
                    .cornerRadius(18)
                    .cornerRadius(4, corners: .bottomRight)

                Text(message.formattedTime)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Incoming Message (Other User)

    private var incomingMessageView: some View {
        HStack(alignment: .top, spacing: 8) {
            // Avatar
            AsyncImage(url: URL(string: message.senderPhotoURL ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle().fill(Color(hex: "#2C4F40").opacity(0.3))
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                // Sender name
                Text(message.senderName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)

                // Message bubble
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(18)
                    .cornerRadius(4, corners: .bottomLeft)
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)

                // Time
                Text(message.formattedTime)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }

            Spacer(minLength: 60)
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        GroupChatMessageRow(message: GroupChatMessage(
            id: UUID(),
            chatId: UUID(),
            senderId: UUID(),
            senderName: "Alex Johnson",
            senderUsername: "alexj",
            senderPhotoURL: "https://picsum.photos/44/44?random=20",
            content: "Hey everyone! Can't wait for the game!",
            messageType: .text,
            createdAt: Date(),
            isFromCurrentUser: false
        ))

        GroupChatMessageRow(message: GroupChatMessage(
            id: UUID(),
            chatId: UUID(),
            senderId: UUID(),
            senderName: "You",
            senderUsername: "me",
            senderPhotoURL: nil,
            content: "Same here! See you all there",
            messageType: .text,
            createdAt: Date(),
            isFromCurrentUser: true
        ))

        GroupChatMessageRow(message: GroupChatMessage(
            id: UUID(),
            chatId: UUID(),
            senderId: nil,
            senderName: "System",
            senderUsername: "system",
            senderPhotoURL: nil,
            content: "Sarah joined the chat",
            messageType: .system,
            createdAt: Date(),
            isFromCurrentUser: false
        ))
    }
    .padding()
    .background(Color(hex: "#F5F5F5"))
}
