//
//  CheckpointError.swift
//  Club Ralley
//
//  Unified error types for the app
//

import Foundation

/// Base protocol for all app errors
protocol CheckpointErrorProtocol: LocalizedError {
    var alertTitle: String { get }
    var userMessage: String { get }
    var recoverySuggestion: String? { get }
}

/// Main error enum
enum CheckpointError: CheckpointErrorProtocol {

    // MARK: - Core Data Errors
    case dataLoadFailed(Error)
    case dataSaveFailed(Error)
    case fetchRequestFailed(Error)

    // MARK: - Network Errors
    case networkUnavailable
    case apiRequestFailed(Error)

    // MARK: - General Errors
    case unknown(Error)
    case invalidInput(String)

    // MARK: - CheckpointErrorProtocol

    var alertTitle: String {
        switch self {
        case .dataLoadFailed, .dataSaveFailed, .fetchRequestFailed:
            return "Data Error"
        case .networkUnavailable, .apiRequestFailed:
            return "Network Error"
        case .unknown, .invalidInput:
            return "Error"
        }
    }

    var userMessage: String {
        switch self {
        case .dataLoadFailed:
            return "Unable to load your data. Please restart the app."
        case .dataSaveFailed:
            return "Unable to save your changes. Please try again."
        case .fetchRequestFailed:
            return "Failed to retrieve data. Please try again."
        case .networkUnavailable:
            return "No internet connection. Please check your network settings."
        case .apiRequestFailed:
            return "Unable to connect to server. Please try again later."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        case .invalidInput(let reason):
            return reason
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your Wi-Fi or cellular connection."
        case .dataLoadFailed, .dataSaveFailed:
            return "Force quit and restart the app."
        default:
            return nil
        }
    }

    // MARK: - LocalizedError

    var errorDescription: String? {
        return userMessage
    }

    var failureReason: String? {
        return alertTitle
    }

    var recoverySuggestionError: String? {
        return recoverySuggestion
    }
}
