
//
//  NotificationService.swift
//  Checkpoint
//
//  Centralized notification management for the app
//

import Foundation
import UserNotifications
import CoreData

// Note: RestrictionBlock is in Shared/Models/CoreData and Weekday is in Shared/Models

final class NotificationService {
    static let shared = NotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - Public Methods

    // Legacy session notification functions removed (dead code for old DialIn system)
    // Removed: scheduleDialInStart, scheduleDialInEnd, scheduleDialInReminder
    // Removed: cancelAllDialInNotifications
    // Removed: All RestrictionBlock notification functions

    /// Cancel specific notification type
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Send an immediate notification (no scheduling, fires right away)
    /// Used by DeviceActivityMonitor extension
    func sendImmediateNotification(content: UNMutableNotificationContent, identifier: String) {
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // nil trigger means immediate delivery
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
            }
        }
    }
    
    /// Request notification permissions if needed
    func requestPermissionIfNeeded(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    DispatchQueue.main.async {
                        completion(granted)
                    }
                }
            case .authorized, .provisional:
                DispatchQueue.main.async {
                    completion(true)
                }
            default:
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }

    // MARK: - Engagement Notifications


    // MARK: - Private Methods
    
    private func scheduleNotification(
        content: UNMutableNotificationContent,
        trigger: UNNotificationTrigger,
        identifier: String
    ) {
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
            }
        }
    }
}

// MARK: - Notification Identifiers

enum NotificationIdentifier {
    // Legacy session identifiers removed (dead code)
}