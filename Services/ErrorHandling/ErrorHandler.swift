//
//  ErrorHandler.swift
//  Checkpoint
//
//  Centralized error handling and user feedback system
//

import Foundation
import SwiftUI

/// Centralized error handling system for the Checkpoint app
class ErrorHandler: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ErrorHandler()
    
    // MARK: - Types
    
    enum Severity {
        case info
        case warning
        case error
        case critical
        
        var icon: String {
            switch self {
            case .info: return "info.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            case .critical: return "exclamationmark.octagon"
            }
        }
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            case .critical: return .red
            }
        }
    }
    
    struct Alert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let severity: Severity
        let primaryAction: AlertAction?
        let secondaryAction: AlertAction?
        
        struct AlertAction {
            let title: String
            let action: () -> Void
        }
    }
    
    // MARK: - Properties
    
    @Published var currentAlert: Alert?
    @Published var isShowingAlert = false
    
    // Analytics/logging handler (can be set by the app)
    var analyticsHandler: ((Error, Severity, String?) -> Void)?
    
    // MARK: - Public Methods
    
    /// Handle an error with optional user-facing alert
    func handle(_ error: Error,
                message: String? = nil,
                severity: Severity = .error,
                showAlert: Bool = false,
                primaryAction: Alert.AlertAction? = nil,
                secondaryAction: Alert.AlertAction? = nil) {
        
        // Log to console
        let logMessage = message ?? error.localizedDescription

        // Send to analytics if configured
        analyticsHandler?(error, severity, message)
        
        // Show alert if requested and severity warrants it
        if showAlert || severity == .critical {
            let alertTitle = getAlertTitle(for: error, severity: severity)
            let alertMessage = getUserFriendlyMessage(for: error, customMessage: message)
            
            // Ensure UI updates happen on main thread
            DispatchQueue.main.async { [weak self] in
                self?.currentAlert = Alert(
                    title: alertTitle,
                    message: alertMessage,
                    severity: severity,
                    primaryAction: primaryAction ?? Alert.AlertAction(title: "OK", action: {}),
                    secondaryAction: secondaryAction
                )
                self?.isShowingAlert = true
            }
        }
    }
    
    /// Log a message without an error object
    func log(_ message: String, severity: Severity = .info) {
        analyticsHandler?(NSError(domain: "CheckpointLog", code: 0), severity, message)
    }
    
    // MARK: - Private Helpers
    
    private func getAlertTitle(for error: Error, severity: Severity) -> String {
        // Check if it's a CheckpointError with custom title
        if let checkpointError = error as? CheckpointError {
            return checkpointError.alertTitle
        }
        
        // Default titles based on severity
        switch severity {
        case .info: return "Information"
        case .warning: return "Warning"
        case .error: return "Error"
        case .critical: return "Critical Error"
        }
    }
    
    private func getUserFriendlyMessage(for error: Error, customMessage: String?) -> String {
        // Use custom message if provided
        if let customMessage = customMessage {
            return customMessage
        }

        // Check if it's a CheckpointError with user-friendly message
        if let checkpointError = error as? CheckpointError {
            return checkpointError.userMessage
        }
        
        // Handle specific system errors
        if let nsError = error as NSError? {
            switch nsError.domain {
            case "FamilyControls":
                return "Unable to manage app restrictions. Please check your Screen Time settings."
            case "CoreData":
                return "Unable to save data. Please try again or restart the app."
            case NSURLErrorDomain:
                return "Network connection error. Please check your internet connection."
            default:
                break
            }
        }
        
        // Default to localized description
        return error.localizedDescription
    }
}

// MARK: - SwiftUI View Modifier

extension View {
    /// Attach error handling alerts to any view
    func withErrorHandling() -> some View {
        self.modifier(ErrorHandlingModifier())
    }
}

struct ErrorHandlingModifier: ViewModifier {
    @ObservedObject private var errorHandler = ErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.currentAlert?.title ?? "Error",
                isPresented: $errorHandler.isShowingAlert,
                presenting: errorHandler.currentAlert
            ) { alert in
                if let primaryAction = alert.primaryAction {
                    Button(primaryAction.title) {
                        primaryAction.action()
                    }
                }
                
                if let secondaryAction = alert.secondaryAction {
                    Button(secondaryAction.title, role: .cancel) {
                        secondaryAction.action()
                    }
                }
            } message: { alert in
                Text(alert.message)
            }
    }
}