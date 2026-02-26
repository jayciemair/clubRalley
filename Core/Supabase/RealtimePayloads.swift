//
//  RealtimePayloads.swift
//  Club Ralley
//
//  Payload types for realtime subscription events
//

import Foundation

// MARK: - Payload Types

/// Payload for direct message events
struct DirectMessagePayload {
    let id: UUID
    let senderId: UUID
    let recipientId: UUID
    let content: String
    let isRead: Bool
    let createdAt: Date

    init?(from record: [String: Any]) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let senderIdString = record["sender_id"] as? String,
              let senderId = UUID(uuidString: senderIdString),
              let recipientIdString = record["recipient_id"] as? String,
              let recipientId = UUID(uuidString: recipientIdString),
              let content = record["content"] as? String else {
            return nil
        }

        self.id = id
        self.senderId = senderId
        self.recipientId = recipientId
        self.content = content
        self.isRead = record["is_read"] as? Bool ?? false

        if let createdAtString = record["created_at"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.createdAt = formatter.date(from: createdAtString) ?? Date()
        } else {
            self.createdAt = Date()
        }
    }
}

/// Payload for chat message events
struct ChatMessagePayload {
    let id: UUID
    let ralleyId: UUID
    let senderId: UUID
    let content: String
    let messageType: String
    let createdAt: Date

    init?(from record: [String: Any]) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let ralleyIdString = record["ralley_id"] as? String,
              let ralleyId = UUID(uuidString: ralleyIdString),
              let senderIdString = record["sender_id"] as? String,
              let senderId = UUID(uuidString: senderIdString),
              let content = record["content"] as? String else {
            return nil
        }

        self.id = id
        self.ralleyId = ralleyId
        self.senderId = senderId
        self.content = content
        self.messageType = record["message_type"] as? String ?? "text"

        if let createdAtString = record["created_at"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.createdAt = formatter.date(from: createdAtString) ?? Date()
        } else {
            self.createdAt = Date()
        }
    }
}

/// Payload for notification events
struct NotificationPayload {
    let id: UUID
    let userId: UUID
    let type: String
    let message: String
    let actorId: UUID?
    let postId: UUID?
    let ralleyId: UUID?
    let isRead: Bool
    let createdAt: Date

    init?(from record: [String: Any]) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let userIdString = record["user_id"] as? String,
              let userId = UUID(uuidString: userIdString),
              let type = record["type"] as? String,
              let message = record["message"] as? String else {
            return nil
        }

        self.id = id
        self.userId = userId
        self.type = type
        self.message = message
        self.isRead = record["is_read"] as? Bool ?? false

        if let actorIdString = record["actor_id"] as? String {
            self.actorId = UUID(uuidString: actorIdString)
        } else {
            self.actorId = nil
        }

        if let postIdString = record["post_id"] as? String {
            self.postId = UUID(uuidString: postIdString)
        } else {
            self.postId = nil
        }

        if let ralleyIdString = record["ralley_id"] as? String {
            self.ralleyId = UUID(uuidString: ralleyIdString)
        } else {
            self.ralleyId = nil
        }

        if let createdAtString = record["created_at"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.createdAt = formatter.date(from: createdAtString) ?? Date()
        } else {
            self.createdAt = Date()
        }
    }
}

/// Payload for participant change events
struct ParticipantChangePayload {
    enum ChangeType {
        case joined
        case updated
        case left
    }

    let type: ChangeType
    let userId: UUID?
    let ralleyId: UUID?
    let status: String?

    init(type: ChangeType, record: [String: Any]?) {
        self.type = type

        if let record = record {
            if let userIdString = record["user_id"] as? String {
                self.userId = UUID(uuidString: userIdString)
            } else {
                self.userId = nil
            }

            if let ralleyIdString = record["ralley_id"] as? String {
                self.ralleyId = UUID(uuidString: ralleyIdString)
            } else {
                self.ralleyId = nil
            }

            self.status = record["status"] as? String
        } else {
            self.userId = nil
            self.ralleyId = nil
            self.status = nil
        }
    }
}
