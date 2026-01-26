//
//  PostCreationView.swift
//  Club Ralley
//
//  Post creation interface matching Figma design
//

import SwiftUI
import PhotosUI

struct PostCreationView: View {
    @State private var postText = ""
    @State private var showingPhotosPicker = false
    @State private var showingCamera = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var postImages: [UIImage] = []
    @State private var showingTitleOption = false
    @State private var postTitle = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                // Close Button
                Button(action: {
                    // Handle close
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 30, height: 30)
                }
                
                Spacer()
                
                // Post Button
                Button(action: {
                    // Handle post
                }) {
                    Text("Post")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(postText.isEmpty && postImages.isEmpty ? .gray : .white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            postText.isEmpty && postImages.isEmpty 
                                ? Color.gray.opacity(0.3)
                                : Color(hex: "#2C4F40")
                        )
                        .cornerRadius(20)
                }
                .disabled(postText.isEmpty && postImages.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Main Content
            ScrollView {
                VStack(spacing: 16) {
                    // Profile and Text Input
                    HStack(alignment: .top, spacing: 12) {
                        // Profile Photo
                        AsyncImage(url: URL(string: "https://picsum.photos/40/40?random=1")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color(hex: "#2C4F40"))
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        
                        // Text Input Area
                        VStack(alignment: .leading, spacing: 12) {
                            // Title Input (if enabled)
                            if showingTitleOption {
                                TextField("Add a Title", text: $postTitle)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.vertical, 8)
                            }
                            
                            // Main Text Input
                            TextField("What's happening?", text: $postText, axis: .vertical)
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.black)
                                .lineLimit(10, reservesSpace: false)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Selected Images
                    if !postImages.isEmpty {
                        ImageGridView(images: postImages) { index in
                            postImages.remove(at: index)
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            
            Spacer()
            
            // Bottom Toolbar
            HStack(spacing: 24) {
                // Photo Gallery Button
                Button(action: {
                    showingPhotosPicker = true
                }) {
                    Image(systemName: "photo")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
                
                // Camera Button
                Button(action: {
                    showingCamera = true
                }) {
                    Image(systemName: "camera")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
                
                // Attachment Button
                Button(action: {
                    // Handle attachments
                }) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
                
                // Title Toggle Button
                Button(action: {
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
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.2)),
                alignment: .top
            )
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .photosPicker(
            isPresented: $showingPhotosPicker,
            selection: $selectedPhotos,
            maxSelectionCount: 4,
            matching: .images
        )
        .onChange(of: selectedPhotos) { _ in
            loadImages()
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { image in
                if let image = image {
                    postImages.append(image)
                }
            }
        }
    }
    
    private func loadImages() {
        Task {
            postImages.removeAll()
            for item in selectedPhotos {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    postImages.append(image)
                }
            }
        }
    }
}

// MARK: - Image Grid View

struct ImageGridView: View {
    let images: [UIImage]
    let onRemove: (Int) -> Void
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
            ForEach(images.indices, id: \.self) { index in
                ZStack {
                    Image(uiImage: images[index])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(12)
                    
                    // Remove Button
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                onRemove(index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 22))
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
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage?) -> Void
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
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            parent.onImageCaptured(image)
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

struct PostCreationView_Previews: PreviewProvider {
    static var previews: some View {
        PostCreationView()
    }
}