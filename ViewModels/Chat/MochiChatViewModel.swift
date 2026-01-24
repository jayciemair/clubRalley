//
//  MochiChatViewModel.swift
//  Checkpoint
//
//  View model for Mochi AI counselor chat
//

import Foundation
import SwiftUI

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp: Date
}

// MARK: - View Model

@MainActor
class MochiChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false

    init() {
        // Welcome message from AI
        addMochiMessage("Hi, I'm Mochi. I'm here to support you through your recovery. What's on your mind?")
    }

    // MARK: - Public Methods

    func sendMessage(_ text: String) async {
        // Add user message
        let userMessage = ChatMessage(text: text, isFromUser: true, timestamp: Date())
        messages.append(userMessage)

        // Show typing indicator
        isTyping = true

        // Get AI response
        do {
            let response = try await getAIResponse(userMessage: text)
            isTyping = false
            addMochiMessage(response)
        } catch {
            print("🔴 [Mochi] Error: \(error)")
            isTyping = false
            addMochiMessage("I'm having trouble connecting right now. But I'm here for you - try again in a moment.")
        }
    }

    // MARK: - Private Methods

    private func addMochiMessage(_ text: String) {
        let message = ChatMessage(text: text, isFromUser: false, timestamp: Date())
        messages.append(message)
    }

    private func getAIResponse(userMessage: String) async throws -> String {
        print("🔵 [Mochi] Starting request...")

        // Get auth token
        guard let token = try? await getAuthToken() else {
            print("🔴 [Mochi] Failed to get auth token")
            throw ChatError.unauthorized
        }
        print("🟢 [Mochi] Got auth token: \(token.prefix(20))...")

        // Prepare URL
        let urlString = AppLinks.API.mochiChat
        print("🔵 [Mochi] URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("🔴 [Mochi] Invalid URL")
            throw ChatError.invalidURL
        }

        // Build conversation history (last 10 messages for context)
        var conversationHistory: [[String: String]] = []
        for message in messages.suffix(10) {
            conversationHistory.append([
                "role": message.isFromUser ? "user" : "assistant",
                "content": message.text
            ])
        }

        // Create request payload
        struct ChatRequest: Encodable {
            let message: String
            let conversationHistory: [[String: String]]
        }

        let payload = ChatRequest(
            message: userMessage,
            conversationHistory: conversationHistory
        )

        // Create HTTP request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(payload)

        if let bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
            print("🔵 [Mochi] Request body: \(bodyString.prefix(200))...")
        }

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("🔴 [Mochi] Invalid response type")
            throw ChatError.invalidResponse
        }

        print("🔵 [Mochi] Status code: \(httpResponse.statusCode)")

        if let responseString = String(data: data, encoding: .utf8) {
            print("🔵 [Mochi] Response body: \(responseString.prefix(500))")
        }

        if httpResponse.statusCode != 200 {
            print("🔴 [Mochi] Non-200 status code: \(httpResponse.statusCode)")
            throw ChatError.networkError
        }

        // Parse response
        struct ChatResponse: Decodable {
            let response: String
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let chatResponse = try decoder.decode(ChatResponse.self, from: data)

        // Trim whitespace and newlines from AI response
        let trimmedResponse = chatResponse.response.trimmingCharacters(in: .whitespacesAndNewlines)

        print("🟢 [Mochi] Success! Response: \(trimmedResponse.prefix(100))...")

        return trimmedResponse
    }

    private func getAuthToken() async throws -> String {
        let session = try await SupabaseClientManager.shared.client.auth.session
        return session.accessToken
    }
}

// MARK: - Errors

enum ChatError: Error {
    case invalidURL
    case invalidResponse
    case networkError
    case unauthorized
}
