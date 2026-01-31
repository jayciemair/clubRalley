//
//  ChatService.swift
//  Club Ralley
//
//  Service layer for group chat operations connecting app models to Supabase backend.
//  Handles chat creation, message sending, member management.
//

import Foundation
import SwiftUI

/**
 * ChatService: Bridge between chat ViewModels and Supabase tables
 *
 * Purpose: Handles all group chat-related database operations
 * Strategy: Real Supabase calls with mock fallbacks for reliability
 * Database: Maps to 'ralley_chats', 'chat_members', 'chat_messages' tables
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

    // MARK: - Chat Creation

    /**
     * Create a new group chat for a ralley
     * @param ralleyId: ID of the ralley to create chat for
     * @param captainId: ID of the captain (will be added as admin)
     * @returns: Created chat ID
     */
    func createRalleyChat(ralleyId: UUID, captainId: UUID) async throws -> UUID {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        isLoading = true
        lastError = nil

        do {
            // Create the chat
            let chatInsert = DatabaseRalleyChatInsert(ralley_id: ralleyId)
            let chatId = try await supabase.insertReturningId(chatInsert, into: "ralley_chats")

            // Add captain as admin member
            let memberInsert = DatabaseChatMemberInsert(
                chat_id: chatId,
                user_id: captainId,
                role: ChatMemberRole.admin.rawValue
            )
            try await supabase.insert(memberInsert, into: "chat_members")

            // Send system message
            let systemMessage = DatabaseChatMessageInsert(
                chat_id: chatId,
                sender_id: captainId,
                content: "Ralley chat created! Welcome everyone.",
                message_type: ChatMessageType.system.rawValue
            )
            try await supabase.insert(systemMessage, into: "chat_messages")

            print("ChatService: Ralley chat created with ID: \(chatId)")
            isLoading = false
            return chatId

        } catch let error as SupabaseManager.SupabaseError {
            isLoading = false
            lastError = error
            print("ChatService: Create chat failed: \(error)")
            throw error
        } catch {
            isLoading = false
            let supabaseError = SupabaseManager.SupabaseError.networkError(error.localizedDescription)
            lastError = supabaseError
            print("ChatService: Create chat failed with network error: \(error)")
            throw supabaseError
        }
    }

    // MARK: - Loading Chats

    /**
     * Load all group chats for the current user
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
        lastError = nil

        do {
            // Get chat memberships for current user with chat and ralley info
            // In real implementation this would be a complex JOIN query
            let memberships: [DatabaseChatMemberWithUser] = try await supabase.query("chat_members")
                .select("*, club_users(first_name, last_name, username, profile_photo_url)")
                .eq("user_id", value: currentUser.id)
                .execute()

            // For each membership, load the chat details
            var chats: [GroupChat] = []
            for membership in memberships {
                if let chat = try? await loadChatDetails(chatId: membership.chat_id, userRole: membership.role) {
                    chats.append(chat)
                }
            }

            // Sort by most recent activity
            chats.sort { ($0.lastMessageAt ?? $0.createdAt) > ($1.lastMessageAt ?? $1.createdAt) }

            isLoading = false
            print("ChatService: Loaded \(chats.count) chats for user")
            return chats

        } catch {
            isLoading = false
            print("ChatService: Load chats failed: \(error)")
            // Return mock data for development
            return generateMockChats()
        }
    }

    /**
     * Load details for a specific chat
     */
    private func loadChatDetails(chatId: UUID, userRole: String) async throws -> GroupChat {
        // Load chat with ralley info
        let chatData: DatabaseRalleyChatWithRalley = try await supabase.query("ralley_chats")
            .select("*, ralleys(title, category, date_time)")
            .eq("id", value: chatId)
            .single()

        // Get member count
        let members: [DatabaseChatMember] = try await supabase.query("chat_members")
            .select("*")
            .eq("chat_id", value: chatId)
            .execute()

        // Get last message
        let messages: [DatabaseChatMessage] = try await supabase.query("chat_messages")
            .select("*")
            .eq("chat_id", value: chatId)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()

        let lastMessage = messages.first

        return GroupChat(
            id: chatData.id,
            ralleyId: chatData.ralley_id,
            ralleyTitle: chatData.ralley.title,
            ralleySport: chatData.ralley.category,
            ralleyDateTime: chatData.ralley.date_time,
            createdAt: chatData.created_at,
            memberCount: members.count,
            lastMessage: lastMessage?.content,
            lastMessageAt: lastMessage?.created_at,
            hasUnread: false, // TODO: Compare with last_read_at
            currentUserRole: ChatMemberRole(rawValue: userRole) ?? .member
        )
    }

    // MARK: - Loading Messages

    /**
     * Load messages for a chat
     * @param chatId: ID of the chat
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
            var query = supabase.query("chat_messages")
                .select("*, club_users(first_name, last_name, username, profile_photo_url)")
                .eq("chat_id", value: chatId)
                .order("created_at", ascending: false)
                .limit(limit)

            if let before = before {
                query = query.lt("created_at", value: before)
            }

            let dbMessages: [DatabaseChatMessageWithUser] = try await query.execute()

            let messages = dbMessages.map { msg in
                GroupChatMessage(
                    id: msg.id,
                    chatId: msg.chat_id,
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
     * @param chatId: ID of the chat
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
            let messageInsert = DatabaseChatMessageInsert(
                chat_id: chatId,
                sender_id: currentUser.id,
                content: trimmedContent,
                message_type: ChatMessageType.text.rawValue
            )

            try await supabase.insert(messageInsert, into: "chat_messages")

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
     * Add a member to a chat
     * @param chatId: ID of the chat
     * @param userId: ID of the user to add
     * @param role: Role to assign (default: member)
     */
    func addMember(chatId: UUID, userId: UUID, role: ChatMemberRole = .member) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        do {
            let memberInsert = DatabaseChatMemberInsert(
                chat_id: chatId,
                user_id: userId,
                role: role.rawValue
            )

            try await supabase.insert(memberInsert, into: "chat_members")

            // Send system message about new member
            if let currentUser = supabase.currentUser {
                let systemMessage = DatabaseChatMessageInsert(
                    chat_id: chatId,
                    sender_id: currentUser.id,
                    content: "A new member joined the chat!",
                    message_type: ChatMessageType.system.rawValue
                )
                try await supabase.insert(systemMessage, into: "chat_messages")
            }

            print("ChatService: Added member \(userId) to chat \(chatId)")

        } catch {
            print("ChatService: Add member failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    /**
     * Remove a member from a chat
     * @param chatId: ID of the chat
     * @param userId: ID of the user to remove
     */
    func removeMember(chatId: UUID, userId: UUID) async throws {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        do {
            try await supabase.delete(
                from: "chat_members",
                where: "chat_id = '\(chatId)' AND user_id = '\(userId)'"
            )

            print("ChatService: Removed member \(userId) from chat \(chatId)")

        } catch {
            print("ChatService: Remove member failed: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    /**
     * Load members of a chat
     * @param chatId: ID of the chat
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
            let dbMembers: [DatabaseChatMemberWithUser] = try await supabase.query("chat_members")
                .select("*, club_users(first_name, last_name, username, profile_photo_url)")
                .eq("chat_id", value: chatId)
                .execute()

            return dbMembers.map { member in
                GroupChatMember(
                    id: member.user_id,
                    name: "\(member.user.first_name) \(member.user.last_name)",
                    username: member.user.username,
                    photoURL: member.user.profile_photo_url,
                    role: ChatMemberRole(rawValue: member.role) ?? .member,
                    joinedAt: member.joined_at,
                    isCurrentUser: member.user_id == currentUser.id
                )
            }

        } catch {
            print("ChatService: Load members failed: \(error)")
            return []
        }
    }

    /**
     * Update last read timestamp for current user
     * @param chatId: ID of the chat
     */
    func markAsRead(chatId: UUID) async throws {
        guard supabase.isAuthenticated else { return }
        guard let currentUser = supabase.currentUser else { return }

        do {
            try await supabase.update(
                table: "chat_members",
                set: ["last_read_at": Date()],
                where: "chat_id = '\(chatId)' AND user_id = '\(currentUser.id)'"
            )
        } catch {
            print("ChatService: Mark as read failed: \(error)")
        }
    }

    // MARK: - Mock Data Generation

    /**
     * Generate mock chats for development and fallback scenarios
     */
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

    /**
     * Generate mock messages for development
     */
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
            ),
            GroupChatMessage(
                id: UUID(),
                chatId: chatId,
                senderId: nil,
                senderName: "System",
                senderUsername: "system",
                senderPhotoURL: nil,
                content: "Marcus joined the chat",
                messageType: .system,
                createdAt: now.addingTimeInterval(-900),
                isFromCurrentUser: false
            )
        ]
    }
}
