//
//  MessagingService.swift
//  Club Ralley
//
//  Service for direct messaging operations
//

import Foundation
import SwiftUI

@MainActor
class MessagingService: ObservableObject {

    // MARK: - Dependencies

    private let supabase = SupabaseManager.shared

    // MARK: - Published Properties

    @Published var conversations: [DirectConversation] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Load Conversations

    /// Load all direct message conversations for the current user
    func loadConversations() async {
        guard supabase.isAuthenticated else { return }
        guard let currentUser = supabase.currentUser else { return }

        isLoading = true
        error = nil

        do {
            // Load conversations where user is participant
            let convos: [DatabaseDirectConversation] = try await supabase.query("direct_conversations")
                .select("*")
                .or("user1_id.eq.\(currentUser.id),user2_id.eq.\(currentUser.id)")
                .order("updated_at", ascending: false)
                .execute()

            // Map to UI model with other user info
            var loadedConversations: [DirectConversation] = []

            for convo in convos {
                let otherUserId = convo.user1_id == currentUser.id ? convo.user2_id : convo.user1_id

                // Load other user's info
                let users: [DatabaseUserProfile] = try await supabase.query("club_users")
                    .select("*")
                    .eq("id", value: otherUserId)
                    .execute()

                guard let otherUser = users.first else { continue }

                // Load last message
                let messages: [DatabaseDirectMessage] = try await supabase.query("direct_messages")
                    .select("*")
                    .eq("conversation_id", value: convo.id)
                    .order("created_at", ascending: false)
                    .limit(1)
                    .execute()

                let lastMessage = messages.first

                // Count unread messages
                let unreadMessages: [DatabaseDirectMessage] = try await supabase.query("direct_messages")
                    .select("*")
                    .eq("conversation_id", value: convo.id)
                    .eq("recipient_id", value: currentUser.id)
                    .eq("is_read", value: false)
                    .execute()

                let conversation = DirectConversation(
                    id: convo.id,
                    otherUserId: otherUserId,
                    otherUserName: "\(otherUser.first_name) \(otherUser.last_name)",
                    otherUserUsername: otherUser.username,
                    otherUserPhotoURL: otherUser.profile_photo_url,
                    isVerified: otherUser.is_verified_athlete,
                    lastMessage: lastMessage?.content,
                    lastMessageAt: lastMessage?.created_at,
                    unreadCount: unreadMessages.count,
                    createdAt: convo.created_at
                )

                loadedConversations.append(conversation)
            }

            conversations = loadedConversations
            print("MessagingService: Loaded \(conversations.count) conversations")
            isLoading = false

        } catch {
            print("MessagingService: Failed to load conversations: \(error)")
            self.error = error
            isLoading = false
            // Use mock data as fallback
            conversations = generateMockConversations()
        }
    }

    // MARK: - Get or Create Conversation

    /// Get existing conversation with user or create a new one
    func getOrCreateConversation(with userId: UUID) async throws -> DirectConversation {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        // Check if conversation already exists
        if let existing = conversations.first(where: { $0.otherUserId == userId }) {
            return existing
        }

        // Try to find in database
        do {
            let existingConvos: [DatabaseDirectConversation] = try await supabase.query("direct_conversations")
                .select("*")
                .or("user1_id.eq.\(currentUser.id).and(user2_id.eq.\(userId)),user1_id.eq.\(userId).and(user2_id.eq.\(currentUser.id))")
                .execute()

            if let existing = existingConvos.first {
                // Load other user info
                let users: [DatabaseUserProfile] = try await supabase.query("club_users")
                    .select("*")
                    .eq("id", value: userId)
                    .execute()

                guard let otherUser = users.first else {
                    throw SupabaseManager.SupabaseError.userNotFound
                }

                let conversation = DirectConversation(
                    id: existing.id,
                    otherUserId: userId,
                    otherUserName: "\(otherUser.first_name) \(otherUser.last_name)",
                    otherUserUsername: otherUser.username,
                    otherUserPhotoURL: otherUser.profile_photo_url,
                    isVerified: otherUser.is_verified_athlete,
                    lastMessage: nil,
                    lastMessageAt: nil,
                    unreadCount: 0,
                    createdAt: existing.created_at
                )

                // Add to local cache
                if !conversations.contains(where: { $0.id == conversation.id }) {
                    conversations.insert(conversation, at: 0)
                }

                return conversation
            }
        } catch {
            print("MessagingService: Error checking existing conversation: \(error)")
        }

        // Create new conversation
        let insert = DatabaseDirectConversationInsert(
            user1_id: currentUser.id,
            user2_id: userId
        )

        let conversationId = try await supabase.insertReturningId(insert, into: "direct_conversations")

        // Load other user info
        let users: [DatabaseUserProfile] = try await supabase.query("club_users")
            .select("*")
            .eq("id", value: userId)
            .execute()

        guard let otherUser = users.first else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        let conversation = DirectConversation(
            id: conversationId,
            otherUserId: userId,
            otherUserName: "\(otherUser.first_name) \(otherUser.last_name)",
            otherUserUsername: otherUser.username,
            otherUserPhotoURL: otherUser.profile_photo_url,
            isVerified: otherUser.is_verified_athlete,
            lastMessage: nil,
            lastMessageAt: nil,
            unreadCount: 0,
            createdAt: Date()
        )

        // Add to local cache
        conversations.insert(conversation, at: 0)

        print("MessagingService: Created new conversation with \(otherUser.first_name)")
        return conversation
    }

    // MARK: - Load Messages

