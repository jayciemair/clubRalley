//
//  RalleyRecapView.swift
//  Club Ralley
//
//  Post-ralley recap screen. Presented after a ralley ends so participants
//  can share a recap (photo + text) to the home feed.
//

import SwiftUI
import PhotosUI

struct RalleyRecapView: View {
    let ralley: ClubRalley
    let attendees: [RalleyAttendee]
    @EnvironmentObject var ralleyManager: RalleyManager
    @Environment(\.dismiss) private var dismiss

    // Form State
    @State private var recapText = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var isSubmitting = false
    @State private var showingSuccess = false

    /// Pre-filled recap content
    private var prefilledContent: String {
        let otherCount = max(0, attendees.count - 1)
        let duration = ralley.durationMinutes >= 60
            ? "\(ralley.durationMinutes / 60)h"
            : "\(ralley.durationMinutes)min"

        if otherCount > 0 {
            return "\(ralley.organizer.name) and \(otherCount) others played \(ralley.sport) for \(duration) at \(ralley.location.name)"
        } else {
            return "Played \(ralley.sport) for \(duration) at \(ralley.location.name)"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    recapPreviewSection
                    photoSection
                    howWasItSection
                    postButton
                }
                .padding(20)
            }
            .background(Color(hex: "#F5F5F5"))
            .navigationTitle("Ralley Recap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Skip") { dismiss() }
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
        .overlay(successOverlay)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "#2C4F40"))

            Text("Great game!")
                .font(.system(size: 24, weight: .bold))

            Text("Share a recap with your followers")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Recap Preview Section

    private var recapPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recap")
                .font(.system(size: 16, weight: .semibold))

            // Pre-filled info card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: SportIconMapper.iconName(for: ralley.sport))
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#2C4F40"))
                    Text(ralley.sport)
                        .font(.system(size: 15, weight: .semibold))
                }

                HStack(spacing: 8) {
                    Image(systemName: "mappin")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text(ralley.location.name)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text("\(ralley.durationMinutes) minutes")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                HStack(spacing: 8) {
                    Image(systemName: "person.2")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text("\(attendees.count) players")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#2C4F40").opacity(0.05))
            .cornerRadius(12)

            Text(prefilledContent)
                .font(.system(size: 14))
                .foregroundColor(Color.black.opacity(0.6))
                .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a Photo")
                .font(.system(size: 16, weight: .semibold))

            if let image = selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)

                    Button(action: { selectedImage = nil; selectedPhotoItem = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    .padding(8)
                }
            } else {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "#2C4F40"))
                        Text("Tap to add a photo")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6]))
                    )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - How Was It Section

    private var howWasItSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("How was it?")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("Optional")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }

            TextField("Tell your friends about the game...", text: $recapText, axis: .vertical)
                .font(.system(size: 15))
                .padding(12)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
                .lineLimit(3...6)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Post Button

    private var postButton: some View {
        Button(action: { Task { await postRecap() } }) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(isSubmitting ? "Posting..." : "Post Recap")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(hex: "#2C4F40"))
            .cornerRadius(12)
            .shadow(color: Color(hex: "#2C4F40").opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isSubmitting)
        .padding(.top, 8)
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        Group {
            if showingSuccess {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        Text("Recap posted!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#2C4F40"))
                    .cornerRadius(25)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSuccess)
            }
        }
    }

    // MARK: - Actions

    private func postRecap() async {
        isSubmitting = true

        // Build the post content
        var content = prefilledContent
        if !recapText.isEmpty {
            content += "\n\n\(recapText)"
        }
        content += "\n\n#ClubRalley #\(ralley.sport.replacingOccurrences(of: " ", with: ""))"

        // Upload photo if provided
        var imageUrls: [String] = []
        if let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            do {
                let uploadService = ImageUploadService()
                let url = try await uploadService.uploadPostImage(imageData: imageData, postId: UUID())
                imageUrls.append(url)
            } catch {
                print("RalleyRecapView: Failed to upload image: \(error)")
            }
        }

        // Create the completion post via the completion manager
        if let completionManager = ralleyManager.completionManager {
            completionManager.completingRalley = ralley
            completionManager.attendees = attendees
            completionManager.taggedUserIds = Set(attendees.map { $0.id })
            await completionManager.completeAndShare()
        }

        isSubmitting = false
        showingSuccess = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showingSuccess = false
            dismiss()
        }
    }
}
