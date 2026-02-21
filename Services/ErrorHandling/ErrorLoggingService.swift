//
//  ErrorLoggingService.swift
//  Checkpoint
//
//  Service for logging critical errors to Supabase for monitoring and debugging
//

import Foundation
import UIKit
import Supabase

/// Service for logging critical app errors to Supabase database
@MainActor
class ErrorLoggingService {

    // MARK: - Singleton

    static let shared = ErrorLoggingService()

    // MARK: - Properties

    private let supabase = SupabaseClientManager.shared.client

    // MARK: - Public Methods

    /// Log an error to Supabase database
    /// - Parameters:
    ///   - userId: The user experiencing the error
    ///   - type: Category of error (e.g., "onboarding_completion_failed")
    ///   - message: Error message
    ///   - context: Additional context data (optional)
    ///   - stackTrace: Stack trace for debugging (optional)
    @MainActor
    func logError(
        userId: UUID,
        type: ErrorType,
        message: String,
        context: [String: Any]? = nil,
        stackTrace: String? = nil
    ) async {

        struct ErrorLog: Encodable {
            let user_id: String
            let error_type: String
            let error_message: String
            let error_context: [String: String]?
            let stack_trace: String?
            let app_version: String?
            let ios_version: String
            let device_model: String
        }

        // Convert context to string dictionary for JSONB
        let stringContext = context?.compactMapValues { value -> String? in
            if let stringValue = value as? String {
                return stringValue
            } else if let boolValue = value as? Bool {
                return boolValue ? "true" : "false"
            } else if let numberValue = value as? CustomStringConvertible {
                return numberValue.description
            }
            return nil
        }

        let log = ErrorLog(
            user_id: userId.uuidString,
            error_type: type.rawValue,
            error_message: message,
            error_context: stringContext,
            stack_trace: stackTrace,
            app_version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            ios_version: UIDevice.current.systemVersion,
            device_model: UIDevice.current.model
        )

        do {
            try await supabase.from("error_logs")
                .insert(log)
                .execute()

            print("✅ Error logged to Supabase: \(type.rawValue)")
        } catch {
            // Fail silently - don't want error logging to crash the app
            // But print to console for local debugging
            print("⚠️ Failed to log error to Supabase: \(error.localizedDescription)")
        }
    }

    /// Log an error with automatic stack trace capture
    /// - Parameters:
    ///   - userId: The user experiencing the error
    ///   - type: Category of error
    ///   - error: The Swift error object
    ///   - context: Additional context data (optional)
    @MainActor
    func logError(
        userId: UUID,
        type: ErrorType,
        error: Error,
        context: [String: Any]? = nil
    ) async {
        let stackTrace = Thread.callStackSymbols.joined(separator: "\n")
        await logError(
            userId: userId,
            type: type,
            message: error.localizedDescription,
            context: context,
            stackTrace: stackTrace
        )
    }
}

// MARK: - Error Types

extension ErrorLoggingService {

    /// Predefined error types for categorization
    enum ErrorType: String {
        // Onboarding errors
        case onboardingCompletionFailed = "onboarding_completion_failed"
        case onboardingDataSyncFailed = "onboarding_data_sync_failed"
        case profileCreationFailed = "profile_creation_failed"

        // Authentication errors
        case authSignInFailed = "auth_sign_in_failed"
        case authSignOutFailed = "auth_sign_out_failed"
        case authSessionRefreshFailed = "auth_session_refresh_failed"

        // Payment errors
        case paymentInitializationFailed = "payment_initialization_failed"
        case paymentPurchaseFailed = "payment_purchase_failed"
        case paymentRestoreFailed = "payment_restore_failed"

        // Analytics errors
        case analyticsCalculationFailed = "analytics_calculation_failed"
        case analyticsSyncFailed = "analytics_sync_failed"

        // Community errors
        case postCreationFailed = "post_creation_failed"
        case postFetchFailed = "post_fetch_failed"

        // App lifecycle errors
        case appLaunchFailed = "app_launch_failed"
        case appBackgroundFailed = "app_background_failed"

        // Protection errors
        case protectionEnableFailed = "protection_enable_failed"
        case protectionDisableFailed = "protection_disable_failed"
        case dnsSetupFailed = "dns_setup_failed"

        // Generic fallback
        case unknown = "unknown_error"
    }
}