    /// Load messages for a conversation
    func loadMessages(conversationId: UUID, limit: Int = 50, before: Date? = nil) async throws -> [DirectMessage] {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        do {
            var query = supabase.query("direct_messages")
                .select("*")
                .eq("conversation_id", value: conversationId)
                .order("created_at", ascending: false)
                .limit(limit)

            if let before = before {
                query = query.lt("created_at", value: before)
            }

            let dbMessages: [DatabaseDirectMessage] = try await query.execute()

            let messages = dbMessages.map { msg in
                DirectMessage(
                    id: msg.id,
                    conversationId: msg.conversation_id,
                    senderId: msg.sender_id,
                    recipientId: msg.recipient_id,
                    content: msg.content,
                    createdAt: msg.created_at,
                    isRead: msg.is_read,
                    isFromCurrentUser: msg.sender_id == currentUser.id
                )
            }

            // Return in chronological order
            return messages.reversed()

        } catch {
            print("MessagingService: Failed to load messages: \(error)")
            return generateMockMessages(conversationId: conversationId)
        }
    }

    // MARK: - Send Message

    /// Send a direct message
    func sendMessage(conversationId: UUID, recipientId: UUID, content: String) async throws -> DirectMessage {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw SupabaseManager.SupabaseError.invalidData("Message cannot be empty")
        }

        let insert = DatabaseDirectMessageInsert(
            conversation_id: conversationId,
            sender_id: currentUser.id,
            recipient_id: recipientId,
            content: trimmedContent
        )

        try await supabase.insert(insert, into: "direct_messages")

        // Update conversation's updated_at
        try? await supabase.update(
            table: "direct_conversations",
            set: ["updated_at": Date()],
            where: "id = '\(conversationId)'"
        )

        // Update local conversation cache
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].lastMessage = trimmedContent
            conversations[index].lastMessageAt = Date()
            // Move to top
            let conversation = conversations.remove(at: index)
            conversations.insert(conversation, at: 0)
        }

        // Return the sent message
        return DirectMessage(
            id: UUID(),
            conversationId: conversationId,
            senderId: currentUser.id,
            recipientId: recipientId,
            content: trimmedContent,
            createdAt: Date(),
            isRead: false,
            isFromCurrentUser: true
        )
    }

    // MARK: - Mark as Read

    /// Mark messages in a conversation as read
    func markAsRead(conversationId: UUID) async {
        guard supabase.isAuthenticated else { return }
        guard let currentUser = supabase.currentUser else { return }

        do {
            try await supabase.update(
                table: "direct_messages",
                set: ["is_read": true],
                where: "conversation_id = '\(conversationId)' AND recipient_id = '\(currentUser.id)' AND is_read = false"
            )

            // Update local cache
            if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                conversations[index].unreadCount = 0
            }

            print("MessagingService: Marked messages as read")
        } catch {
            print("MessagingService: Failed to mark as read: \(error)")
        }
    }

    // MARK: - Total Unread Count

    /// Get total unread message count across all conversations
    var totalUnreadCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    // MARK: - Mock Data

    private func generateMockConversations() -> [DirectConversation] {
        return [
            DirectConversation(
                id: UUID(),
                otherUserId: UUID(),
                otherUserName: "Alex Johnson",
                otherUserUsername: "alexj",
                otherUserPhotoURL: "https://picsum.photos/100/100?random=301",
                isVerified: false,
                lastMessage: "See you at the game!",
                lastMessageAt: Date().addingTimeInterval(-1800),
                unreadCount: 2,
                createdAt: Date().addingTimeInterval(-86400)
            ),
            DirectConversation(
                id: UUID(),
                otherUserId: UUID(),
                otherUserName: "Sarah Chen",
                otherUserUsername: "sarahc",
                otherUserPhotoURL: "https://picsum.photos/100/100?random=302",
                isVerified: true,
                lastMessage: "Thanks for the invite!",
                lastMessageAt: Date().addingTimeInterval(-7200),
                unreadCount: 0,
                createdAt: Date().addingTimeInterval(-172800)
            ),
            DirectConversation(
                id: UUID(),
                otherUserId: UUID(),
                otherUserName: "Marcus Williams",
                otherUserUsername: "marcusw",
                otherUserPhotoURL: "https://picsum.photos/100/100?random=303",
                isVerified: false,
                lastMessage: "Great playing with you",
                lastMessageAt: Date().addingTimeInterval(-86400),
                unreadCount: 0,
                createdAt: Date().addingTimeInterval(-259200)
            )
        ]
    }

    private func generateMockMessages(conversationId: UUID) -> [DirectMessage] {
        let now = Date()
        let currentUserId = supabase.currentUser?.id ?? UUID()
        let otherUserId = UUID()

        return [
            DirectMessage(
                id: UUID(),
                conversationId: conversationId,
                senderId: otherUserId,
                recipientId: currentUserId,
                content: "Hey! Are you coming to the game tomorrow?",
                createdAt: now.addingTimeInterval(-7200),
                isRead: true,
                isFromCurrentUser: false
            ),
            DirectMessage(
                id: UUID(),
                conversationId: conversationId,
                senderId: currentUserId,
                recipientId: otherUserId,
                content: "Yes! I'll be there around 6pm",
                createdAt: now.addingTimeInterval(-3600),
                isRead: true,
                isFromCurrentUser: true
            ),
            DirectMessage(
                id: UUID(),
                conversationId: conversationId,
                senderId: otherUserId,
                recipientId: currentUserId,
                content: "Perfect! See you at the game!",
                createdAt: now.addingTimeInterval(-1800),
                isRead: true,
                isFromCurrentUser: false
            )
        ]
    }
}
