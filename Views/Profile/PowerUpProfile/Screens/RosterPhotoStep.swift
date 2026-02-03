//
//  RosterPhotoStep.swift
//  Club Ralley
//
//  Step 1: Profile photo selection for Power Up Profile
//

import SwiftUI
import PhotosUI

struct RosterPhotoStep: View {
    @EnvironmentObject var viewModel: PowerUpProfileViewModel

    @State private var selectedItem: PhotosPickerItem?
    @State private var showActionSheet = false
    @State private var showCamera = false
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text(PowerUpStep.rosterPhoto.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)

                Text(PowerUpStep.rosterPhoto.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)

            Spacer()
                .frame(height: 20)

            // Photo placeholder/preview
            Button(action: { showActionSheet = true }) {
                ZStack {
                    if let imageData = viewModel.data.profilePhotoData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 180, height: 180)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(ClubRalleyTheme.Colors.darkGreen, lineWidth: 3)
                            )
                    } else if let photoURL = viewModel.data.profilePhotoURL,
                              !photoURL.isEmpty {
                        AsyncImage(url: URL(string: photoURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 180, height: 180)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(ClubRalleyTheme.Colors.darkGreen, lineWidth: 3)
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
                    if isProcessing || viewModel.isLoading {
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

            // Tap to change / Remove photo button
            if viewModel.data.hasPhoto {
                VStack(spacing: 12) {
                    Button(action: { showActionSheet = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera")
                                .font(.system(size: 14))
                            Text("Change photo")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                    }

                    Button(action: removePhoto) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                            Text("Remove photo")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.red)
                    }
                }
                .padding(.top, 8)
            } else {
                Text("Tap to add photo")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            Spacer()
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
            PowerUpCameraView(imageData: Binding(
                get: { viewModel.data.profilePhotoData },
                set: { data in
                    if let data = data {
                        Task {
                            await viewModel.updatePhoto(data)
                        }
                    }
                }
            ))
        }
    }

    // MARK: - Actions

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        isProcessing = true
        defer { isProcessing = false }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                await viewModel.updatePhoto(data)
            }
        } catch {
            print("RosterPhotoStep: Failed to load image: \(error)")
        }
    }

    private func removePhoto() {
        viewModel.removePhoto()
    }
}

// MARK: - Camera View

struct PowerUpCameraView: UIViewControllerRepresentable {
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
        let parent: PowerUpCameraView

        init(_ parent: PowerUpCameraView) {
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

// MARK: - Preview

struct RosterPhotoStep_Previews: PreviewProvider {
    static var previews: some View {
        RosterPhotoStep()
            .environmentObject(PowerUpProfileViewModel())
    }
}
