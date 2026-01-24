//
//  RecoveryComponents.swift
//  Checkpoint
//
//  Reusable components for recovery module screens
//

import SwiftUI

// MARK: - Back Button

struct RecoveryBackButton: View {
    let action: () -> Void

    var body: some View {
        HStack {
            Button(action: action) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
}

// MARK: - Header

struct RecoveryHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.custom("Satoshi-Bold", size: 28))
                .foregroundColor(.black)

            Text(subtitle)
                .font(.custom("Satoshi-Regular", size: 16))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Universal Card Component

struct RecoveryCard: View {
    let emoji: String?
    let title: String
    let description: String
    let practiceAction: (() -> Void)?
    let backgroundColor: Color?

    init(emoji: String? = nil, title: String, description: String, practiceAction: (() -> Void)? = nil, backgroundColor: Color? = nil) {
        self.emoji = emoji
        self.title = title
        self.description = description
        self.practiceAction = practiceAction
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 20) {
                if let emoji = emoji {
                    Text(emoji)
                        .font(.system(size: 52))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.custom("Satoshi-Bold", size: 20))
                        .foregroundColor(.black)

                    Text(description)
                        .font(.custom("Satoshi-Regular", size: 16))
                        .foregroundColor(.gray)
                        .lineSpacing(6)
                }
            }

            // Practice button (if provided)
            if let practiceAction = practiceAction {
                Button(action: practiceAction) {
                    Text("Practice")
                        .font(.custom("Satoshi-Bold", size: 14))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(backgroundColor ?? Color(red: 0.96, green: 0.96, blue: 0.97))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
}

// MARK: - Done Button

struct RecoveryDoneButton: View {
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button(action: {
            onComplete()
            dismiss()
        }) {
            Text("Done")
                .font(.custom("Satoshi-Bold", size: 16))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}

// MARK: - Previews

#Preview("Recovery Card with Emoji") {
    RecoveryCard(
        emoji: "🏃",
        title: "High-Intensity Exercise",
        description: "Sprint intervals, boxing, heavy lifting. Gets your heart racing. Releases the same endorphins you're craving."
    )
}

#Preview("Recovery Card without Emoji") {
    RecoveryCard(
        title: "Box Breathing (4-4-4-4)",
        description: """
        1. Breathe in for 4 seconds
        2. Hold for 4 seconds
        3. Breathe out for 4 seconds
        4. Hold for 4 seconds

        Repeat 4 times. Slows your heart rate, calms anxiety.
        """
    )
}

#Preview("Recovery Components") {
    ScrollView {
        VStack(spacing: 24) {
            RecoveryBackButton(action: {})

            RecoveryHeader(
                title: "Practice Calming Techniques",
                subtitle: "Use these when urges hit"
            )

            RecoveryCard(
                emoji: "🏃",
                title: "High-Intensity Exercise",
                description: "Sprint intervals, boxing, heavy lifting."
            )

            RecoveryCard(
                title: "Box Breathing",
                description: "Breathe in for 4 seconds, hold for 4 seconds."
            )

            RecoveryDoneButton(onComplete: {})
        }
    }
    .background(Color.white)
}
