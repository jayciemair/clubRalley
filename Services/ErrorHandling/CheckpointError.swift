//
//  CheckpointError.swift
//  Checkpoint
//
//  Unified error types for the Checkpoint app
//

import Foundation

/// Base protocol for all Checkpoint errors
protocol CheckpointErrorProtocol: LocalizedError {
    var alertTitle: String { get }
    var userMessage: String { get }
    var recoverySuggestion: String? { get }
}

/// Main error enum for Checkpoint app
enum CheckpointError: CheckpointErrorProtocol {
    
    // MARK: - ScreenTime/FamilyControls Errors
    case screenTimeNotAuthorized
    case screenTimeAuthorizationFailed(Error)
    case appBlockingFailed(Error)
    case restrictionApplicationFailed
    case tokenSerializationFailed
    
    // MARK: - App Group Errors
    case appGroupNotFound(String)
    case appGroupCreationFailed(Error)
    case appGroupDeletionFailed(Error)
    case appGroupSaveFailed(Error)
    case appGroupLoadFailed(Error)
    case appGroupMigrationFailed
    
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
        case .screenTimeNotAuthorized, .screenTimeAuthorizationFailed:
            return "Screen Time Permission Required"
        case .appBlockingFailed, .restrictionApplicationFailed, .tokenSerializationFailed:
            return "App Blocking Error"
        case .appGroupNotFound, .appGroupCreationFailed, .appGroupDeletionFailed,
             .appGroupSaveFailed, .appGroupLoadFailed, .appGroupMigrationFailed:
            return "App Group Error"
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
        case .screenTimeNotAuthorized:
            return "Checkpoint needs Screen Time permissions to protect your recovery. Please enable it in Settings."
        case .screenTimeAuthorizationFailed:
            return "Failed to authorize Screen Time. Please try again or check your settings."
        case .appBlockingFailed:
            return "Unable to apply app restrictions. Please try again."
        case .restrictionApplicationFailed:
            return "Failed to update app restrictions. Your selection may not have been saved."
        case .tokenSerializationFailed:
            return "Unable to save your app selections. Please try selecting apps again."
            
        case .appGroupNotFound(let name):
            return "The app group '\\(name)' could not be found."
        case .appGroupCreationFailed:
            return "Failed to create the app group. Please try again."
        case .appGroupDeletionFailed:
            return "Failed to delete the app group. Please try again."
        case .appGroupSaveFailed:
            return "Unable to save app groups. Your changes may not persist."
        case .appGroupLoadFailed:
            return "Unable to load your app groups. Please restart the app."
        case .appGroupMigrationFailed:
            return "Failed to migrate to app groups. Your previous selections are still active."
            
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
        case .screenTimeNotAuthorized, .screenTimeAuthorizationFailed:
            return "Go to Settings > Screen Time > Checkpoint and enable permissions."
        case .appBlockingFailed, .restrictionApplicationFailed:
            return "Try disabling and re-enabling app blocking."
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

