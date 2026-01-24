//
//  ForceUpdateView.swift
//  Checkpoint
//
//  Full-screen modal that blocks app usage until user updates
//

import SwiftUI

struct ForceUpdateView: View {

    let latestVersion: String
    let onUpdateTapped: () -> Void

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // App icon or logo
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                // Title
                Text("Update Required")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                // Description
                VStack(spacing: 12) {
                    Text("A new version of Checkpoint is required to continue.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)

                    Text("Please update to version \(latestVersion)")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Update button
                Button(action: onUpdateTapped) {
                    Text("Update Now")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            .padding(32)
        }
    }
}

// MARK: - Preview

#Preview {
    ForceUpdateView(latestVersion: "1.2.3") {
        // Update tapped
    }
}
