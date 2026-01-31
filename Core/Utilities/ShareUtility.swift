//
//  ShareUtility.swift
//  Club Ralley
//
//  Utility for sharing content via iOS share sheet
//

import SwiftUI
import UIKit

struct ShareUtility {

    /// Share a post via iOS share sheet
    /// - Parameter post: The post to share
    static func sharePost(_ post: ClubRalleyPost) {
        var shareContent = ""

        if let title = post.title, !title.isEmpty {
            shareContent += "\(title)\n\n"
        }

        shareContent += post.content
        shareContent += "\n\nShared from Club Ralley"

        presentShareSheet(items: [shareContent])
    }

    /// Share text content via iOS share sheet
    /// - Parameter text: The text to share
    static func shareText(_ text: String) {
        presentShareSheet(items: [text])
    }

    /// Share a URL via iOS share sheet
    /// - Parameter url: The URL to share
    static func shareURL(_ url: URL) {
        presentShareSheet(items: [url])
    }

    /// Present the iOS share sheet with the given items
    /// - Parameter items: Items to share (strings, URLs, images, etc.)
    private static func presentShareSheet(items: [Any]) {
        let activityViewController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        // Exclude certain activity types if needed
        activityViewController.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .openInIBooks
        ]

        // Get the root view controller and present
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                // Find the topmost presented controller
                var topController = rootViewController
                while let presentedController = topController.presentedViewController {
                    topController = presentedController
                }

                // For iPad, configure the popover
                if let popover = activityViewController.popoverPresentationController {
                    popover.sourceView = topController.view
                    popover.sourceRect = CGRect(
                        x: topController.view.bounds.midX,
                        y: topController.view.bounds.midY,
                        width: 0,
                        height: 0
                    )
                    popover.permittedArrowDirections = []
                }

                topController.present(activityViewController, animated: true)
            }
        }
    }
}
