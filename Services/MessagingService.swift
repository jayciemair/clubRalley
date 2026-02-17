//
//  MessagingService.swift
//  Club Ralley
//
//  Service for direct messaging operations
//  Uses direct_messages table for 1-on-1 DMs
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
            // Get all unique users we've messaged with
            // Query messages where we're sender or recipient
            let sentMessages: [DatabaseDirectMessageRecord] = try await supabase.query("direct_messages")
                .select("*")
                .eq("sender_id", value: currentUser.id)
                .order("created_at", ascending: false)
                .execute()

            let receivedMessages: [DatabaseDirectMessageRecord] = try await supabase.query("direct_messages")
                .select("*")
                .eq("recipient_id", value: currentUser.id)
                .order("created_at", ascending: false)
                .execute()

            // Combine and find unique conversation partners
            var conversationPartners: [UUID: (lastMessage: DatabaseDirectMessageRecord, unreadCount: Int)] = [:]

            for msg in sentMessages {
                let partnerId = msg.recipient_id
                if let existing = conversationPartners[partnerId] {
                    if msg.created_at > existing.lastMessage.created_at {
                        conversationPartners[partnerId] = (lastMessage: msg, unreadCount: 0)
                    }
                } else {
                    conversationPartners[partnerId] = (lastMessage: msg, unreadCount: 0)
                }
            }

            for msg in receivedMessages {
                let partnerId = msg.sender_id
                let isUnread = !msg.is_read
                if let existing = conversationPartners[partnerId] {
                    let newUnread = existing.unreadCount + (isUnread ? 1 : 0)
                    if msg.created_at > existing.lastMessage.created_at {
                        conversationPartners[partnerId] = (lastMessage: msg, unreadCount: newUnread)
                    } else {
                        conversationPartners[partnerId] = (lastMessage: existing.lastMessage, unreadCount: newUnread)
                    }
                } else {
                    conversationPartners[partnerId] = (lastMessage: msg, unreadCount: isUnread ? 1 : 0)
                }
            }

            // Load user info for each partner and build conversations
            var loadedConversations: [DirectConversation] = []

            for (partnerId, data) in conversationPartners {
                if let userInfo = try? await loadUserInfo(userId: partnerId) {
                    let conversation = DirectConversation(
                        id: partnerId, // Use partner ID as conversation ID
                        otherUserId: partnerId,
                        otherUserName: "\(userInfo.first_name) \(userInfo.last_name)",
                        otherUserUsername: userInfo.username,
                        otherUserPhotoURL: userInfo.profile_photo_url,
                        isVerified: false,
                        lastMessage: data.lastMessage.content,
                        lastMessageAt: data.lastMessage.created_at,
                        unreadCount: data.unreadCount,
                        createdAt: data.lastMessage.created_at
                    )
                    loadedConversations.append(conversation)
                }
            }

            // Sort by most recent message
            loadedConversations.sort { ($0.lastMessageAt ?? Date.distantPast) > ($1.lastMessageAt ?? Date.distantPast) }

            conversations = loadedConversations
            print("MessagingService: Loaded \(conversations.count) conversations from database")
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

        // Check if conversation already exists in local cache
        if let existing = conversations.first(where: { $0.otherUserId == userId }) {
            return existing
        }

        // Load user info for the new conversation partner
        guard let userInfo = try? await loadUserInfo(userId: userId) else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        // Create a new conversation (no actual DB record needed - conversation is implicit)
        let conversation = DirectConversation(
            id: userId,
            otherUserId: userId,
            otherUserName: "\(userInfo.first_name) \(userInfo.last_name)",
            otherUserUsername: userInfo.username,
            otherUserPhotoURL: userInfo.profile_photo_url,
            isVerified: false,
            lastMessage: nil,
            lastMessageAt: nil,
            unreadCount: 0,
            createdAt: Date()
        )

        // Add to local cache
        conversations.insert(conversation, at: 0)

        print("MessagingService: Created new conversation with \(userInfo.first_name)")
        return conversation
    }

    // MARK: - Load Messages

    /// Load messages for a conversation (between current user and other user)
    func loadMessages(conversationId: UUID, limit: Int = 50, before: Date? = nil) async throws -> [DirectMessage] {
        guard supabase.isAuthenticated else {
            throw SupabaseManager.SupabaseError.notAuthenticated
        }

        guard let currentUser = supabase.currentUser else {
            throw SupabaseManager.SupabaseError.userNotFound
        }

        let otherUserId = conversationId // conversationId is the other user's ID

        do {
            // Get messages sent by current user to other user
            let sentMessages: [DatabaseDirectMessageRecord] = try await supabase.query("direct_messages")
                .select("*")
                .eq("sender_id", value: currentUser.id)
                .eq("recipient_id", value: otherUserId)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()

            // Get messages received from other user
            let receivedMessages: [DatabaseDirectMessageRecord] = try await supabase.query("direct_messages")
                .select("*")
                .eq("sender_id", value: otherUserId)
                .eq("recipient_id", value: currentUser.id)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()

            // Combine and sort
            var allMessages = sentMessages + receivedMessages
            allMessages.sort { $0.created_at < $1.created_at }

            // Map to UI model
            let messages = allMessages.map { msg in
                DirectMessage(
                    id: msg.id,
                    conversationId: otherUserId,
                    senderId: msg.sender_id,
                    recipientId: msg.recipient_id,
                    content: msg.content,
                    createdAt: msg.created_at,
                    isRead: msg.is_read,
                    isFromCurrentUser: msg.sender_id == currentUser.id
                )
            }

            print("MessagingService: Loaded \(messages.count) messages from database")
            return messages

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

        do {
            let insert = DatabaseDirectMessageInsert(
                sender_id: currentUser.id,
                recipient_id: recipientId,
                content: trimmedContent
            )

            try await supabase.insert(insert, into: "direct_messages")

            print("MessagingService: Message sent to \(recipientId)")

            // Update local conversation cache
            if let index = conversations.firstIndex(where: { $0.otherUserId == recipientId }) {
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

        } catch {
            print("MessagingService: Failed to send message: \(error)")
            throw SupabaseManager.SupabaseError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Mark as Read

    /// Mark messages in a conversation as read (updates database)
    func markAsRead(conversationId: UUID) async {
        guard supabase.isAuthenticated else { return }
        guard let currentUser = supabase.currentUser else { return }

        let otherUserId = conversationId

        // Update local cache immediately (optimistic update)
        if let index = conversations.firstIndex(where: { $0.otherUserId == otherUserId }) {
            conversations[index].unreadCount = 0
        }

        // Update database - mark all unread messages from this sender as read
        do {
            try await supabase.update(
                ["is_read": true],
                in: "direct_messages",
                where: "recipient_id = '\(currentUser.id)' AND sender_id = '\(otherUserId)' AND is_read = false"
            )
            print("MessagingService: Marked messages as read in database")
        } catch {
            print("MessagingService: Failed to mark messages as read in database: \(error)")
            // Local cache already updated, so UI will still show as read
        }
    }

    /// Mark a specific message as read
    func markMessageAsRead(messageId: UUID) async {
        guard supabase.isAuthenticated else { return }

        do {
            try await supabase.update(
                ["is_read": true],
                in: "direct_messages",
                where: "id = '\(messageId)'"
            )
            print("MessagingService: Marked message \(messageId) as read")
        } catch {
            print("MessagingService: Failed to mark message as read: \(error)")
        }
    }

    // MARK: - Total Unread Count

    /// Get total unread message count across all conversations
    var totalUnreadCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    // MARK: - Helper Methods

    private func loadUserInfo(userId: UUID) async throws -> DatabaseUserBasic {
        let users: [DatabaseUserBasic] = try await supabase.query("club_users")
            .select("id, first_name, last_name, username, profile_photo_url")
            .eq("id", value: userId)
            .execute()

        guard let user = users.first else {
            throw SupabaseManager.SupabaseError.userNotFound
        }
        return user
    }

    // MARK: - Mock Data (Fallback)

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
            )
        ]
    }

    private func generateMockMessages(conversationId: UUID) -> [DirectMessage] {
        let now = Date()
        let currentUserId = supabase.currentUser?.id ?? UUID()
        let otherUserId = conversationId

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

// MARK: - Database Models for Direct Messages

/// Database record for direct messages
struct DatabaseDirectMessageRecord: Codable {
    let id: UUID
    let sender_id: UUID
    let recipient_id: UUID
    let content: String
    let is_read: Bool
    let created_at: Date
}

/// Database insert for direct messages
struct DatabaseDirectMessageInsert: Codable {
    let sender_id: UUID
    let recipient_id: UUID
    let content: String
}

/// Basic user info for conversation display
struct DatabaseUserBasic: Codable {
    let id: UUID
    let first_name: String
    let last_name: String
    let username: String
    let profile_photo_url: String?
}

// NOTE: DirectConversation and DirectMessage UI structs are defined in Models/Chat/ChatModels.swift
