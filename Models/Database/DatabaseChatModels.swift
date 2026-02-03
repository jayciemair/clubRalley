//
//  DatabaseChatModels.swift
//  Club Ralley
//
//  Database models for chat-related Supabase tables.
//  Includes ralley_chats, chat_members, and chat_messages.
//

import Foundation

// MARK: - Ralley Chat Database Models

/**
 * Database representation of a ralley group chat
 */
struct DatabaseRalleyChat: Codable {
    let id: UUID
    let ralley_id: UUID
    let created_at: Date
}

/**
 * Database representation for creating a new ralley chat
 */
struct DatabaseRalleyChatInsert: Codable {
    let ralley_id: UUID
}

/**
 * Database ralley chat with joined ralley information
 */
struct DatabaseRalleyChatWithRalley: Codable {
    let id: UUID
    let ralley_id: UUID
    let created_at: Date
    let ralley: DatabaseRalleyChatRalleyInfo

    enum CodingKeys: String, CodingKey {
        case id
        case ralley_id
        case created_at
        case ralley = "ralleys"
    }
}

/**
 * Ralley info for chat queries
 */
struct DatabaseRalleyChatRalleyInfo: Codable {
    let title: String
    let category: String
    let date_time: Date
}

// MARK: - Chat Member Database Models

/**
 * Database representation of a chat member
 */
struct DatabaseChatMember: Codable {
    let id: UUID
    let chat_id: UUID
    let user_id: UUID
    let role: String
    let joined_at: Date
    let last_read_at: Date?
}

/**
 * Database representation for inserting a chat member
 */
struct DatabaseChatMemberInsert: Codable {
    let chat_id: UUID
    let user_id: UUID
    let role: String
}

/**
 * Database chat member with joined user information
 */
struct DatabaseChatMemberWithUser: Codable {
    let id: UUID
    let chat_id: UUID
    let user_id: UUID
    let role: String
    let joined_at: Date
    let last_read_at: Date?
    let user: DatabaseUser

    enum CodingKeys: String, CodingKey {
        case id
        case chat_id
        case user_id
        case role
        case joined_at
        case last_read_at
        case user = "club_users"
    }
}

// MARK: - Chat Message Database Models

/**
 * Database representation of a chat message
 */
struct DatabaseChatMessage: Codable {
    let id: UUID
    let chat_id: UUID
    let sender_id: UUID
    let content: String
    let message_type: String
    let created_at: Date
}

/**
 * Database representation for inserting a chat message
 */
struct DatabaseChatMessageInsert: Codable {
    let chat_id: UUID
    let sender_id: UUID
    let content: String
    let message_type: String
}

/**
 * Database chat message with joined sender information
 */
struct DatabaseChatMessageWithUser: Codable {
    let id: UUID
    let chat_id: UUID
    let sender_id: UUID
    let content: String
    let message_type: String
    let created_at: Date
    let sender: DatabaseUser

    enum CodingKeys: String, CodingKey {
        case id
        case chat_id
        case sender_id
        case content
        case message_type
        case created_at
        case sender = "club_users"
    }
}

// MARK: - Pending Request Database Models

/**
 * Database ralley participant with user info for pending requests
 */
struct DatabasePendingRequestWithUser: Codable {
    let id: UUID
    let ralley_id: UUID
    let user_id: UUID
    let status: String
    let created_at: Date
    let user: DatabaseUser

    enum CodingKeys: String, CodingKey {
        case id
        case ralley_id
        case user_id
        case status
        case created_at
        case user = "club_users"
    }
}

// MARK: - Direct Message Database Models

/**
 * Database representation of a direct message conversation
 */
struct DatabaseDirectConversation: Codable {
    let id: UUID
    let user1_id: UUID
    let user2_id: UUID
    let created_at: Date
    let updated_at: Date
}

/**
 * Database representation for creating a new conversation
 */
struct DatabaseDirectConversationInsert: Codable {
    let user1_id: UUID
    let user2_id: UUID
}

/**
 * Database direct conversation with user information
 */
struct DatabaseDirectConversationWithUsers: Codable {
    let id: UUID
    let user1_id: UUID
    let user2_id: UUID
    let created_at: Date
    let updated_at: Date
    let user1: DatabaseUser?
    let user2: DatabaseUser?

    enum CodingKeys: String, CodingKey {
        case id
        case user1_id
        case user2_id
        case created_at
        case updated_at
        case user1 = "user1:club_users!user1_id"
        case user2 = "user2:club_users!user2_id"
    }
}

/**
 * Database representation of a direct message
 */
struct DatabaseDirectMessage: Codable {
    let id: UUID
    let conversation_id: UUID
    let sender_id: UUID
    let recipient_id: UUID
    let content: String
    let is_read: Bool
    let created_at: Date
}

/**
 * Database representation for inserting a direct message
 */
struct DatabaseDirectMessageInsert: Codable {
    let conversation_id: UUID
    let sender_id: UUID
    let recipient_id: UUID
    let content: String
}

/**
 * Database direct message with sender information
 */
struct DatabaseDirectMessageWithUser: Codable {
    let id: UUID
    let conversation_id: UUID
    let sender_id: UUID
    let recipient_id: UUID
    let content: String
    let is_read: Bool
    let created_at: Date
    let sender: DatabaseUser

    enum CodingKeys: String, CodingKey {
        case id
        case conversation_id
        case sender_id
        case recipient_id
        case content
        case is_read
        case created_at
        case sender = "club_users"
    }
}
