//
//  SimulatorMessage.swift
//  goh
//
//  Model for text simulator messages
//

import Foundation

// MARK: - Simulator Message Model

enum MessageType: Equatable {
    case userMessage
    case hisResponse
    case systemEvent  // For all inline events (screenshot, left on read, etc.)
}

// MARK: - System Event Types

enum SystemEventType {
    case screenshot
    case leftOnRead(reason: String)
    case putPhoneDown(reason: String)
    case stoppedResponding(reason: String)
    case completeGhost  // He just stops - brutal silence

    var message: String {
        switch self {
        case .screenshot:
            return Self.screenshotReasons.randomElement()!
        case .leftOnRead(let reason):
            return "he left you on read because \(reason)"
        case .putPhoneDown(let reason):
            return "he put his phone down because \(reason)"
        case .stoppedResponding(let reason):
            return "he stopped responding because \(reason)"
        case .completeGhost:
            return Self.completeGhostReasons.randomElement()!
        }
    }

    // Random reasons for each event type
    static let screenshotReasons = [
        "he screenshotted your messages and sent it to his group chat...",
        "he screenshotted your messages and sent it to the girl he's talking to...",
    ]

    static let leftOnReadReasons = [
        "he's bored of this conversation",
        "he has to get ready for his date",
        "he got a text from a girl he likes",
        "he just doesn't care about you",
        "you're annoying him",
        "he literally wants to do anything but talk to you",
        "he doesn't like your tone",
    ]

    static let putPhoneDownReasons = [
        "he's texting someone he actually wants to talk to",
        "you're not worth his time right now",
        "he's getting ready to go out without you",
        "his friends are more interesting than you",
        "he's looking at another girl's instagram",
        "he's dming girls",
        "he's watching thirst traps",
        "literally anything else is more important",
    ]

    static let stoppedRespondingReasons = [
        "he's over this and he's over you",
        "you're exhausting him",
        "he realized he doesn't owe you anything",
        "he's with someone who actually makes him happy",
        "you were never that important to him",
        "he deleted your conversation",
        "he muted you",
        "he's telling his friends how annoying you are",
    ]

    static let completeGhostReasons = [
        "he started typing... then realized you're not worth it.",
        "he's done pretending to care.",
        "you pushed him too far.",
        "he blocked you in his head.",
        "he's laughing at your messages with his friends.",
        "he forgot you existed.",
    ]

    static func randomLeftOnRead() -> SystemEventType {
        .leftOnRead(reason: leftOnReadReasons.randomElement()!)
    }

    static func randomPutPhoneDown() -> SystemEventType {
        .putPhoneDown(reason: putPhoneDownReasons.randomElement()!)
    }

    static func randomStoppedResponding() -> SystemEventType {
        .stoppedResponding(reason: stoppedRespondingReasons.randomElement()!)
    }
}

struct SimulatorMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    var deliveryStatus: DeliveryStatus
    let messageType: MessageType

    init(content: String, isFromUser: Bool, timestamp: Date = Date(), deliveryStatus: DeliveryStatus = .delivered, messageType: MessageType? = nil) {
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.deliveryStatus = deliveryStatus
        // Auto-detect type if not provided
        self.messageType = messageType ?? (isFromUser ? .userMessage : .hisResponse)
    }

    // Convenience initializer for system events
    static func systemEvent(_ eventType: SystemEventType) -> SimulatorMessage {
        SimulatorMessage(
            content: eventType.message,
            isFromUser: false,
            deliveryStatus: .none,
            messageType: .systemEvent
        )
    }

    // Shorthand for screenshot
    static func screenshotAlert() -> SimulatorMessage {
        systemEvent(.screenshot)
    }

    static func == (lhs: SimulatorMessage, rhs: SimulatorMessage) -> Bool {
        lhs.id == rhs.id && lhs.deliveryStatus == rhs.deliveryStatus
    }
}

// MARK: - Delivery Status

enum DeliveryStatus: Equatable {
    case delivered
    case read(time: String)
    case none // For incoming messages

    var displayText: String {
        switch self {
        case .delivered:
            return "Delivered"
        case .read(let time):
            return "Read \(time)"
        case .none:
            return ""
        }
    }

    static func readNow() -> DeliveryStatus {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return .read(time: formatter.string(from: Date()))
    }
}

// MARK: - Simulator State

enum SimulatorState {
    case idle              // Waiting for user input
    case sending           // User sent message, showing delivered
    case reading           // He's reading (show Active now)
    case typing            // He's typing (show dots)
    case responded         // He sent a response
    case ghosting          // Past exchange limit, no more responses
    case screenshot        // Show screenshot alert (random trigger)
    case completeGhost     // Complete silence - messages just sit at Delivered forever
}

// MARK: - Contact Status

enum ContactStatus {
    case offline(lastActive: Date)
    case online
    case typing
    case currentlyDoing(activity: String)

    var displayText: String {
        switch self {
        case .offline(let lastActive):
            return formatLastActive(lastActive)
        case .online:
            return "active now"
        case .typing:
            return "active now"  // Don't show "typing" as status, just show active now
        case .currentlyDoing(let activity):
            return activity
        }
    }

    private func formatLastActive(_ date: Date) -> String {
        let now = Date()
        let seconds = Int(now.timeIntervalSince(date))

        if seconds < 60 {
            return "active now"
        }

        let minutes = seconds / 60
        if minutes < 60 {
            return "active \(minutes)m ago"
        }

        let hours = minutes / 60
        if hours < 24 {
            return "active \(hours)h ago"
        }

        let days = hours / 24
        return "active \(days)d ago"
    }
}
