//
//  EmptyStateView.swift
//  Club Ralley
//
//  Reusable empty state UI component for when no data exists
//

import SwiftUI

/// A reusable empty state view for displaying when no content is available
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))

            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)

            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#2C4F40"))
                        .cornerRadius(12)
                }
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    /// Empty state for when no posts are available
    static func noPosts(onCreate: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "doc.text",
            title: "No Posts Yet",
            message: "Start sharing your athletic journey with the community!",
            actionTitle: onCreate != nil ? "Create Post" : nil,
            action: onCreate
        )
    }

    /// Empty state for when no ralleys are available
    static func noRalleys(onCreate: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "sportscourt",
            title: "No Ralleys Nearby",
            message: "Be the first to create a pickup game in your area!",
            actionTitle: onCreate != nil ? "Create Ralley" : nil,
            action: onCreate
        )
    }

    /// Empty state for when no users are found
    static var noUsers: EmptyStateView {
        EmptyStateView(
            icon: "person.2",
            title: "No Users Found",
            message: "Try adjusting your search or check back later."
        )
    }

    /// Empty state for when a profile has no content
    static var emptyProfile: EmptyStateView {
        EmptyStateView(
            icon: "person.crop.circle",
            title: "No Activity Yet",
            message: "This user hasn't posted or joined any ralleys yet."
        )
    }

    /// Empty state for network/loading errors
    static func error(onRetry: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.exclamationmark",
            title: "Unable to Load",
            message: "Check your internet connection and try again.",
            actionTitle: "Try Again",
            action: onRetry
        )
    }

    /// Empty state for search with no results
    static func noSearchResults(query: String) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "No matches found for \"\(query)\". Try a different search term."
        )
    }

    /// Empty state for when filters return no results
    static func noFilterResults(onClearFilters: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "line.3.horizontal.decrease.circle",
            title: "No Matching Results",
            message: "Try adjusting your filters to see more content.",
            actionTitle: "Clear Filters",
            action: onClearFilters
        )
    }
}

// MARK: - Preview

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            EmptyStateView.noRalleys(onCreate: {})
            EmptyStateView.noPosts()
        }
    }
}
