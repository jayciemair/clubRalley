//
//  RalleyCompletionSheet.swift
//  Club Ralley
//
//  Sheet shown when captain completes a ralley.
//  Allows preview of auto-generated post, tagging attendees, and visibility selection.
//

import SwiftUI

struct RalleyCompletionSheet: View {
    let ralley: ClubRalley
    @EnvironmentObject var ralleyManager: RalleyManager
    @Environment(\.dismiss) private var dismiss

    @State private var attendees: [RalleyAttendee] = []
    @State private var taggedUserIds: Set<UUID> = []
    @State private var selectedVisibility: PostVisibility = .everyone
    @State private var skipPost = false
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var postContent = ""
    @State private var showingRecap = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Post Preview
                    if !skipPost {
                        postPreviewSection
                    }

                    // Attendee List
                    if !skipPost && !attendees.isEmpty {
                        attendeesSection
                    }

                    // Visibility Picker
                    if !skipPost {
                        visibilitySection
                    }

                    // Skip Option
                    skipOptionSection

                    // Action Buttons
                    actionButtonsSection
                }
                .padding(20)
            }
            .background(Color(hex: "#F5F5F5"))
            .navigationTitle("Complete Ralley")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
            .task {
                await loadData()
            }
            .sheet(isPresented: $showingRecap) {
                RalleyRecapView(
                    ralley: ralley,
                    attendees: attendees
                )
                .environmentObject(ralleyManager)
                .onDisappear {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#2C4F40"))

            Text("Great session!")
                .font(.system(size: 24, weight: .bold))

            Text("Would you like to share this ralley with your followers?")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Post Preview Section

    private var postPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Post Preview")
                .font(.system(size: 16, weight: .semibold))

            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text("Completed: \(ralley.title)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#2C4F40"))

                // Content
                Text(postContent)
                    .font(.system(size: 15))
                    .foregroundColor(.black)

                // Tagged users preview
                if !taggedUserIds.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                        Text("\(taggedUserIds.count) attendees tagged")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Attendees Section

    private var attendeesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tag Attendees")
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                Button(action: toggleAllTags) {
                    Text(taggedUserIds.count == attendees.count ? "Untag All" : "Tag All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }

            ForEach(attendees) { attendee in
                AttendeeRow(
                    attendee: attendee,
                    isTagged: taggedUserIds.contains(attendee.id),
                    onToggle: { toggleTag(for: attendee.id) }
                )
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Visibility Section

    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Who can see this post?")
                .font(.system(size: 16, weight: .semibold))

            PostVisibilityPicker(
                selectedVisibility: $selectedVisibility,
                showDescription: false
            )
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Skip Option Section

    private var skipOptionSection: some View {
        Button(action: { skipPost.toggle() }) {
            HStack {
                Image(systemName: skipPost ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(skipPost ? Color(hex: "#2C4F40") : .gray)

                Text("Don't share a post")
                    .font(.system(size: 15))
                    .foregroundColor(.black)

                Spacer()
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Primary Action
            Button(action: { Task { await completeRalley() } }) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(skipPost ? "Complete Ralley" : "Share & Complete")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "#2C4F40"))
                .cornerRadius(12)
            }
            .disabled(isSubmitting)
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true

        // Load attendees
        if let participationManager = ralleyManager.participationManager {
            attendees = await participationManager.getAttendees(for: ralley.id)
            taggedUserIds = Set(attendees.map { $0.id })
        }

        // Generate post content
        postContent = generatePostContent()

        isLoading = false
    }

    private func generatePostContent() -> String {
        var content = "Just wrapped up an awesome \(ralley.sport.lowercased()) session at \(ralley.location.name)!"

        if attendees.count > 1 {
            let otherCount = attendees.count - 1
            if otherCount == 1 {
                content += " Great playing with 1 other athlete!"
            } else {
                content += " Great playing with \(otherCount) other athletes!"
            }
        }

        content += "\n\n#ClubRalley #\(ralley.sport.replacingOccurrences(of: " ", with: ""))"

        return content
    }

    // MARK: - Actions

    private func toggleTag(for userId: UUID) {
        if taggedUserIds.contains(userId) {
            taggedUserIds.remove(userId)
        } else {
            taggedUserIds.insert(userId)
        }
    }

    private func toggleAllTags() {
        if taggedUserIds.count == attendees.count {
            taggedUserIds.removeAll()
        } else {
            taggedUserIds = Set(attendees.map { $0.id })
        }
    }

    private func completeRalley() async {
        isSubmitting = true

        if let completionManager = ralleyManager.completionManager {
            if skipPost {
                await completionManager.skipAndComplete()
                isSubmitting = false
                dismiss()
            } else {
                // Set up the completion manager state
                completionManager.taggedUserIds = taggedUserIds
                completionManager.selectedVisibility = selectedVisibility
                completionManager.completingRalley = ralley
                completionManager.attendees = attendees

                // Complete and share
                await completionManager.completeAndShare()
                isSubmitting = false

                // Show the recap screen
                showingRecap = true
            }
        } else {
            isSubmitting = false
            dismiss()
        }
    }
}


// MARK: - Attendee Row

private struct AttendeeRow: View {
    let attendee: RalleyAttendee
    let isTagged: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: attendee.photoURL ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(attendee.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)

                    Text("@\(attendee.username)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: isTagged ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isTagged ? Color(hex: "#2C4F40") : Color.gray.opacity(0.3))
            }
            .padding(12)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
}
