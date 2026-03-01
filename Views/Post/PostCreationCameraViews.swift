//
//  PostCreationCameraViews.swift
//  Club Ralley
//
//  Photo and camera post creation views extracted from PostCreationView.swift.
//

import SwiftUI
import PhotosUI

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
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)

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
            // Clear any previous error before attempting
            postManager.clearError()

            // Upload selected images to Supabase Storage
            let postId = UUID()
            let imageDatas = selectedImages.compactMap { $0.jpegData(compressionQuality: 0.9) }
            var imageUrls: [String] = []
            do {
                imageUrls = try await ImageUploadService.shared.uploadPostImages(imageDatas: imageDatas, postId: postId)
            } catch {
                errorMessage = "Failed to upload images: \(error.localizedDescription)"
                showingError = true
                isPosting = false
                return
            }

            await postManager.createPost(
                content: postText.isEmpty ? "" : postText,
                title: nil,
                images: imageUrls,
                visibility: .everyone
            )

            isPosting = false

            // If an error occurred, show it and keep view open with selections preserved
            if postManager.error != nil {
                errorMessage = "Failed to create post. Please check your connection and try again."
                showingError = true
                return
            }

            // Success — dismiss
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
            // Clear any previous error before attempting
            postManager.clearError()

            // Upload captured image to Supabase Storage
            var imageUrls: [String] = []
            if let image = capturedImage, let imageData = image.jpegData(compressionQuality: 0.9) {
                let postId = UUID()
                do {
                    let url = try await ImageUploadService.shared.uploadPostImage(imageData: imageData, postId: postId)
                    imageUrls = [url]
                } catch {
                    errorMessage = "Failed to upload photo: \(error.localizedDescription)"
                    showingError = true
                    isPosting = false
                    return
                }
            }

            await postManager.createPost(
                content: "",
                title: nil,
                images: imageUrls,
                visibility: .everyone
            )

            isPosting = false

            // If an error occurred, show it and keep view open with photo preserved
            if postManager.error != nil {
                errorMessage = "Failed to create post. Please check your connection and try again."
                showingError = true
                return
            }

            // Success — dismiss
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
