//
//  ContactsManager.swift
//  Club Ralley
//
//  Reads device contacts and matches them against club_users by email
//

import Foundation
import Contacts
import SwiftUI

@MainActor
class ContactsManager: ObservableObject {

    // MARK: - Published Properties

    @Published var contactSuggestions: [RosterUserData] = []

    // MARK: - Dependencies

    private let supabase = SupabaseManager.shared

    // MARK: - Fetch Contact Matches

    /// Fetches device contacts and finds matching club_users by email
    func fetchContactMatches() async {
        let store = CNContactStore()

        // Only proceed if contacts access is authorized
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else {
            print("ContactsManager: Contacts access not authorized")
            return
        }

        do {
            // Fetch all contact emails from device
            let keysToFetch: [CNKeyDescriptor] = [
                CNContactEmailAddressesKey as CNKeyDescriptor
            ]

            var contactEmails: Set<String> = []
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)

            try store.enumerateContacts(with: request) { contact, _ in
                for email in contact.emailAddresses {
                    contactEmails.insert((email.value as String).lowercased())
                }
            }

            guard !contactEmails.isEmpty else {
                print("ContactsManager: No contact emails found")
                return
            }

            // Query club_users where email matches contact emails
            let emailArray = Array(contactEmails)
            let dbUsers: [DatabaseUserProfile] = try await supabase.query("club_users")
                .select("*")
                .in("email", values: emailArray)
                .limit(20)
                .execute()

            // Get current user's followed users to filter them out
            let currentUserId = supabase.currentUser?.id
            var followedIds: Set<UUID> = []

            if let currentUser = supabase.currentUser {
                let friendships: [DatabaseFriendship] = try await supabase.query("friendships")
                    .select("*")
                    .eq("user_id", value: currentUser.id)
                    .execute()
                followedIds = Set(friendships.map { $0.friend_id })
            }

            // Filter out current user and already-followed users
            contactSuggestions = dbUsers
                .filter { $0.id != currentUserId && !followedIds.contains($0.id) }
                .map { dbUser in
                    RosterUserData(
                        id: dbUser.id,
                        name: "\(dbUser.first_name) \(dbUser.last_name)",
                        username: dbUser.username,
                        location: "\(dbUser.city ?? ""), \(dbUser.state ?? "")",
                        photoURL: dbUser.profile_photo_url ?? "https://picsum.photos/100/100?random=\(dbUser.id.hashValue % 1000)",
                        mutuals: dbUser.friends_count,
                        isFollowing: false,
                        isVerified: dbUser.is_verified_athlete
                    )
                }

            print("✅ ContactsManager: Found \(contactSuggestions.count) contact matches")

        } catch {
            print("❌ ContactsManager: Failed to fetch contact matches: \(error)")
        }
    }
}
