//
//  LikesSheetView.swift
//  Club Ralley
//
//  Sheet view for displaying users who liked a post
//

import SwiftUI

struct LikesSheetView: View {
    let postId: UUID
    @EnvironmentObject var postManager: PostManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    if postManager.isLoadingLikers {
                        ProgressView()
                            .padding(.top, 40)
                    } else if postManager.selectedPostLikers.isEmpty {
                        emptyLikesView
                    } else {
                        ForEach(postManager.selectedPostLikers) { liker in
                            LikerRow(liker: liker)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .navigationTitle("Likes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                }
            }
        }
        .onAppear {
            Task {
                await postManager.loadLikers(for: postId)
            }
        }
        .onDisappear {
            postManager.clearLikers()
        }
    }

    private var emptyLikesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundColor(ClubRalleyTheme.Colors.darkGreen.opacity(0.5))

            Text("No likes yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
        }
        .padding(.top, 60)
    }
}

// MARK: - Liker Row

struct LikerRow: View {
    let liker: PostLiker

    var body: some View {
        HStack(spacing: 12) {
            // Profile photo
            AsyncImage(url: URL(string: liker.profile_photo_url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Text(initials)
                    .font(.system(size: 14, weight: .bold))
                    .fontDesign(.rounded)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(ClubRalleyTheme.Colors.darkGreen)
                    .clipShape(Circle())
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(liker.fullName)
                    .font(.system(size: 15, weight: .semibold))
                    .fontDesign(.rounded)
                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)

                Text("@\(liker.username)")
                    .font(.system(size: 13))
                    .fontDesign(.rounded)
                    .foregroundColor(ClubRalleyTheme.Colors.mutedText)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private var initials: String {
        let first = liker.first_name.prefix(1)
        let last = liker.last_name.prefix(1)
        return "\(first)\(last)".uppercased()
    }
}
