//
//  ProfilePhotoScreen.swift
//  Club Ralley
//
//  Onboarding screen for profile photo (Figma design)
//

import SwiftUI
import PhotosUI

struct ProfilePhotoScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isUploading = false
    @State private var showActionSheet = false
    @State private var showCamera = false

    var body: some View {
        ClubRalleyScrollableLayout(
            canGoBack: controller.canGoBack,
            onBack: { controller.goToPreviousStep() },
            onContinue: { saveAndContinue() },
            continueEnabled: true,
            continueText: selectedImageData == nil ? "Skip" : "Submit"
        ) {
            VStack(spacing: 32) {
                ClubRalleyOnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: controller.currentStep.subtitle
                )

                Spacer()
                    .frame(height: 20)

                // Photo placeholder/preview
                Button(action: { showActionSheet = true }) {
                    ZStack {
                        if let imageData = selectedImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 180, height: 180)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: "#2C4F40"), lineWidth: 3)
                                )
                        } else {
                            // Dashed circle placeholder
                            Circle()
                                .strokeBorder(
                                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                                )
                                .foregroundColor(Color.gray.opacity(0.4))
                                .frame(width: 180, height: 180)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray.opacity(0.4))
                                )
                        }

                        // Loading overlay
                        if isUploading {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 180, height: 180)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.5)
                                )
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Remove photo button (if photo selected)
                if selectedImageData != nil {
                    Button(action: removePhoto) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                            Text("Remove photo")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.red)
                    }
                    .padding(.top, 8)
                }

                Spacer()
            }
            .padding(.top, 20)
        }
        .confirmationDialog("Add Photo", isPresented: $showActionSheet) {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("Photo Gallery")
            }

            Button("Camera") {
                showCamera = true
            }

            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                await loadImage(from: newItem)
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraView(imageData: $selectedImageData)
        }
    }

    // MARK: - Actions

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        isUploading = true
        defer { isUploading = false }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                selectedImageData = data
                _ = try await controller.updateProfilePhoto(data)
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }

    private func removePhoto() {
        selectedItem = nil
        selectedImageData = nil
        controller.skipProfilePhoto()
    }

    private func saveAndContinue() {
        if selectedImageData == nil {
            controller.skipProfilePhoto()
        }
        controller.goToNextStep()
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .front
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
            if let image = info[.originalImage] as? UIImage {
                parent.imageData = image.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct ProfilePhotoScreen_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePhotoScreen()
            .environmentObject(ClubRalleyOnboardingController())
    }
}
