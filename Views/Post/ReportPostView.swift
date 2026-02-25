//
//  ReportPostView.swift
//  Club Ralley
//
//  View for reporting inappropriate posts
//

import SwiftUI

struct ReportPostView: View {
    let postId: UUID
    @EnvironmentObject var postManager: PostManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedReason: ReportReason?
    @State private var otherReasonText = ""
    @State private var isSubmitting = false
    @State private var showingSuccessAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header explanation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why are you reporting this post?")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)

                    Text("Your report is anonymous. We'll review this post and take action if it violates our community guidelines.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)

                Divider()

                // Report reasons list
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(ReportReason.allCases, id: \.self) { reason in
                            ReportReasonRow(
                                reason: reason,
                                isSelected: selectedReason == reason,
                                onSelect: {
                                    selectedReason = reason
                                }
                            )
                        }
                    }

                    // Other reason text field
                    if selectedReason == .other {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Please describe the issue")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            TextEditor(text: $otherReasonText)
                                .frame(minHeight: 100)
                                .padding(12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding(20)
                    }
                }

                // Submit button
                VStack(spacing: 0) {
                    Divider()

                    Button(action: submitReport) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Submit Report")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        selectedReason != nil && !isSubmitting
                            ? Color(hex: "#2C4F40")
                            : Color.gray.opacity(0.3)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(selectedReason == nil || isSubmitting || (selectedReason == .other && otherReasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                    .padding(20)
                }
            }
            .navigationTitle("Report Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
            .alert("Report Submitted", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for helping keep Club Ralley safe. We'll review this post and take appropriate action.")
            }
        }
    }

    private func submitReport() {
        guard let reason = selectedReason else { return }

        isSubmitting = true

        let reasonText = reason == .other
            ? otherReasonText.trimmingCharacters(in: .whitespacesAndNewlines)
            : reason.rawValue

        Task {
            await postManager.reportPost(postId, reason: reasonText)
            isSubmitting = false
            showingSuccessAlert = true
        }
    }
}

// MARK: - Report Reason

enum ReportReason: String, CaseIterable {
    case spam = "Spam"
    case harassment = "Harassment or bullying"
    case inappropriateContent = "Inappropriate content"
    case hateSpeech = "Hate speech"
    case violence = "Violence or dangerous behavior"
    case falseInformation = "False information"
    case other = "Other"

    var description: String {
        switch self {
        case .spam:
            return "Irrelevant or promotional content"
        case .harassment:
            return "Content that targets or demeans someone"
        case .inappropriateContent:
            return "Content not suitable for all audiences"
        case .hateSpeech:
            return "Content promoting hate or discrimination"
        case .violence:
            return "Content promoting harm or dangerous activities"
        case .falseInformation:
            return "Misleading or false claims"
        case .other:
            return "Something else not listed here"
        }
    }
}

// MARK: - Report Reason Row

struct ReportReasonRow: View {
    let reason: ReportReason
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reason.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)

                    Text(reason.description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? Color(hex: "#2C4F40") : .gray.opacity(0.4))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(isSelected ? Color(hex: "#2C4F40").opacity(0.05) : Color.clear)
        }

        Divider()
            .padding(.leading, 20)
    }
}
