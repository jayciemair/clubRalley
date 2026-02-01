//
//  PostVisibility.swift
//  Club Ralley
//
//  Visibility settings for posts - controls who can see a post
//

import Foundation

// MARK: - Post Visibility

/**
 * Defines who can see a post in the feed
 */
enum PostVisibility: String, Codable, CaseIterable {
    /// Visible to everyone on Club Ralley
    case everyone = "everyone"

    /// Only visible to friends (mutual followers)
    case friends = "friends"

    /// Only visible to mutual friends (2nd degree connections)
    case mutualFriends = "mutual_friends"

    /// Only visible to the author (private)
    case privatePost = "private"

    var displayName: String {
        switch self {
        case .everyone: return "Everyone"
        case .friends: return "Friends"
        case .mutualFriends: return "Mutual Friends"
        case .privatePost: return "Only Me"
        }
    }

    var description: String {
        switch self {
        case .everyone: return "Anyone on Club Ralley can see this post"
        case .friends: return "Only your friends can see this post"
        case .mutualFriends: return "Friends and mutual friends can see this post"
        case .privatePost: return "Only you can see this post"
        }
    }

    var iconName: String {
        switch self {
        case .everyone: return "globe"
        case .friends: return "person.2.fill"
        case .mutualFriends: return "person.3.fill"
        case .privatePost: return "lock.fill"
        }
    }
}
