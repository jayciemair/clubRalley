//
//  ChatServiceMembers.swift
//  Club Ralley
//
//  Member management extension for ChatService.
//  Extracted from ChatService.swift for file size management.
//

import Foundation

// MARK: - Member Management

extension ChatService {

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
     * Update last read timestamp in the database
     * Uses compound WHERE (ralley_id + user_id) via Supabase client directly
     * @param chatId: ID of the ralley
     */
    func markAsRead(chatId: UUID) async throws {
        await syncMarkAsReadToDatabase(chatId: chatId)
    }

    /// Write last_read_at to ralley_participants in Supabase
    func syncMarkAsReadToDatabase(chatId: UUID) async {
        guard let userId = supabase.currentUser?.id,
              let client = supabase.client else {
            return
        }

        do {
            let now = ISO8601DateFormatter().string(from: Date())
            try await client.client.from("ralley_participants")
                .update(["last_read_at": now])
                .eq("ralley_id", value: chatId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()

            print("ChatService: Synced last_read_at to DB for chat \(chatId)")
        } catch {
            print("ChatService: Failed to sync last_read_at: \(error)")
        }
    }

    /// Fetch last_read_at from ralley_participants and populate local cache
    func syncLastReadFromDatabase() async {
        guard supabase.isAuthenticated,
              let userId = supabase.currentUser?.id else {
            return
        }

        do {
            let participants: [DatabaseRalleyParticipantRecord] = try await supabase.query("ralley_participants")
                .select("*")
                .eq("user_id", value: userId)
                .execute()

            var dbTimestamps: [UUID: Date] = [:]
            for participant in participants {
                if let lastRead = participant.last_read_at {
                    dbTimestamps[participant.ralley_id] = lastRead
                }
            }

            // Merge: use whichever is more recent (local cache or DB)
            for (chatId, dbDate) in dbTimestamps {
                if let localDate = lastReadTimestamps[chatId] {
                    lastReadTimestamps[chatId] = max(localDate, dbDate)
                } else {
                    lastReadTimestamps[chatId] = dbDate
                }
            }
            saveLastReadTimestamps()

            print("ChatService: Synced \(dbTimestamps.count) last_read_at from database")
        } catch {
            print("ChatService: Failed to sync last_read_at from DB: \(error)")
        }
    }
}
