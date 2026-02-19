//
//  ServiceContainer.swift
//  Club Ralley
//
//  Singleton holding one instance of each shared service.
//  Prevents duplicate service instantiation across ViewModels and Views.
//

import Foundation
import SwiftUI

@MainActor
class ServiceContainer: ObservableObject {

    // MARK: - Singleton

    static let shared = ServiceContainer()

    // MARK: - Shared Services

    let friendshipService: FriendshipService
    let sharedUserState: SharedUserState
    let ralleyService: RalleyService
    let postService: PostService
    let postEngagementService: PostEngagementService
    let chatService: ChatService
    let messagingService: MessagingService
    let ralleyParticipationService: RalleyParticipationService
    let ralleyCompletionService: RalleyCompletionService

    // MARK: - Initialization

    private init() {
        // Leaf services first (no custom deps)
        let friendship = FriendshipService()
        let engagement = PostEngagementService()
        let participation = RalleyParticipationService()
        let chat = ChatService()
        let messaging = MessagingService()

        // SharedUserState depends on FriendshipService
        let userState = SharedUserState(friendshipService: friendship)

        // Services that need injected deps
        let ralley = RalleyService(friendshipService: friendship, sharedUserState: userState)
        let post = PostService(friendshipService: friendship, sharedUserState: userState)
        let completion = RalleyCompletionService(participationService: participation)

        // Assign all
        self.friendshipService = friendship
        self.sharedUserState = userState
        self.ralleyService = ralley
        self.postService = post
        self.postEngagementService = engagement
        self.chatService = chat
        self.messagingService = messaging
        self.ralleyParticipationService = participation
        self.ralleyCompletionService = completion

        print("ServiceContainer: Initialized with shared service instances")
    }
}
