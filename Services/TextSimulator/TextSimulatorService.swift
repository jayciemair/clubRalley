//
//  TextSimulatorService.swift
//  goh
//
//  Service for Text Simulator - calls backend API for ex responses
//

import Foundation

class TextSimulatorService {

    // MARK: - Fallback Mock Data (used if API fails)

    private let fallbackResponses = [
        "k", "ok", "sure", "yeah", "idk", "maybe", "whatever", "busy rn",
        "what do you want", "i'm busy", "not now", "we've been over this",
        "i've moved on", "can we not", "seriously?"
    ]

    private let currentlyDoingActivities = [
        "at a bar with friends",
        "on a date",
        "at a party",
        "hanging with the boys",
        "out with someone",
        "busy, can't talk",
        "at the gym",
        "watching the game",
        "with friends rn",
        "out tonight",
    ]

    // MARK: - Public Methods

    /// Get an ex-boyfriend style response to the user's message
    func getExResponse(userMessage: String, conversationHistory: [(String, Bool)]) async throws -> String {
        print("🔵 [Ex] Starting request...")

        // Get auth token
        guard let token = try? await getAuthToken() else {
            print("🔴 [Ex] Failed to get auth token, using fallback")
            return fallbackResponses.randomElement() ?? "k"
        }
        print("🟢 [Ex] Got auth token")

        // Prepare URL
        let urlString = AppLinks.API.exChat
        print("🔵 [Ex] URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("🔴 [Ex] Invalid URL")
            return fallbackResponses.randomElement() ?? "k"
        }

        // Build conversation history
        var history: [[String: String]] = []
        for (content, isFromUser) in conversationHistory {
            history.append([
                "role": isFromUser ? "user" : "assistant",
                "content": content
            ])
        }

        // Create request payload
        struct ChatRequest: Encodable {
            let message: String
            let conversationHistory: [[String: String]]
        }

        let payload = ChatRequest(
            message: userMessage,
            conversationHistory: history
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
            print("🔵 [Ex] Request body: \(bodyString.prefix(200))...")
        }

        // Make request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("🔴 [Ex] Invalid response type")
                return fallbackResponses.randomElement() ?? "k"
            }

            print("🔵 [Ex] Status code: \(httpResponse.statusCode)")

            if let responseString = String(data: data, encoding: .utf8) {
                print("🔵 [Ex] Response body: \(responseString.prefix(500))")
            }

            if httpResponse.statusCode != 200 {
                print("🔴 [Ex] Non-200 status code")
                return fallbackResponses.randomElement() ?? "k"
            }

            // Parse response
            struct ChatResponse: Decodable {
                let response: String
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let chatResponse = try decoder.decode(ChatResponse.self, from: data)

            let trimmedResponse = chatResponse.response.trimmingCharacters(in: .whitespacesAndNewlines)
            print("🟢 [Ex] Success! Response: \(trimmedResponse)")

            return trimmedResponse
        } catch {
            print("🔴 [Ex] Error: \(error)")
            return fallbackResponses.randomElement() ?? "k"
        }
    }

    /// Get a "currently doing" activity for when he's ghosting
    func getCurrentlyDoingActivity() async throws -> String {
        return currentlyDoingActivities.randomElement() ?? "busy rn"
    }

    // MARK: - Private Methods

    private func getAuthToken() async throws -> String {
        let session = try await SupabaseClientManager.shared.client.auth.session
        return session.accessToken
    }
}

// MARK: - Error Types

enum TextSimulatorError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError
    case unauthorized
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError:
            return "Network error occurred"
        case .unauthorized:
            return "Not authorized"
        case .serverError(let message):
            return message
        }
    }
}
