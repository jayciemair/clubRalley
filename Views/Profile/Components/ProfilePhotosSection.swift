//
//  ProfilePhotosSection.swift
//  Club Ralley
//
//  Photos grid section for profile view — 4-column layout with pill badge header
//

import SwiftUI

struct ProfilePhotosSection: View {
    let photos: [UserPhoto]
    @State private var showingAllPhotos = false
    @State private var selectedPhoto: UserPhoto?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Green pill header
            HStack {
                ProfileSectionHeader(title: "My Pics")

                Spacer()

                if photos.count > 9 {
                    Button(action: { showingAllPhotos = true }) {
                        Text("See All")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "#2C4F40"))
                    }
                }
            }

            // 3-column photo grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3),
                spacing: 2
            ) {
                ForEach(Array(photos.prefix(9).enumerated()), id: \.offset) { _, photo in
                    PhotoGridItem(photo: photo, onTap: {
                        selectedPhoto = photo
                    })
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .sheet(isPresented: $showingAllPhotos) {
            AllPhotosView(photos: photos)
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo)
        }
    }
}

struct PhotoGridItem: View {
    let photo: UserPhoto
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            AsyncImage(url: URL(string: photo.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(hex: "#E2E4D6").opacity(0.5))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(Color(hex: "#2C4F40").opacity(0.3))
                    )
            }
            .aspectRatio(1, contentMode: .fill)
            .clipped()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AllPhotosView: View {
    let photos: [UserPhoto]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: UserPhoto?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3),
                    spacing: 2
                ) {
                    ForEach(photos) { photo in
                        AsyncImage(url: URL(string: photo.imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(Color(hex: "#E8E4DA"))
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.8)
                                )
                        }
                        .onTapGesture {
                            selectedPhoto = photo
                        }
                    }
                }
            }
            .navigationTitle("All Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#2D4A3E"))
                }
            }
            .sheet(item: $selectedPhoto) { photo in
                PhotoDetailView(photo: photo)
            }
        }
    }
}

struct PhotoDetailView: View {
    let photo: UserPhoto
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                AsyncImage(url: URL(string: photo.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color(hex: "#E8E4DA"))
                        .overlay(ProgressView())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Photo info
                VStack(alignment: .leading, spacing: 12) {
                    if let caption = photo.caption, !caption.isEmpty {
                        Text(caption)
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#2D4A3E"))
                    }

                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red.opacity(0.8))
                            Text("\(photo.likesCount)")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#2D4A3E"))
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "bubble.right.fill")
                                .foregroundColor(Color(hex: "#2D4A3E"))
                            Text("\(photo.commentsCount)")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#2D4A3E"))
                        }

                        Spacer()

                        Text(formatDate(photo.createdAt))
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#6B7B6E"))
                    }

                    if !photo.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(photo.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#2D4A3E"))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule().fill(Color(hex: "#E8E4DA"))
                                        )
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color(hex: "#F5F2EB"))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color(hex: "#2D4A3E"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color(hex: "#2D4A3E"))
                    }
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct ProfilePhotosSection_Previews: PreviewProvider {
    static var mockPhotos: [UserPhoto] {
        (1...12).map { index -> UserPhoto in
            let caption: String? = index % 3 == 0 ? "Great game today!" : nil
            let date = Date().addingTimeInterval(-Double(index) * 86400)
            let tags: [String] = index % 2 == 0 ? ["tennis", "bucknell"] : []
            return UserPhoto(
                id: UUID(),
                imageURL: "https://picsum.photos/200/200?random=\(index)",
                caption: caption,
                createdAt: date,
                likesCount: Int.random(in: 5...50),
                commentsCount: Int.random(in: 0...15),
                tags: tags
            )
        }
    }

    static var previews: some View {
        ProfilePhotosSection(photos: mockPhotos)
            .padding()
    }
}
