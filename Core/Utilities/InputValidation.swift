//
//  InputValidation.swift
//  Club Ralley
//
//  Input validation utilities for user inputs
//

import Foundation

/// Validation errors
enum ValidationError: LocalizedError {
    case empty(field: String)
    case tooShort(field: String, minLength: Int)
    case tooLong(field: String, maxLength: Int)
    case invalidFormat(field: String, reason: String)
    case invalidCharacters(field: String)
    case alreadyTaken(field: String)

    var errorDescription: String? {
        switch self {
        case .empty(let field):
            return "\(field) cannot be empty"
        case .tooShort(let field, let minLength):
            return "\(field) must be at least \(minLength) characters"
        case .tooLong(let field, let maxLength):
            return "\(field) must be \(maxLength) characters or less"
        case .invalidFormat(let field, let reason):
            return "\(field) is invalid: \(reason)"
        case .invalidCharacters(let field):
            return "\(field) contains invalid characters"
        case .alreadyTaken(let field):
            return "This \(field) is already taken"
        }
    }
}

/// Input validation utilities
struct InputValidation {

    // MARK: - Username Validation

    /// Validate username format
    /// - Parameter username: The username to validate
    /// - Returns: Array of validation errors (empty if valid)
    static func validateUsername(_ username: String) -> [ValidationError] {
        var errors: [ValidationError] = []
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            errors.append(.empty(field: "Username"))
            return errors
        }

        if trimmed.count < 3 {
            errors.append(.tooShort(field: "Username", minLength: 3))
        }

        if trimmed.count > 30 {
            errors.append(.tooLong(field: "Username", maxLength: 30))
        }

        // Only allow alphanumeric, underscores, and periods
        let allowedCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_.-"))
        if trimmed.unicodeScalars.contains(where: { !allowedCharacterSet.contains($0) }) {
            errors.append(.invalidCharacters(field: "Username"))
        }

        // Cannot start or end with period or underscore
        if trimmed.hasPrefix(".") || trimmed.hasPrefix("_") ||
           trimmed.hasSuffix(".") || trimmed.hasSuffix("_") {
            errors.append(.invalidFormat(field: "Username", reason: "cannot start or end with . or _"))
        }

        // Cannot have consecutive periods or underscores
        if trimmed.contains("..") || trimmed.contains("__") || trimmed.contains("._") || trimmed.contains("_.") {
            errors.append(.invalidFormat(field: "Username", reason: "cannot have consecutive special characters"))
        }

        return errors
    }

    // MARK: - Bio Validation

    /// Validate bio text
    /// - Parameter bio: The bio text to validate
    /// - Returns: Array of validation errors (empty if valid)
    static func validateBio(_ bio: String?) -> [ValidationError] {
        guard let bio = bio, !bio.isEmpty else {
            return [] // Bio is optional
        }

        var errors: [ValidationError] = []

        if bio.count > 500 {
            errors.append(.tooLong(field: "Bio", maxLength: 500))
        }

        return errors
    }

    // MARK: - Name Validation

    /// Validate first or last name
    /// - Parameters:
    ///   - name: The name to validate
    ///   - fieldName: "First name" or "Last name" for error messages
    /// - Returns: Array of validation errors
    static func validateName(_ name: String, fieldName: String = "Name") -> [ValidationError] {
        var errors: [ValidationError] = []
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            errors.append(.empty(field: fieldName))
            return errors
        }

        if trimmed.count < 1 {
            errors.append(.tooShort(field: fieldName, minLength: 1))
        }

        if trimmed.count > 50 {
            errors.append(.tooLong(field: fieldName, maxLength: 50))
        }

        // Names should only contain letters, spaces, hyphens, and apostrophes
        let allowedCharacterSet = CharacterSet.letters.union(CharacterSet(charactersIn: " '-"))
        if trimmed.unicodeScalars.contains(where: { !allowedCharacterSet.contains($0) }) {
            errors.append(.invalidCharacters(field: fieldName))
        }

        return errors
    }

    // MARK: - Email Validation

    /// Validate email format
    /// - Parameter email: The email to validate
    /// - Returns: Array of validation errors
    static func validateEmail(_ email: String) -> [ValidationError] {
        var errors: [ValidationError] = []
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            errors.append(.empty(field: "Email"))
            return errors
        }

        // Basic email regex
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        if trimmed.range(of: emailRegex, options: .regularExpression) == nil {
            errors.append(.invalidFormat(field: "Email", reason: "invalid email format"))
        }

        if trimmed.count > 254 {
            errors.append(.tooLong(field: "Email", maxLength: 254))
        }

        return errors
    }

    // MARK: - Ralley Validation

    /// Validate ralley title
    /// - Parameter title: The title to validate
    /// - Returns: Array of validation errors
    static func validateRalleyTitle(_ title: String) -> [ValidationError] {
        var errors: [ValidationError] = []
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            errors.append(.empty(field: "Title"))
            return errors
        }

        if trimmed.count < 3 {
            errors.append(.tooShort(field: "Title", minLength: 3))
        }

        if trimmed.count > 100 {
            errors.append(.tooLong(field: "Title", maxLength: 100))
        }

        return errors
    }

    /// Validate ralley description
    /// - Parameter description: The description to validate
    /// - Returns: Array of validation errors
    static func validateRalleyDescription(_ description: String?) -> [ValidationError] {
        guard let description = description, !description.isEmpty else {
            return [] // Description is optional
        }

        var errors: [ValidationError] = []

        if description.count > 2000 {
            errors.append(.tooLong(field: "Description", maxLength: 2000))
        }

        return errors
    }

    // MARK: - Post Validation

    /// Validate post content
    /// - Parameter content: The content to validate
    /// - Returns: Array of validation errors
    static func validatePostContent(_ content: String) -> [ValidationError] {
        var errors: [ValidationError] = []
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            errors.append(.empty(field: "Post"))
            return errors
        }

        if trimmed.count > 5000 {
            errors.append(.tooLong(field: "Post", maxLength: 5000))
        }

        return errors
    }

    // MARK: - Message Validation

    /// Validate message content
    /// - Parameter message: The message to validate
    /// - Returns: Array of validation errors
    static func validateMessage(_ message: String) -> [ValidationError] {
        var errors: [ValidationError] = []
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            errors.append(.empty(field: "Message"))
            return errors
        }

        if trimmed.count > 2000 {
            errors.append(.tooLong(field: "Message", maxLength: 2000))
        }

        return errors
    }

    // MARK: - Helper Methods

    /// Check if a string contains only valid characters for a given set
    static func containsOnlyCharacters(in characterSet: CharacterSet, string: String) -> Bool {
        return string.unicodeScalars.allSatisfy { characterSet.contains($0) }
    }

    /// Sanitize input by trimming whitespace and normalizing
    static func sanitize(_ input: String) -> String {
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Username Uniqueness Check

extension InputValidation {

    /// Check if username is available (not already taken)
    /// - Parameter username: The username to check
    /// - Returns: True if available, false if taken
    @MainActor
    static func isUsernameAvailable(_ username: String) async -> Bool {
        let supabase = SupabaseManager.shared

        do {
            let users: [UsernameCheck] = try await supabase.query("club_users")
                .select("id")
                .eq("username", value: username.lowercased())
                .execute()

            return users.isEmpty
        } catch {
            // If we can't check, assume it might be taken to be safe
            return false
        }
    }
}

/// Helper struct for username uniqueness check
private struct UsernameCheck: Codable {
    let id: UUID
}
