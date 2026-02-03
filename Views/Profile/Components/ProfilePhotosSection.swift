//
//  ProfilePhotosSection.swift
//  Club Ralley
//
//  Photos grid section for profile view matching Figma design
//

import SwiftUI

struct ProfilePhotosSection: View {
    let photos: [UserPhoto]
    @State private var showingAllPhotos = false
    @State private var selectedPhoto: UserPhoto?
    
    var body: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.md) {
            // Section header
            HStack {
                Button(action: {
                    showingAllPhotos = true
                }) {
                    Text("My Pics")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                        .padding(.horizontal, ClubRalleyTheme.Spacing.md)
                        .padding(.vertical, ClubRalleyTheme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(ClubRalleyTheme.Colors.accent)
                        )
                }
                .clubRalleyButtonStyle(.primary)
                
                Spacer()
            }
            
            // Photos grid - 4x2 grid showing first 8 photos
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4),
                spacing: 4
            ) {
                ForEach(Array(photos.prefix(8).enumerated()), id: \.offset) { index, photo in
                    PhotoGridItem(photo: photo, onTap: {
                        selectedPhoto = photo
                    })
                }
            }
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
                    .fill(ClubRalleyTheme.Colors.sageGreen)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(ClubRalleyTheme.Colors.accent)
                    )
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: ClubRalleyTheme.CornerRadius.small))
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
                                .fill(ClubRalleyTheme.Colors.sageGreen)
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
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ClubRalleyTheme.Colors.accent)
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
                // Main photo
                AsyncImage(url: URL(string: photo.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(ClubRalleyTheme.Colors.sageGreen)
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Photo info
                VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.md) {
                    if let caption = photo.caption, !caption.isEmpty {
                        Text(caption)
                            .font(ClubRalleyTheme.Typography.body)
                            .foregroundColor(ClubRalleyTheme.Colors.text)
                    }
                    
                    // Engagement stats
                    HStack(spacing: ClubRalleyTheme.Spacing.lg) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(ClubRalleyTheme.Colors.error)
                            Text("\(photo.likesCount)")
                                .font(ClubRalleyTheme.Typography.footnote)
                                .foregroundColor(ClubRalleyTheme.Colors.text)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.right.fill")
                                .foregroundColor(ClubRalleyTheme.Colors.accent)
                            Text("\(photo.commentsCount)")
                                .font(ClubRalleyTheme.Typography.footnote)
                                .foregroundColor(ClubRalleyTheme.Colors.text)
                        }
                        
                        Spacer()
                        
                        Text(formatDate(photo.createdAt))
                            .font(ClubRalleyTheme.Typography.caption)
                            .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                    }
                    
                    // Tags
                    if !photo.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(photo.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(ClubRalleyTheme.Typography.caption)
                                        .foregroundColor(ClubRalleyTheme.Colors.accent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(ClubRalleyTheme.Colors.sageGreen)
                                        )
                                }
                            }
                            .padding(.horizontal, ClubRalleyTheme.Spacing.md)
                        }
                    }
                }
                .padding(ClubRalleyTheme.Spacing.md)
                .background(ClubRalleyTheme.Colors.background)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(ClubRalleyTheme.Colors.accent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Handle share action
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(ClubRalleyTheme.Colors.accent)
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
            let caption: String? = index % 3 == 0 ? "Great game today! #tennis #bucknell" : nil
            let date = Date().addingTimeInterval(-Double(index) * 86400)
            let tags: [String] = index % 2 == 0 ? ["tennis", "bucknell", "game"] : []
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