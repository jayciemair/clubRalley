//
//  PendingRequestsSheet.swift
//  Club Ralley
//
//  Sheet for captain to approve/reject join requests.
//

import SwiftUI

struct PendingRequestsSheet: View {
    let ralley: ClubRalley
    @Binding var requests: [PendingJoinRequest]
    @EnvironmentObject var ralleyManager: RalleyManager
    @Environment(\.dismiss) private var dismiss

    @State private var processingId: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if requests.isEmpty {
                    emptyState
                } else {
                    requestsList
                }
            }
            .navigationTitle("Join Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.clock")
                .font(.system(size: 56))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.5))

            Text("No Pending Requests")
                .font(.system(size: 20, weight: .semibold))

            Text("When someone requests to join your ralley, they'll appear here.")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#F5F5F5"))
    }

    // MARK: - Requests List

    private var requestsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(requests) { request in
                    RequestRow(
                        request: request,
                        isProcessing: processingId == request.id,
                        onApprove: { await approveRequest(request) },
                        onReject: { await rejectRequest(request) }
                    )
                }
            }
            .padding(16)
        }
        .background(Color(hex: "#F5F5F5"))
    }

    // MARK: - Actions

    private func approveRequest(_ request: PendingJoinRequest) async {
        processingId = request.id

        await ralleyManager.approveJoinRequest(request, chatId: ralley.chatId)

        // Remove from local list
        requests.removeAll { $0.id == request.id }
        processingId = nil
    }

    private func rejectRequest(_ request: PendingJoinRequest) async {
        processingId = request.id

        await ralleyManager.rejectJoinRequest(request)

        // Remove from local list
        requests.removeAll { $0.id == request.id }
        processingId = nil
    }
}

// MARK: - Request Row

private struct RequestRow: View {
    let request: PendingJoinRequest
    let isProcessing: Bool
    let onApprove: () async -> Void
    let onReject: () async -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // User photo
                AsyncImage(url: URL(string: request.userPhotoURL ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())

                // User info
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.userName)
                        .font(.system(size: 16, weight: .semibold))

                    Text("@\(request.userUsername)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    if request.mutualCount > 0 {
                        Text("\(request.mutualCount) mutual friends")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#2C4F40"))
                    }
                }

                Spacer()

                Text(request.timeAgo)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: { Task { await onReject() } }) {
                    Text("Decline")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                }
                .disabled(isProcessing)

                Button(action: { Task { await onApprove() } }) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Approve")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#2C4F40"))
                    .cornerRadius(10)
                }
                .disabled(isProcessing)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
