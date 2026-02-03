//
//  PostCreationView.swift
//  Club Ralley
//
//  Interface for creating new posts with photos, titles, and visibility settings.
//

import SwiftUI
import PhotosUI

// MARK: - Post Type Selection Popup

struct PostTypePopup: View {
    @Binding var isPresented: Bool
    let onSelectThread: () -> Void
    let onSelectPhotos: () -> Void
    let onSelectCamera: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }

            // Popup content
            VStack {
                Spacer()

                VStack(spacing: 0) {
                    PostTypeOption(
                        title: "Thread",
                        icon: "square.and.pencil",
                        action: {
                            withAnimation { isPresented = false }
                            onSelectThread()
                        }
                    )

                    Divider()

                    PostTypeOption(
                        title: "Photos",
                        icon: "photo.on.rectangle",
                        action: {
                            withAnimation { isPresented = false }
                            onSelectPhotos()
                        }
                    )

                    Divider()

                    PostTypeOption(
                        title: "Camera",
                        icon: "camera",
                        action: {
                            withAnimation { isPresented = false }
                            onSelectCamera()
                        }
                    )
                }
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 60)
                .padding(.bottom, 120)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            }
        }
    }
}

struct PostTypeOption: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.black)

                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Post Creation Interface (Tab View)

struct PostCreationInterfaceView: View {
    @EnvironmentObject var postManager: PostManager
    @State private var showingPopup = false
    @State private var showingThreadComposer = false
    @State private var showingPhotosPicker = false
    @State private var showingCamera = false

    var body: some View {
        ZStack {
            // Empty placeholder - actual content shows via sheets/popups
            VStack {
                Spacer()
                Text("Tap the + button to create a post")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#F5F5F5"))
            .onAppear {
                // Show popup when tab is selected
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !showingThreadComposer && !showingPhotosPicker && !showingCamera {
                        showingPopup = true
                    }
                }
            }

            // Post type popup
            if showingPopup {
                PostTypePopup(
                    isPresented: $showingPopup,
                    onSelectThread: {
                        showingThreadComposer = true
                    },
                    onSelectPhotos: {
                        showingPhotosPicker = true
                    },
                    onSelectCamera: {
                        showingCamera = true
                    }
                )
                .transition(.opacity)
            }
        }
        .fullScreenCover(isPresented: $showingThreadComposer) {
            ThreadComposerView()
                .environmentObject(postManager)
        }
        .fullScreenCover(isPresented: $showingPhotosPicker) {
            PhotoPostView()
                .environmentObject(postManager)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPostView()
                .environmentObject(postManager)
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
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
            }

            Spacer()

            Button(action: createPost) {
                Text("Post")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(canPost ? Color(hex: "#2C4F40") : .gray)
            }
            .disabled(!canPost || isPosting)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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
                        .foregroundColor(.black)
                }

                TextField("What's happening?", text: $postText, axis: .vertical)
                    .font(.system(size: 17))
                    .foregroundColor(.black)
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
            let previousError = postManager.error

            // In production, upload images and get URLs
            let imageUrls = selectedImages.isEmpty ? [] :
                Array(0..<selectedImages.count).map { "https://picsum.photos/300/300?random=\($0 + 600)" }

            await postManager.createPost(
                content: postText,
                title: showingTitleOption && !postTitle.isEmpty ? postTitle : nil,
                images: imageUrls,
                visibility: .everyone
            )

            // Check if error was set during operation
            if postManager.error != nil && postManager.error?.localizedDescription != previousError?.localizedDescription {
                errorMessage = "Failed to create post. Please check your connection and try again."
                showingError = true
                isPosting = false
                return
            }

            isPosting = false
            dismiss()
        }
    }
}

// MARK: - Photo Post View

struct PhotoPostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var postManager: PostManager

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var postText = ""
    @State private var isPosting = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.black)

                    Spacer()

                    // Photos/Albums toggle
                    HStack(spacing: 0) {
                        Text("Photos")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "#E8E8E8"))
                            .cornerRadius(6)

                        Text("Albums")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }

                    Spacer()

                    Button("Add") {
                        createPost()
                    }
                    .foregroundColor(selectedImages.isEmpty ? .gray : Color(hex: "#2C4F40"))
                    .disabled(selectedImages.isEmpty || isPosting)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()

                // Photo picker content
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 4, matching: .images) {
                    VStack {
                        if selectedImages.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("Select photos to share")
                                    .font(.system(size: 17))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 2),
                                    GridItem(.flexible(), spacing: 2),
                                    GridItem(.flexible(), spacing: 2)
                                ], spacing: 2) {
                                    ForEach(selectedImages.indices, id: \.self) { index in
                                        Image(uiImage: selectedImages[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 130)
                                            .clipped()
                                    }
                                }
                            }
                        }
                    }
                }
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
            }
            .background(Color.white)
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func createPost() {
        guard !selectedImages.isEmpty && !isPosting else { return }
        isPosting = true

        Task { @MainActor in
            let previousError = postManager.error
            let imageUrls = Array(0..<selectedImages.count).map { "https://picsum.photos/300/300?random=\($0 + 700)" }

            await postManager.createPost(
                content: postText.isEmpty ? "" : postText,
                title: nil,
                images: imageUrls,
                visibility: .everyone
            )

            // Check if error was set during operation
            if postManager.error != nil && postManager.error?.localizedDescription != previousError?.localizedDescription {
                errorMessage = "Failed to create post. Please check your connection and try again."
                showingError = true
                isPosting = false
                return
            }

            isPosting = false
            dismiss()
        }
    }
}

// MARK: - Camera Post View

struct CameraPostView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var postManager: PostManager

    @State private var capturedImage: UIImage?
    @State private var showingCamera = true
    @State private var isPosting = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            if showingCamera {
                PostCameraView(capturedImage: $capturedImage)
                    .ignoresSafeArea()

                // Close button overlay
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .padding(12)
                        }
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 50)
                .padding(.leading, 20)
            }

            if let image = capturedImage {
                // Preview captured image
                VStack {
                    HStack {
                        Button(action: {
                            capturedImage = nil
                            showingCamera = true
                        }) {
                            Text("Retake")
                                .foregroundColor(.white)
                        }

                        Spacer()

                        Button(action: createPost) {
                            Text("Use Photo")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    Spacer()

                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)

                    Spacer()
                }
                .background(Color.black)
            }
        }
        .onChange(of: capturedImage) { _, newImage in
            if newImage != nil {
                showingCamera = false
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func createPost() {
        guard capturedImage != nil && !isPosting else { return }
        isPosting = true

        Task { @MainActor in
            let previousError = postManager.error

            await postManager.createPost(
                content: "",
                title: nil,
                images: ["https://picsum.photos/300/300?random=\(Int.random(in: 800...999))"],
                visibility: .everyone
            )

            // Check if error was set during operation
            if postManager.error != nil && postManager.error?.localizedDescription != previousError?.localizedDescription {
                errorMessage = "Failed to create post. Please check your connection and try again."
                showingError = true
                isPosting = false
                return
            }

            isPosting = false
            dismiss()
        }
    }
}

// MARK: - Camera View

struct PostCameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PostCameraView

        init(_ parent: PostCameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
