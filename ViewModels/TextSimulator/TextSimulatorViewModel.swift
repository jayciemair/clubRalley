//
//  TextSimulatorViewModel.swift
//  goh
//
//  ViewModel for the Text Him simulator feature
//

import Foundation
import SwiftUI

@MainActor
class TextSimulatorViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var messages: [SimulatorMessage] = []
    @Published var inputText: String = ""
    @Published var state: SimulatorState = .idle
    @Published var contactStatus: ContactStatus = .offline(lastActive: Date().addingTimeInterval(-Double.random(in: 3600...10800)))  // Random 1-3h ago
    @Published var isTyping: Bool = false
    @Published var showScreenshotFlash: Bool = false
    @Published var showDisclaimer: Bool = true
    @Published var isInputDisabled: Bool = false
    @Published var showReflection: Bool = false

    // MARK: - Private Properties

    private let service = TextSimulatorService()
    private var exchangeCount: Int = 0
    private let maxExchanges: Int = Int.random(in: 6...10)
    private var lastActivityTime: Date = Date()
    private var isCompleteGhost: Bool = false  // Complete silence mode
    private var isGhosting: Bool = false  // Regular ghosting mode (after max exchanges)
    private let completeGhostChance: Double = 0.05  // 5% chance per message after threshold
    private let completeGhostThreshold: Int = 4  // Start checking after this many exchanges

    // MARK: - Initialization

    init() {
        // Check if disclaimer has been shown before
        showDisclaimer = !UserDefaults.standard.bool(forKey: "hasSeenTextSimulatorDisclaimer")
    }

    // MARK: - Public Methods

    func dismissDisclaimer() {
        UserDefaults.standard.set(true, forKey: "hasSeenTextSimulatorDisclaimer")
        showDisclaimer = false
    }

    func sendMessage() async {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        // Clear input immediately
        let messageText = trimmedText
        inputText = ""

        print("[TextSim] 📤 Sending message: \(messageText)")

        // Create and add user message (starts as delivered)
        let userMessage = SimulatorMessage(
            content: messageText,
            isFromUser: true,
            deliveryStatus: .delivered
        )
        messages.append(userMessage)

        // Update state
        state = .sending
        print("[TextSim] State -> sending")

        // Haptic feedback
        HapticUtility.impact(style: .light)

        // Check if we're in complete ghost mode - messages just sit at Delivered forever
        if isCompleteGhost {
            print("[TextSim] 💀 Complete ghost mode - message stays at Delivered")
            state = .completeGhost
            // Message stays at .delivered, no read receipt, no response, nothing
            return
        }

        // Check if we're already in ghosting mode - just silence, no more events
        if isGhosting {
            print("[TextSim] 👻 Already ghosting - message stays at Delivered, no events")
            state = .ghosting
            // Message stays at .delivered, no read receipt, no response, no events
            return
        }

        // Check if we should enter ghosting mode
        if exchangeCount >= maxExchanges {
            print("[TextSim] 👻 Entering ghosting mode (exchange \(exchangeCount) >= max \(maxExchanges))")
            await handleGhosting()
            return
        }

        // Simulate reading delay (1-3 seconds)
        print("[TextSim] ⏳ Waiting for him to read...")
        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...3_000_000_000))

        // HE READS IT - update to read with timestamp
        print("[TextSim] 👀 He's reading it now...")
        print("[TextSim] 🔍 Looking for message with id: \(userMessage.id)")
        print("[TextSim] 🔍 Messages count: \(messages.count)")
        for (i, msg) in messages.enumerated() {
            print("[TextSim] 🔍 Message[\(i)]: id=\(msg.id), content=\(msg.content), status=\(msg.deliveryStatus.displayText)")
        }

        if let index = messages.firstIndex(where: { $0.id == userMessage.id }) {
            print("[TextSim] 🔍 Found at index \(index), BEFORE status: \(messages[index].deliveryStatus.displayText)")
            let newStatus = DeliveryStatus.readNow()
            print("[TextSim] 🔍 New status will be: \(newStatus.displayText)")
            messages[index].deliveryStatus = newStatus
            print("[TextSim] 🔍 AFTER status: \(messages[index].deliveryStatus.displayText)")
            print("[TextSim] ✅ Message marked as READ with timestamp: \(messages[index].deliveryStatus.displayText)")

            // Force UI update by triggering objectWillChange
            objectWillChange.send()
        } else {
            print("[TextSim] ❌ ERROR: Could not find message to mark as read!")
        }
        contactStatus = .online
        state = .reading
        print("[TextSim] Status -> online (green), State -> reading")

        // Random chance of screenshot AFTER he reads it (15% chance)
        let shouldScreenshot = Double.random(in: 0...1) < 0.15
        print("[TextSim] Screenshot roll: \(shouldScreenshot ? "YES" : "no")")
        if shouldScreenshot {
            await triggerScreenshot()
        }

        // Random chance to not respond (20%)
        let shouldIgnore = Double.random(in: 0...1) < 0.2
        if shouldIgnore {
            print("[TextSim] 🙄 He's ignoring (20% chance hit)")
            try? await Task.sleep(nanoseconds: 3_000_000_000)

            // Add a "left on read" event
            let event = SimulatorMessage.systemEvent(.randomLeftOnRead())
            messages.append(event)
            print("[TextSim] 📝 Added event: \(event.content)")

            contactStatus = .offline(lastActive: Date().addingTimeInterval(-60))
            state = .idle
            print("[TextSim] Status -> offline (1m ago), State -> idle")
            return
        }

        // Show typing indicator
        print("[TextSim] ⌨️ Showing typing indicator...")
        try? await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...1_500_000_000))
        isTyping = true
        contactStatus = .typing
        state = .typing
        print("[TextSim] isTyping = true, Status -> typing, State -> typing")

        // Get AI response
        print("[TextSim] 🤖 Calling AI service...")
        do {
            // Filter out system events - only send actual conversation messages to AI
            let conversationOnly = messages.filter { $0.messageType != .systemEvent }
            let response = try await service.getExResponse(
                userMessage: messageText,
                conversationHistory: conversationOnly.map { ($0.content, $0.isFromUser) }
            )
            print("[TextSim] ✅ AI response received: \(response)")

            // Typing duration based on response length
            let typingDuration = min(Double(response.count) * 0.05, 3.0)
            print("[TextSim] ⌨️ Typing for \(typingDuration)s...")
            try? await Task.sleep(nanoseconds: UInt64(typingDuration * 1_000_000_000))

            isTyping = false
            print("[TextSim] isTyping = false")

            // Add response
            let responseMessage = SimulatorMessage(
                content: response,
                isFromUser: false,
                deliveryStatus: .none
            )
            messages.append(responseMessage)
            HapticUtility.impact(style: .medium)

            exchangeCount += 1
            contactStatus = .online
            state = .responded
            print("[TextSim] Exchange count: \(exchangeCount), Status -> online, State -> responded")

            // Check for complete ghost trigger (5% chance per message after threshold)
            if exchangeCount >= completeGhostThreshold {
                let shouldCompleteGhost = Double.random(in: 0...1) < completeGhostChance
                print("[TextSim] 💀 Complete ghost roll: \(shouldCompleteGhost ? "TRIGGERED" : "no") (exchange \(exchangeCount), threshold \(completeGhostThreshold))")
                if shouldCompleteGhost {
                    await triggerCompleteGhost()
                    return
                }
            }

            // Go offline after a bit
            let offlineDelay = Double.random(in: 2...5)
            print("[TextSim] ⏳ Going offline in \(offlineDelay)s...")
            try? await Task.sleep(nanoseconds: UInt64(offlineDelay * 1_000_000_000))

            // 15% chance he "puts phone down" instead of just going offline
            if Double.random(in: 0...1) < 0.15 {
                let event = SimulatorMessage.systemEvent(.randomPutPhoneDown())
                messages.append(event)
                print("[TextSim] 📝 Added event: \(event.content)")
            }

            contactStatus = .offline(lastActive: Date().addingTimeInterval(-60))  // 1 min ago
            state = .idle
            print("[TextSim] Status -> offline (1m ago), State -> idle")

        } catch {
            print("[TextSim] ❌ AI service error: \(error)")
            isTyping = false
            contactStatus = .offline(lastActive: Date().addingTimeInterval(-120))  // 2 min ago on error
            state = .idle
            print("[TextSim] isTyping = false, Status -> offline (2m ago), State -> idle")
        }
    }

    func resetConversation() {
        // Show reflection if we had a real conversation (at least 1 exchange)
        if exchangeCount > 0 || state == .ghosting || state == .completeGhost {
            showReflection = true
            return
        }
        performReset()
    }

    func performReset() {
        messages = []
        exchangeCount = 0
        state = .idle
        isTyping = false
        isInputDisabled = false
        isCompleteGhost = false
        isGhosting = false
        showScreenshotFlash = false
        showReflection = false
        contactStatus = .offline(lastActive: Date().addingTimeInterval(-Double.random(in: 3600...10800)))  // Random 1-3h ago
    }

    // MARK: - Private Methods

    private func handleGhosting() async {
        print("[TextSim] 👻 Entering ghosting mode...")
        isGhosting = true  // Set flag so future messages are silently ignored
        state = .ghosting
        isInputDisabled = false // They can still send, just gets left on read

        // Wait a bit before showing the ghosting event
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // Add a "stopped responding" event - this is the ONE and ONLY event
        let event = SimulatorMessage.systemEvent(.randomStoppedResponding())
        messages.append(event)
        print("[TextSim] 📝 Added ghosting event: \(event.content)")

        // Just go offline - no activity, no screenshot (he's not reading anymore)
        contactStatus = .offline(lastActive: Date())
    }

    private func triggerCompleteGhost() async {
        print("[TextSim] 💀 Triggering complete ghost...")

        // Brief delay before he "starts typing"
        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_000_000_000))

        // Show typing indicator - he's about to respond...
        isTyping = true
        contactStatus = .typing
        print("[TextSim] 💀 He started typing...")

        // Type for 1-2 seconds... then stop
        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_000_000_000))

        // He stopped typing - gave up
        isTyping = false
        print("[TextSim] 💀 He stopped typing...")

        // Brief pause
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Add the subtle "..." message
        let event = SimulatorMessage.systemEvent(.completeGhost)
        messages.append(event)
        print("[TextSim] 💀 Added '...' event")

        // Enter complete ghost state
        isCompleteGhost = true
        state = .completeGhost
        contactStatus = .offline(lastActive: Date())
        print("[TextSim] 💀 Complete ghost mode ACTIVE - all future messages will be ignored")
    }

    private func triggerScreenshot() async {
        print("[TextSim] 📸 Screenshot triggered!")

        // Heavy haptic
        HapticUtility.notification(type: .warning)

        // Flash on
        showScreenshotFlash = true

        // Flash off after 0.1s
        try? await Task.sleep(nanoseconds: 100_000_000)
        showScreenshotFlash = false

        // Insert screenshot alert as a message after 0.3s
        try? await Task.sleep(nanoseconds: 300_000_000)
        withAnimation(.easeOut(duration: 0.3)) {
            messages.append(SimulatorMessage.screenshotAlert())
        }
        print("[TextSim] 📸 Screenshot alert added to messages")
    }
}
