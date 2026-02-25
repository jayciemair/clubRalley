//
//  RepostSheet.swift
//  Club Ralley
//
//  Sheet for reposting with optional quote comment.
//

import SwiftUI

struct RepostSheet: View {
    let post: ClubRalleyPost
    @EnvironmentObject var postManager: PostManager
    @Environment(\.dismiss) private var dismiss

    @State private var quoteComment = ""
    @State private var isReposting = false
    @State private var showQuoteOption = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Options
                VStack(spacing: 0) {
                    // Quick Repost Option
                    Button(action: { Task { await quickRepost() } }) {
                        HStack(spacing: 16) {
                            Image(systemName: "arrow.2.squarepath")
                                .font(.system(size: 22))
                                .foregroundColor(Color(hex: "#2C4F40"))
                                .frame(width: 44, height: 44)
                                .background(Color(hex: "#2C4F40").opacity(0.1))
                                .cornerRadius(22)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Repost")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                                Text("Share instantly to your followers")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            if isReposting && !showQuoteOption {
                                ProgressView()
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(16)
                    }
                    .disabled(isReposting)

                    Divider()
                        .padding(.leading, 76)

                    // Quote Repost Option
                    Button(action: { showQuoteOption = true }) {
                        HStack(spacing: 16) {
                            Image(systemName: "quote.bubble")
                                .font(.system(size: 22))
                                .foregroundColor(Color(hex: "#2C4F40"))
                                .frame(width: 44, height: 44)
                                .background(Color(hex: "#2C4F40").opacity(0.1))
                                .cornerRadius(22)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Quote")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                                Text("Add your thoughts to this post")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(16)
                    }
                    .disabled(isReposting)
                }
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 16)
                .padding(.top, 20)

                // Quote Input (shown when quote option selected)
                if showQuoteOption {
                    VStack(spacing: 16) {
                        // Quote Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Add your comment")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)

                            TextField("What do you think?", text: $quoteComment, axis: .vertical)
                                .font(.system(size: 16))
                                .lineLimit(5, reservesSpace: true)
                                .padding(12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }

                        // Original Post Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Original post by \(post.authorName)")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)

                            Text(post.content)
                                .font(.system(size: 14))
                                .lineLimit(3)
                                .foregroundColor(.black.opacity(0.7))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(10)
                        }

                        // Post Button
                        Button(action: { Task { await quoteRepost() } }) {
                            HStack {
                                if isReposting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                Text(isReposting ? "Posting..." : "Post")
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#2C4F40"))
                            .cornerRadius(12)
                        }
                        .disabled(isReposting)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }

                Spacer()
            }
            .background(Color(hex: "#F5F5F5"))
            .navigationTitle("Repost")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Actions

    private func quickRepost() async {
        isReposting = true

        if let engagementManager = postManager.engagementManager {
            let success = await engagementManager.repost(postId: post.id)
            if success {
                dismiss()
            }
        }

        isReposting = false
    }

    private func quoteRepost() async {
        isReposting = true

        let comment = quoteComment.trimmingCharacters(in: .whitespacesAndNewlines)
        if let engagementManager = postManager.engagementManager {
            let success = await engagementManager.repost(
                postId: post.id,
                comment: comment.isEmpty ? nil : comment
            )
            if success {
                dismiss()
            }
        }

        isReposting = false
    }
}

// MARK: - Repost Button

struct RepostButton: View {
    let post: ClubRalleyPost
    @State private var showingRepostSheet = false
    @EnvironmentObject var postManager: PostManager

    var body: some View {
        Button(action: { showingRepostSheet = true }) {
            Image(systemName: post.isReposted ? "arrow.2.squarepath" : "arrow.2.squarepath")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(post.isReposted ? Color(hex: "#2C4F40") : Color(hex: "#2C4F40"))
        }
        .sheet(isPresented: $showingRepostSheet) {
            RepostSheet(post: post)
                .environmentObject(postManager)
        }
    }
}
