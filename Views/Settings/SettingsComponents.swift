//
//  SettingsComponents.swift
//  Club Ralley
//
//  Shared components for settings views
//

import SwiftUI

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    var showChevron = true

    var body: some View {
        HStack(spacing: ClubRalleyTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)

            Text(title)
                .font(ClubRalleyTheme.Typography.body)
                .foregroundColor(ClubRalleyTheme.Colors.text)

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Custom Text Field Style

struct ClubRalleyTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(ClubRalleyTheme.Colors.sageGreen.opacity(0.3))
            .cornerRadius(ClubRalleyTheme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ClubRalleyTheme.CornerRadius.medium)
                    .stroke(ClubRalleyTheme.Colors.accent.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.editedImage] as? UIImage {
                parent.image = image
            } else if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
