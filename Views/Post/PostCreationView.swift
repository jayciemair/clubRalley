//
//  PostCreationView.swift
//  Club Ralley
//
//  Interface for creating new posts with photos and titles.
//

import SwiftUI

// MARK: - Post Creation Interface

struct PostCreationInterfaceView: View {
    @EnvironmentObject var postManager: PostManager
    @State private var postText = ""
    @State private var showingPhotosPicker = false
    @State private var showingCamera = false
    @State private var showingTitleOption = false
    @State private var postTitle = ""
    @State private var selectedImages: [String] = []
    @State private var isPosting = false
    @State private var showingSuccessMessage = false
    @State private var showingDiscardAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    // Close Button
                    Button(action: {
                        handleClose()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 30, height: 30)
                    }

                    Spacer()

                    // Post Button
                    Button(action: {
                        createPost()
                    }) {
                        HStack(spacing: 6) {
                            if isPosting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isPosting ? "Posting..." : "Post")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(canPost ? .white : .gray)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            canPost
                                ? Color(hex: "#2C4F40")
                                : Color.gray.opacity(0.3)
                        )
                        .cornerRadius(20)
                    }
                    .disabled(!canPost || isPosting)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Main Content Area
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile and Text Input
                        HStack(alignment: .top, spacing: 12) {
                            // Profile Photo
                            AsyncImage(url: URL(string: "https://picsum.photos/44/44?random=1")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color(hex: "#2C4F40"))
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())

                            // Text Input Area
                            VStack(alignment: .leading, spacing: 12) {
                                // Title Input (conditional)
                                if showingTitleOption {
                                    TextField("Add a Title", text: $postTitle)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.black)
                                        .padding(.vertical, 4)
                                }

                                // Main Text Input
                                VStack(alignment: .leading, spacing: 8) {
                                    TextField("What's happening?", text: $postText, axis: .vertical)
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundColor(.black)
                                        .lineLimit(15, reservesSpace: false)

                                    // Character counter (if text is not empty)
                                    if !postText.isEmpty {
                                        HStack {
                                            Spacer()
                                            Text("\(postText.count)/280")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(postText.count > 280 ? .red : (postText.count > 250 ? .orange : .gray))
                                        }
                                    }
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // Selected Images Preview
                        if !selectedImages.isEmpty {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: selectedImages.count > 1 ? 2 : 1), spacing: 8) {
                                ForEach(selectedImages.indices, id: \.self) { index in
                                    ZStack {
                                        AsyncImage(url: URL(string: "https://picsum.photos/200/200?random=\(index + 500)")) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                        }
                                        .frame(height: selectedImages.count == 1 ? 250 : 180)
                                        .clipped()
                                        .cornerRadius(12)

                                        // Remove Button
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Button(action: {
                                                    selectedImages.remove(at: index)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(.white)
                                                        .background(Color.black.opacity(0.6))
                                                        .clipShape(Circle())
                                                }
                                                .padding(8)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        Spacer(minLength: 120)
                    }
                }

                // Bottom Toolbar
                VStack(spacing: 0) {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2))

                    HStack(spacing: 24) {
                        // Photo Gallery Button
                        Button(action: {
                            addPhoto()
                        }) {
                            ZStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(hex: "#2C4F40"))

                                // Photo count badge
                                if selectedImages.count > 0 {
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Text("\(selectedImages.count)")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(width: 18, height: 18)
                                                .background(Color(hex: "#2C4F40"))
                                                .clipShape(Circle())
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }

                        // Camera Button
                        Button(action: {
                            addCameraPhoto()
                        }) {
                            Image(systemName: "camera")
                                .font(.system(size: 22))
                                .foregroundColor(Color(hex: "#2C4F40"))
                        }

                        // Attachment Button
                        Button(action: {}) {
                            Image(systemName: "link")
                                .font(.system(size: 22))
                                .foregroundColor(Color(hex: "#2C4F40"))
                        }

                        // Title Toggle Button
                        Button(action: {
                            let lightFeedback = UIImpactFeedbackGenerator(style: .light)
                            lightFeedback.impactOccurred()
                            showingTitleOption.toggle()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "textformat")
                                    .font(.system(size: 18))
                                Text("Title")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(showingTitleOption ? Color(hex: "#2C4F40") : .gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                showingTitleOption
                                    ? Color(hex: "#2C4F40").opacity(0.1)
                                    : Color.clear
                            )
                            .cornerRadius(16)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white)
                }
            }
            .background(Color.white)
            .navigationBarHidden(true)
            .overlay(
                Group {
                    if showingSuccessMessage {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                Text("Post shared successfully!")
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
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSuccessMessage)
                    }
                }
            )
            .alert("Discard Post?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) {
                    clearForm()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("Are you sure you want to discard this post? Your changes will be lost.")
            }
        }
    }

    // MARK: - Computed Properties

    private var canPost: Bool {
        let trimmedText = postText.trimmingCharacters(in: .whitespacesAndNewlines)
        return (!trimmedText.isEmpty || !selectedImages.isEmpty) && postText.count <= 280
    }

    private var hasUnsavedContent: Bool {
        !postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !selectedImages.isEmpty ||
        (showingTitleOption && !postTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    // MARK: - Post Creation Functions

    private func handleClose() {
        if hasUnsavedContent {
            showingDiscardAlert = true
        } else {
            clearForm()
        }
    }

    private func createPost() {
        guard canPost && !isPosting else { return }

        isPosting = true

        Task { @MainActor in
            let imageUrls = selectedImages.isEmpty ? [] :
                Array(0..<selectedImages.count).map { "https://picsum.photos/300/300?random=\($0 + 600)" }

            await postManager.createPost(
                content: postText,
                title: showingTitleOption && !postTitle.isEmpty ? postTitle : nil,
                images: imageUrls
            )

            clearForm()

            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            showingSuccessMessage = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showingSuccessMessage = false
            }

            isPosting = false
        }
    }

    private func clearForm() {
        postText = ""
        postTitle = ""
        selectedImages.removeAll()
        showingTitleOption = false
    }

    private func addPhoto() {
        let lightFeedback = UIImpactFeedbackGenerator(style: .light)
        lightFeedback.impactOccurred()
        selectedImages.append("photo_\(selectedImages.count)")
    }

    private func addCameraPhoto() {
        let lightFeedback = UIImpactFeedbackGenerator(style: .light)
        lightFeedback.impactOccurred()
        selectedImages.append("camera_\(selectedImages.count)")
    }
}
