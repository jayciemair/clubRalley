//
//  PostCardViews.swift
//  Club Ralley
//
//  Post card components for the home feed — author row, photo collage, action bar
//

import SwiftUI
import UIKit

// MARK: - Home Feed Post Card

struct HomeFeedPostCard: View {
    let post: ClubRalleyPost
    @State private var isLiked = false

    private var initials: String {
        let parts = post.authorName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    private var subtitle: String {
        let location = post.authorLocation ?? ""
        if location.isEmpty {
            return post.timeAgo
        }
        return "\(post.timeAgo) · \(location)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Author row
            HStack(alignment: .center, spacing: 12) {
                // Avatar — 46pt green circle with initials
                Circle()
                    .fill(Color(hex: "#2C4F40"))
                    .frame(width: 46, height: 46)
                    .overlay(
                        Text(initials)
                            .font(.system(size: 18, weight: .bold))
                            .fontDesign(.rounded)
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(post.authorName)
                        .font(.system(size: 16, weight: .bold))
                        .fontDesign(.rounded)
                        .foregroundColor(Color(hex: "#2C4F40"))

                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold))
                        .fontDesign(.rounded)
                        .foregroundColor(Color(hex: "#2C4F40").opacity(0.55))
                }

                Spacer()
            }

            // 2. Post title
            if let title = post.title, !title.isEmpty {
                Text(title)
                    .font(.custom("Chillax-Bold", size: 17))
                    .foregroundColor(Color(hex: "#2C4F40"))
                    .padding(.top, 14)
                    .padding(.bottom, 4)
            }

            // 3. Post text
            if !post.content.isEmpty {
                Text(post.content)
                    .font(.system(size: 14, weight: .medium))
                    .fontDesign(.rounded)
                    .foregroundColor(Color(hex: "#2C4F40").opacity(0.7))
                    .lineSpacing(2)
                    .padding(.bottom, 14)
            }

            // 4. Photos (full bleed)
            if !post.images.isEmpty {
                PostPhotoCollage(photos: post.images)
                    .padding(.horizontal, -22)
            }

            // 5. Mutuals row
            if post.likes > 0 {
                HomeMutualsRow()
                    .padding(.top, 10)
            }

            // 6. Action bar separator (full bleed)
            Rectangle()
                .fill(Color(hex: "#ECE9E2"))
                .frame(height: 1)
                .padding(.horizontal, -22)
                .padding(.top, 10)

            // 7. Action bar
            PostActionBar(isLiked: $isLiked)
                .padding(.top, 10)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
    }
}

// MARK: - Photo Collage

struct PostPhotoCollage: View {
    let photos: [String]

    var body: some View {
        Group {
            switch photos.count {
            case 1:
                singlePhoto
            case 2:
                twoPhotos
            default:
                fivePhotoGrid
            }
        }
    }

    // 1 photo — full width, 240pt
    private var singlePhoto: some View {
        photoImage(photos[0])
            .frame(height: 240)
            .clipped()
    }

    // 2 photos — side by side, 210pt, 2pt gap
    private var twoPhotos: some View {
        HStack(spacing: 2) {
            photoImage(photos[0])
                .frame(height: 210)
                .clipped()
            photoImage(photos[1])
                .frame(height: 210)
                .clipped()
        }
    }

    // 5-photo collage — 290pt total
    // Left column: 1 tall photo (top) + 2 small photos side by side (bottom)
    // Right column: 2 stacked photos spanning full height
    private var fivePhotoGrid: some View {
        let p = Array(photos.prefix(5))
        return HStack(spacing: 2) {
            // Left column
            VStack(spacing: 2) {
                photoImage(p[0])
                    .frame(height: 144)
                    .clipped()

                HStack(spacing: 2) {
                    photoImage(p.count > 1 ? p[1] : p[0])
                        .frame(height: 144)
                        .clipped()
                    photoImage(p.count > 2 ? p[2] : p[0])
                        .frame(height: 144)
                        .clipped()
                }
            }

            // Right column
            VStack(spacing: 2) {
                photoImage(p.count > 3 ? p[3] : p[0])
                    .frame(height: 144)
                    .clipped()
                photoImage(p.count > 4 ? p[4] : p[0])
                    .frame(height: 144)
                    .clipped()
            }
        }
        .frame(height: 290)
    }

    private func photoImage(_ url: String) -> some View {
        AsyncImage(url: URL(string: url)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color(hex: "#E2E4D6").opacity(0.5))
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#2C4F40").opacity(0.3))
                )
        }
    }
}

// MARK: - Action Bar

struct PostActionBar: View {
    @Binding var isLiked: Bool

    var body: some View {
        HStack {
            // Heart
            Button(action: { isLiked.toggle() }) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundColor(isLiked ? Color(hex: "#E74C3C") : Color(hex: "#999999"))
            }

            Spacer()

            // Repost
            Button(action: {}) {
                Image(systemName: "arrow.2.squarepath")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#999999"))
            }

            Spacer()

            // Comment
            Button(action: {}) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#999999"))
            }

            Spacer()

            // Share
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#999999"))
            }
        }
    }
}

// MARK: - Share Helper

enum ShareHelper {
    static func sharePost(_ post: ClubRalleyPost) {
        var content = ""
        if let title = post.title, !title.isEmpty { content += "\(title)\n\n" }
        content += post.content + "\n\nShared from Club Ralley"

        let activityVC = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = scene.windows.first?.rootViewController else { return }
            var top = root
            while let presented = top.presentedViewController { top = presented }
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = top.view
                popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
            }
            top.present(activityVC, animated: true)
        }
    }
}
