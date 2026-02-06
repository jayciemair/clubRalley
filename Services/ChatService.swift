//
//  ChatService.swift
//  Club Ralley
//
//  Service layer for group chat operations.
//  Uses chat_messages table with ralley_id as the chat identifier.
//  Each ralley has an implicit group chat for its participants.
//

import Foundation
import SwiftUI

/**
 * ChatService: Bridge between chat ViewModels and database
 *
 * Purpose: Handles all group chat-related operations
 * Strategy: Each ralley has an implicit group chat (no separate chat table needed)
 * Database: Uses chat_messages table with ralley_id as the chat identifier
 */
@MainActor
class ChatService: ObservableObject {

    // MARK: - Dependencies

    /// Supabase client for database operations
    private let supabase = SupabaseManager.shared

    // MARK: - Published Properties

    /// Loading state for UI spinners
    @Published var isLoading = false

    /// Last operation error for user feedback
    @Published var lastError: SupabaseManager.SupabaseError?

    /// Track last read message timestamps per chat (stored in UserDefaults)
    private var lastReadTimestamps: [UUID: Date] = [:]
    private let lastReadKey = "clubRalley_chatLastRead"

    // MARK: - Initialization

    init() {
        loadLastReadTimestamps()
    }

    // MARK: - Last Read Tracking

