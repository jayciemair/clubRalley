//
//  NavigationModels.swift
//  Club Ralley
//
//  Navigation models and routing for Club Ralley app
//

import Foundation

// MARK: - Navigation Routes

enum NavigationRoute: Hashable {
    // Profile routes
    case userProfile(userId: UUID)
    case editProfile
    case settings
    case friendsList
    
    // Ralley routes
    case ralleyDetail(ralleyId: UUID)
    case createRalley
    case editRalley(ralleyId: UUID)
    case ralleyParticipants(ralleyId: UUID)
    
    // Social routes
    case socialFeed
    case postDetail(postId: UUID)
    case friendRequests
    case userSearch
    
    // Discovery routes
    case discoverUsers
    case discoverRalleys
    case mapView
    
    // Onboarding routes
    case welcomeScreen
    case profileSetup
    case athleteVerification
    case sportsSelection
    case availabilitySetup
    
    var id: String {
        switch self {
        case .userProfile(let userId):
            return "userProfile_\(userId.uuidString)"
        case .editProfile:
            return "editProfile"
        case .settings:
            return "settings"
        case .friendsList:
            return "friendsList"
        case .ralleyDetail(let ralleyId):
            return "ralleyDetail_\(ralleyId.uuidString)"
        case .createRalley:
            return "createRalley"
        case .editRalley(let ralleyId):
            return "editRalley_\(ralleyId.uuidString)"
        case .ralleyParticipants(let ralleyId):
            return "ralleyParticipants_\(ralleyId.uuidString)"
        case .socialFeed:
            return "socialFeed"
        case .postDetail(let postId):
            return "postDetail_\(postId.uuidString)"
        case .friendRequests:
            return "friendRequests"
        case .userSearch:
            return "userSearch"
        case .discoverUsers:
            return "discoverUsers"
        case .discoverRalleys:
            return "discoverRalleys"
        case .mapView:
            return "mapView"
        case .welcomeScreen:
            return "welcomeScreen"
        case .profileSetup:
            return "profileSetup"
        case .athleteVerification:
            return "athleteVerification"
        case .sportsSelection:
            return "sportsSelection"
        case .availabilitySetup:
            return "availabilitySetup"
        }
    }
}

// MARK: - Tab Selection

struct TabSelection {
    var selectedTab: MainTab
    var homeNavigation: [NavigationRoute] = []
    var findRalleysNavigation: [NavigationRoute] = []
    var teamsNavigation: [NavigationRoute] = []
    var profileNavigation: [NavigationRoute] = []
    
    mutating func navigate(to route: NavigationRoute, in tab: MainTab) {
        switch tab {
        case .home:
            homeNavigation.append(route)
        case .findRalleys:
            findRalleysNavigation.append(route)
        case .post:
            break // Post is modal, no navigation stack
        case .teams:
            teamsNavigation.append(route)
        case .profile:
            profileNavigation.append(route)
        }
    }
    
    mutating func popToRoot(in tab: MainTab) {
        switch tab {
        case .home:
            homeNavigation.removeAll()
        case .findRalleys:
            findRalleysNavigation.removeAll()
        case .post:
            break // Post is modal
        case .teams:
            teamsNavigation.removeAll()
        case .profile:
            profileNavigation.removeAll()
        }
    }
    
    mutating func pop(in tab: MainTab) {
        switch tab {
        case .home:
            if !homeNavigation.isEmpty {
                homeNavigation.removeLast()
            }
        case .findRalleys:
            if !findRalleysNavigation.isEmpty {
                findRalleysNavigation.removeLast()
            }
        case .post:
            break // Post is modal
        case .teams:
            if !teamsNavigation.isEmpty {
                teamsNavigation.removeLast()
            }
        case .profile:
            if !profileNavigation.isEmpty {
                profileNavigation.removeLast()
            }
        }
    }
}

// MARK: - Deep Link Handling

struct DeepLink {
    enum DeepLinkType {
        case ralley(id: UUID)
        case userProfile(id: UUID)
        case invitation(ralleyId: UUID)
        case friendRequest(fromUserId: UUID)
        
        var route: NavigationRoute {
            switch self {
            case .ralley(let id):
                return .ralleyDetail(ralleyId: id)
            case .userProfile(let id):
                return .userProfile(userId: id)
            case .invitation(let ralleyId):
                return .ralleyDetail(ralleyId: ralleyId)
            case .friendRequest:
                return .friendRequests
            }
        }
        
        var targetTab: MainTab {
            switch self {
            case .ralley, .invitation:
                return .teams
            case .userProfile, .friendRequest:
                return .profile
            }
        }
    }
    
    let type: DeepLinkType
    let url: URL
    
    init?(url: URL) {
        self.url = url
        
        guard url.scheme == "clubralley" else { return nil }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        guard !pathComponents.isEmpty else { return nil }
        
        switch pathComponents[0] {
        case "ralley":
            guard pathComponents.count > 1,
                  let ralleyId = UUID(uuidString: pathComponents[1]) else { return nil }
            self.type = .ralley(id: ralleyId)
            
        case "user":
            guard pathComponents.count > 1,
                  let userId = UUID(uuidString: pathComponents[1]) else { return nil }
            self.type = .userProfile(id: userId)
            
        case "invitation":
            guard pathComponents.count > 1,
                  let ralleyId = UUID(uuidString: pathComponents[1]) else { return nil }
            self.type = .invitation(ralleyId: ralleyId)
            
        case "friend-request":
            guard let queryItems = components?.queryItems,
                  let userIdString = queryItems.first(where: { $0.name == "from" })?.value,
                  let fromUserId = UUID(uuidString: userIdString) else { return nil }
            self.type = .friendRequest(fromUserId: fromUserId)
            
        default:
            return nil
        }
    }
}

// MARK: - Navigation Actions

enum NavigationAction {
    case showOnboarding(flow: OnboardingFlowType)
    case completeOnboarding
    case switchTab(MainTab)
    case navigate(NavigationRoute, in: MainTab)
    case popToRoot(MainTab)
    case pop(MainTab)
    case handleDeepLink(DeepLink)
    case showCreateRalley
    case dismissModal
}

// MARK: - Modal Presentations

enum ModalPresentation: Identifiable {
    case createRalley
    case editProfile
    case settings
    case ralleyParticipants(ralleyId: UUID)
    case userSearch
    case friendRequests
    case mapView
    
    var id: String {
        switch self {
        case .createRalley:
            return "createRalley"
        case .editProfile:
            return "editProfile"
        case .settings:
            return "settings"
        case .ralleyParticipants(let ralleyId):
            return "ralleyParticipants_\(ralleyId.uuidString)"
        case .userSearch:
            return "userSearch"
        case .friendRequests:
            return "friendRequests"
        case .mapView:
            return "mapView"
        }
    }
}