//
//  PostCreationView.swift
//  Club Ralley
//
//  Interface for creating new posts with photos, titles, and visibility settings.
//

import SwiftUI
import PhotosUI

// MARK: - Post Creation Interface (Inline Composer)

struct PostCreationInterfaceView: View {
    @EnvironmentObject var postManager: PostManager
    @AppStorage("selectedTab") var selectedTab: MainTab = .home

    // Composer state
    @State private var postText = ""
    @State private var selectedImages: [UIImage] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isPosting = false
    @State private var showingPhotosPicker = false
    @State private var showingCamera = false
    @State private var showingError = false
    @State private var errorMessage = ""

    // Auto-focus
    @FocusState private var isTextFieldFocused: Bool

    private let supabase = SupabaseManager.shared

    private var canPost: Bool {
        !postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImages.isEmpty
    }

    private var userProfile: SavedUserProfile? {
        SavedUserProfile.loadFromStorage()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            composerHeader

            Divider()

            // Composer area
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    composerInput

                    if !selectedImages.isEmpty {
                        imagePreviewSection
                    }

                    Spacer(minLength: 100)
                }
            }

            // Bottom toolbar
            composerToolbar
        }
        .background(Color.white)
        .onTapGesture {
            isTextFieldFocused = false
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isTextFieldFocused = true
            }
        }
        .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedItems, maxSelectionCount: 4, matching: .images)
        .onChange(of: selectedItems) { _, newItems in
            Task {
                selectedImages.removeAll()
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImages.append(image)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            PostCameraView(capturedImage: Binding(
                get: { nil },
                set: { image in
                    if let image = image {
                        selectedImages.append(image)
                    }
                }
            ))
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Top Bar

    private var composerHeader: some View {
        HStack {
            Button(action: { selectedTab = .home }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
            }

            Spacer()

            Button(action: submitPost) {
                Text("Post")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(canPost ? Color(hex: "#2C4F40") : .gray.opacity(0.5))
            }
            .disabled(!canPost || isPosting)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Composer Input

    private var composerInput: some View {
        HStack(alignment: .top, spacing: 12) {
            // User profile photo
            if let photoURL = userProfile?.profilePhotoURL, !photoURL.isEmpty {
                AsyncImage(url: URL(string: photoURL)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    profileInitials
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else {
                profileInitials
            }

            // Text input
            TextField("What's happening?", text: $postText, axis: .vertical)
                .font(.system(size: 17))
                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                .lineLimit(20, reservesSpace: false)
                .focused($isTextFieldFocused)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var profileInitials: some View {
        let initials: String = {
            let first = userProfile?.firstName.prefix(1) ?? "?"
            return String(first).uppercased()
        }()

        return Text(initials)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 36, height: 36)
            .background(Color(hex: "#2C4F40"))
            .clipShape(Circle())
    }

    // MARK: - Image Preview

    private var imagePreviewSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(selectedImages.indices, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: selectedImages[index])
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipped()
                            .cornerRadius(12)

                        Button(action: {
                            selectedImages.remove(at: index)
                            if index < selectedItems.count {
                                selectedItems.remove(at: index)
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .offset(x: 6, y: -6)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Bottom Toolbar

    private var composerToolbar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 24) {
                // Photo library
                Button(action: { showingPhotosPicker = true }) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }

                // Camera
                Button(action: { showingCamera = true }) {
                    Image(systemName: "camera")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .background(Color.white)
    }

    // MARK: - Submit

    private func submitPost() {
        guard canPost && !isPosting else { return }
        isPosting = true

        Task { @MainActor in
            // Clear any previous error before attempting
            postManager.clearError()

            let imageUrls = selectedImages.isEmpty ? [] :
                Array(0..<selectedImages.count).map { "https://picsum.photos/300/300?random=\($0 + 600)" }

            await postManager.createPost(
                content: postText,
                title: nil,
                images: imageUrls,
                visibility: .everyone
            )

            isPosting = false

            // If an error occurred, show it and keep composer open with text preserved
            if let error = postManager.error {
                errorMessage = "Failed to create post: \(error.localizedDescription)"
                showingError = true
                return
            }

            // Success — reset state and navigate to home
            postText = ""
            selectedImages = []
            selectedItems = []
            selectedTab = .home
        }
    }
}

// MARK: - Thread Composer View

struct ThreadComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var postManager: PostManager

    @State private var postText = ""
    @State private var postTitle = ""
    @State private var showingTitleOption = false
    @State private var selectedImages: [UIImage] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isPosting = false
    @State private var showingPhotosPicker = false
    @State private var showingCamera = false
    @State private var showingError = false
    @State private var errorMessage = ""

    private let supabase = SupabaseManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView

                // Main content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Profile and text input
                        textInputSection

                        // Selected images preview
                        if !selectedImages.isEmpty {
                            imagesPreviewSection
                        }

                        Spacer(minLength: 100)
                    }
                }

                // Bottom toolbar
                bottomToolbar
            }
            .background(Color.white)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationBarHidden(true)
        }
        .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedItems, maxSelectionCount: 4, matching: .images)
        .onChange(of: selectedItems) { _, newItems in
            Task {
                selectedImages.removeAll()
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImages.append(image)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            PostCameraView(capturedImage: Binding(
                get: { nil },
                set: { image in
                    if let image = image {
                        selectedImages.append(image)
                    }
                }
            ))
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                }

                Spacer()

                Button(action: createPost) {
                    Text("Post")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(canPost ? Color(hex: "#2C4F40") : .gray)
                }
                .disabled(!canPost || isPosting)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()
        }
    }

    // MARK: - Text Input Section

    private var textInputSection: some View {
        HStack(alignment: .top, spacing: 12) {
            // Profile photo
            AsyncImage(url: URL(string: supabase.currentUser?.email ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle().fill(Color(hex: "#2C4F40"))
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                if showingTitleOption {
                    TextField("Add a Title", text: $postTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                }

                TextField("What's happening?", text: $postText, axis: .vertical)
                    .font(.system(size: 17))
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                    .lineLimit(20, reservesSpace: false)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Images Preview

    private var imagesPreviewSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(selectedImages.indices, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: selectedImages[index])
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipped()
                            .cornerRadius(12)

                        Button(action: {
                            selectedImages.remove(at: index)
                            if index < selectedItems.count {
                                selectedItems.remove(at: index)
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .offset(x: 6, y: -6)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 20) {
                // Title toggle
                Button(action: { showingTitleOption.toggle() }) {
                    Image(systemName: "square")
                        .font(.system(size: 22))
                        .foregroundColor(showingTitleOption ? Color(hex: "#2C4F40") : .gray)
                }

                Spacer()

                // Camera button
                Button(action: { showingCamera = true }) {
                    Image(systemName: "camera")
                        .font(.system(size: 22))
                        .foregroundColor(.gray)
                }

                // Photo library button
                Button(action: { showingPhotosPicker = true }) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 22))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.white)
    }

    // MARK: - Helpers

    private var canPost: Bool {
        !postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !selectedImages.isEmpty
    }

    private func createPost() {
        guard canPost && !isPosting else { return }
        isPosting = true

        Task { @MainActor in
            // Clear any previous error before attempting
            postManager.clearError()

            // In production, upload images and get URLs
            let imageUrls = selectedImages.isEmpty ? [] :
                Array(0..<selectedImages.count).map { "https://picsum.photos/300/300?random=\($0 + 600)" }

            await postManager.createPost(
                content: postText,
                title: showingTitleOption && !postTitle.isEmpty ? postTitle : nil,
                images: imageUrls,
                visibility: .everyone
            )

            isPosting = false

            // If an error occurred, show it and keep composer open with text preserved
            if let error = postManager.error {
                errorMessage = "Failed to create post: \(error.localizedDescription)"
                showingError = true
                return
            }

            // Success — dismiss
            dismiss()
        }
    }
}