    /// Load last read timestamps from UserDefaults
    private func loadLastReadTimestamps() {
        if let data = UserDefaults.standard.data(forKey: lastReadKey),
           let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
            lastReadTimestamps = decoded.reduce(into: [:]) { result, pair in
                if let uuid = UUID(uuidString: pair.key) {
                    result[uuid] = pair.value
                }
            }
        }
    }

    /// Save last read timestamps to UserDefaults
    private func saveLastReadTimestamps() {
        let stringKeyed = lastReadTimestamps.reduce(into: [String: Date]()) { result, pair in
            result[pair.key.uuidString] = pair.value
        }
        if let data = try? JSONEncoder().encode(stringKeyed) {
            UserDefaults.standard.set(data, forKey: lastReadKey)
        }
    }

    /// Mark a chat as read (updates last read timestamp)
    func markChatAsRead(chatId: UUID) {
        lastReadTimestamps[chatId] = Date()
        saveLastReadTimestamps()
        print("ChatService: Marked chat \(chatId) as read")
    }

    /// Get last read timestamp for a chat
    func getLastReadTimestamp(chatId: UUID) -> Date? {
        return lastReadTimestamps[chatId]
    }

    /// Check if a chat has unread messages
    func hasUnreadMessages(chatId: UUID, lastMessageAt: Date?) -> Bool {
        guard let lastMessage = lastMessageAt else { return false }
        guard let lastRead = lastReadTimestamps[chatId] else { return true }
        return lastMessage > lastRead
    }

    // MARK: - Chat Creation

    /**
     * Create a new group chat for a ralley
     * Note: Chat is implicit - just send a welcome message
     * @param ralleyId: ID of the ralley
     * @param captainId: ID of the captain (host)
     * @returns: The ralley ID (used as chat ID)
     */
    func createRalleyChat(ralleyId: UUID, captainId: UUID) async throws -> UUID {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        do {
            // Send system message to start the chat
            let systemMessage = DatabaseChatMessageInsertRecord(
                ralley_id: ralleyId,
                sender_id: captainId,
                content: "Ralley chat created! Welcome everyone.",
                message_type: "system"
            )

            try await supabase.insert(systemMessage, into: "chat_messages")

            print("ChatService: Ralley chat created for ralley \(ralleyId)")
            return ralleyId

        } catch {
            print("ChatService: Create chat failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Loading Chats

    /**
     * Load all group chats for the current user
     * Finds ralleys user is participating in that have messages
     * @returns: Array of GroupChat models
     */
    func loadUserChats() async throws -> [GroupChat] {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Get ralleys user is participating in
            let participations: [DatabaseRalleyParticipantRecord] = try await supabase.query("ralley_participants")
                .select("*")
                .eq("user_id", value: currentUser.id)
                .execute()

            // Also get ralleys user is hosting
            let hostedRalleys: [DatabaseRalleyBasic] = try await supabase.query("ralleys")
                .select("id, host_user_id, title, sport, date_time, current_participants")
                .eq("host_user_id", value: currentUser.id)
                .execute()

            // Combine ralley IDs
            var ralleyIds = Set(participations.map { $0.ralley_id })
            for ralley in hostedRalleys {
                ralleyIds.insert(ralley.id)
            }

            // Load chat info for each ralley
            var chats: [GroupChat] = []

            for ralleyId in ralleyIds {
                if let chat = try? await loadChatForRalley(ralleyId: ralleyId, currentUserId: currentUser.id) {
                    chats.append(chat)
                }
            }

            // Sort by most recent message
            chats.sort { ($0.lastMessageAt ?? $0.createdAt) > ($1.lastMessageAt ?? $1.createdAt) }

            print("ChatService: Loaded \(chats.count) chats from database")
            return chats

        } catch {
            print("ChatService: Load chats failed: \(error)")
            return generateMockChats()
        }
    }

    /**
     * Load chat details for a specific ralley
     */
    private func loadChatForRalley(ralleyId: UUID, currentUserId: UUID) async throws -> GroupChat {
        // Load ralley info
        let ralleys: [DatabaseRalleyBasic] = try await supabase.query("ralleys")
            .select("id, host_user_id, title, sport, date_time, current_participants")
            .eq("id", value: ralleyId)
            .execute()

        guard let ralley = ralleys.first else {
            throw SupabaseManager.SupabaseError.networkError("Ralley not found")
        }

        // Get last message
        let messages: [DatabaseChatMessageRecord] = try await supabase.query("chat_messages")
            .select("*")
            .eq("ralley_id", value: ralleyId)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()

        let lastMessage = messages.first

        // Determine user's role
        let isHost = ralley.host_user_id == currentUserId
        let role: ChatMemberRole = isHost ? .admin : .member

        // Check for unread messages
        let hasUnread = hasUnreadMessages(chatId: ralleyId, lastMessageAt: lastMessage?.created_at)

        return GroupChat(
            id: ralleyId, // Use ralley ID as chat ID
            ralleyId: ralleyId,
            ralleyTitle: ralley.title,
            ralleySport: ralley.sport ?? "Sports",
            ralleyDateTime: ralley.date_time,
            createdAt: ralley.date_time,
            memberCount: ralley.current_participants,
            lastMessage: lastMessage?.content,
            lastMessageAt: lastMessage?.created_at,
            hasUnread: hasUnread,
            currentUserRole: role
        )
    }

    // MARK: - Loading Messages

    /**
     * Load messages for a chat (ralley)
     * @param chatId: ID of the ralley (used as chat ID)
     * @param limit: Maximum messages to load
     * @param before: Load messages before this date (for pagination)
     * @returns: Array of GroupChatMessage models
     */
    func loadMessages(chatId: UUID, limit: Int = 50, before: Date? = nil) async throws -> [GroupChatMessage] {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        do {
            // Load messages with sender info
            let dbMessages: [DatabaseChatMessageWithSender] = try await supabase.query("chat_messages")
                .select("*, club_users(id, first_name, last_name, username, profile_photo_url)")
                .eq("ralley_id", value: chatId)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()

            let messages = dbMessages.map { msg in
                GroupChatMessage(
                    id: msg.id,
                    chatId: chatId,
                    senderId: msg.sender_id,
                    senderName: "\(msg.sender.first_name) \(msg.sender.last_name)",
                    senderUsername: msg.sender.username,
                    senderPhotoURL: msg.sender.profile_photo_url,
                    content: msg.content,
                    messageType: ChatMessageType(rawValue: msg.message_type) ?? .text,
                    createdAt: msg.created_at,
                    isFromCurrentUser: msg.sender_id == currentUser.id
                )
            }

            print("ChatService: Loaded \(messages.count) messages for ralley \(chatId)")

            // Return in chronological order
            return messages.reversed()

        } catch {
            print("ChatService: Load messages failed: \(error)")
            return generateMockMessages(chatId: chatId)
        }
    }

    // MARK: - Sending Messages

    /**
     * Send a message in a chat
     * @param chatId: ID of the ralley (used as chat ID)
     * @param content: Message content
     * @returns: The sent message
     */
    func sendMessage(chatId: UUID, content: String) async throws -> GroupChatMessage {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw SupabaseManager.SupabaseError.networkError("Message cannot be empty")
        }

        do {
            let messageInsert = DatabaseChatMessageInsertRecord(
                ralley_id: chatId,
                sender_id: currentUser.id,
                content: trimmedContent,
                message_type: "text"
            )

            try await supabase.insert(messageInsert, into: "chat_messages")

            print("ChatService: Message sent to ralley chat \(chatId)")

            // Return the message for immediate UI update
            return GroupChatMessage(
                id: UUID(),
                chatId: chatId,
                senderId: currentUser.id,
                senderName: currentUser.displayName,
                senderUsername: currentUser.email.components(separatedBy: "@").first ?? "user",
                senderPhotoURL: nil,
                content: trimmedContent,
                messageType: .text,
                createdAt: Date(),
                isFromCurrentUser: true
            )

        } catch {
            print("ChatService: Send message failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Member Management

    /**
     * Add a member to a chat (adds to ralley participants)
     * @param chatId: ID of the ralley
     * @param userId: ID of the user to add
     * @param role: Role to assign (default: member)
     */
    func addMember(chatId: UUID, userId: UUID, role: ChatMemberRole = .member) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        do {
            // Add to ralley participants
            let participant = DatabaseRalleyParticipantInsert(
                ralley_id: chatId,
                user_id: userId,
                status: "joined"
            )

            try await supabase.insert(participant, into: "ralley_participants")

            // Send system message
            if let currentUser = supabase.currentUser {
                let systemMessage = DatabaseChatMessageInsertRecord(
                    ralley_id: chatId,
                    sender_id: currentUser.id,
                    content: "A new member joined the ralley!",
                    message_type: "system"
                )
                try await supabase.insert(systemMessage, into: "chat_messages")
            }

            print("ChatService: Added member \(userId) to ralley \(chatId)")

        } catch {
            print("ChatService: Add member failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    /**
     * Remove a member from a chat (removes from ralley participants)
     * @param chatId: ID of the ralley
     * @param userId: ID of the user to remove
     */
    func removeMember(chatId: UUID, userId: UUID) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        do {
            try await supabase.delete(
                from: "ralley_participants",
                where: "ralley_id = '\(chatId)' AND user_id = '\(userId)'"
            )

            print("ChatService: Removed member \(userId) from ralley \(chatId)")

        } catch {
            print("ChatService: Remove member failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    /**
     * Load members of a chat (ralley participants)
     * @param chatId: ID of the ralley
     * @returns: Array of GroupChatMember models
     */
    func loadMembers(chatId: UUID) async throws -> [GroupChatMember] {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        do {
            // Get ralley host
            let ralleys: [DatabaseRalleyBasic] = try await supabase.query("ralleys")
                .select("id, host_user_id, title, sport, date_time, current_participants")
                .eq("id", value: chatId)
                .execute()

            let hostId = ralleys.first?.host_user_id

            // Get participants with user info
            let dbParticipants: [DatabaseChatParticipantWithUser] = try await supabase.query("ralley_participants")
                .select("*, club_users(id, first_name, last_name, username, profile_photo_url)")
                .eq("ralley_id", value: chatId)
                .execute()

            var members = dbParticipants.map { participant in
                let isHost = participant.user_id == hostId
                return GroupChatMember(
                    id: participant.user_id,
                    name: "\(participant.user.first_name) \(participant.user.last_name)",
                    username: participant.user.username,
                    photoURL: participant.user.profile_photo_url,
                    role: isHost ? .admin : .member,
                    joinedAt: participant.joined_at,
                    isCurrentUser: participant.user_id == currentUser.id
                )
            }

            // Also add host if not in participants
            if let hostId = hostId, !members.contains(where: { $0.id == hostId }) {
                if let hostInfo = try? await loadHostInfo(hostId: hostId) {
                    let hostMember = GroupChatMember(
                        id: hostId,
                        name: "\(hostInfo.first_name) \(hostInfo.last_name)",
                        username: hostInfo.username,
                        photoURL: hostInfo.profile_photo_url,
                        role: .admin,
                        joinedAt: Date(),
                        isCurrentUser: hostId == currentUser.id
                    )
                    members.insert(hostMember, at: 0)
                }
            }

            print("ChatService: Loaded \(members.count) members for ralley \(chatId)")
            return members

        } catch {
            print("ChatService: Load members failed: \(error)")
            return []
        }
    }

    private func loadHostInfo(hostId: UUID) async throws -> DatabaseUserBasic {
        let users: [DatabaseUserBasic] = try await supabase.query("club_users")
            .select("id, first_name, last_name, username, profile_photo_url")
            .eq("id", value: hostId)
            .execute()

        guard let user = users.first else {
            throw SupabaseManager.SupabaseError.userNotFound
        }
        return user
    }

    /**
     * Update last read timestamp (stub - not implemented yet)
     * @param chatId: ID of the ralley
     */
    func markAsRead(chatId: UUID) async throws {
        // TODO: Implement unread tracking
        print("ChatService: markAsRead called for chat \(chatId)")
    }

    // MARK: - Mock Data Generation (Fallback)

    private func generateMockChats() -> [GroupChat] {
        return [
            GroupChat(
                id: UUID(),
                ralleyId: UUID(),
                ralleyTitle: "Basketball Pickup",
                ralleySport: "Basketball",
                ralleyDateTime: Date().addingTimeInterval(3600 * 2),
                createdAt: Date().addingTimeInterval(-3600 * 24),
                memberCount: 6,
                lastMessage: "Can't wait for tomorrow!",
                lastMessageAt: Date().addingTimeInterval(-1800),
                hasUnread: true,
                currentUserRole: .member
            ),
            GroupChat(
                id: UUID(),
                ralleyId: UUID(),
                ralleyTitle: "Tennis Doubles",
                ralleySport: "Tennis",
                ralleyDateTime: Date().addingTimeInterval(3600 * 24),
                createdAt: Date().addingTimeInterval(-3600 * 48),
                memberCount: 4,
                lastMessage: "Who's bringing extra balls?",
                lastMessageAt: Date().addingTimeInterval(-7200),
                hasUnread: false,
                currentUserRole: .admin
            )
        ]
    }

    private func generateMockMessages(chatId: UUID) -> [GroupChatMessage] {
        let now = Date()
        return [
            GroupChatMessage(
                id: UUID(),
                chatId: chatId,
                senderId: UUID(),
                senderName: "Alex Johnson",
                senderUsername: "alexj",
                senderPhotoURL: "https://picsum.photos/44/44?random=20",
                content: "Hey everyone! Excited for the game!",
                messageType: .text,
                createdAt: now.addingTimeInterval(-3600),
                isFromCurrentUser: false
            ),
            GroupChatMessage(
                id: UUID(),
                chatId: chatId,
                senderId: UUID(),
                senderName: "Sarah Chen",
                senderUsername: "sarahc",
                senderPhotoURL: "https://picsum.photos/44/44?random=21",
                content: "Same! I'll bring some water bottles",
                messageType: .text,
                createdAt: now.addingTimeInterval(-1800),
                isFromCurrentUser: false
            )
        ]
    }
}

// MARK: - Database Models for Chat Messages

/// Database record for chat messages
struct DatabaseChatMessageRecord: Codable {
    let id: UUID
    let ralley_id: UUID
    let sender_id: UUID
    let content: String
    let message_type: String
    let created_at: Date
}

/// Database chat message with sender info
struct DatabaseChatMessageWithSender: Codable {
    let id: UUID
    let ralley_id: UUID
    let sender_id: UUID
    let content: String
    let message_type: String
    let created_at: Date
    let sender: DatabaseUserBasic

    enum CodingKeys: String, CodingKey {
        case id, ralley_id, sender_id, content, message_type, created_at
        case sender = "club_users"
    }
}

/// Database insert for chat messages
struct DatabaseChatMessageInsertRecord: Codable {
    let ralley_id: UUID
    let sender_id: UUID
    let content: String
    let message_type: String
}

/// Basic ralley info for chat queries
struct DatabaseRalleyBasic: Codable {
    let id: UUID
    let host_user_id: UUID
    let title: String
    let sport: String?
    let date_time: Date
    let current_participants: Int
}

/// Ralley participant record
struct DatabaseRalleyParticipantRecord: Codable {
    let id: UUID
    let ralley_id: UUID
    let user_id: UUID
    let status: String
    let joined_at: Date
}

/// Ralley participant insert
struct DatabaseRalleyParticipantInsert: Codable {
    let ralley_id: UUID
    let user_id: UUID
    let status: String
}

/// Ralley participant with user info
struct DatabaseChatParticipantWithUser: Codable {
    let id: UUID
    let ralley_id: UUID
    let user_id: UUID
    let status: String
    let joined_at: Date
    let user: DatabaseUserBasic

    enum CodingKeys: String, CodingKey {
        case id, ralley_id, user_id, status, joined_at
        case user = "club_users"
    }
}
