//
//  PostVisibilityPicker.swift
//  Club Ralley
//
//  Reusable visibility selector component for posts.
//

import SwiftUI

// MARK: - Post Visibility Picker

struct PostVisibilityPicker: View {
    @Binding var selectedVisibility: PostVisibility
    var showDescription: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Who can see this?")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)

            ForEach(PostVisibility.allCases, id: \.self) { visibility in
                VisibilityOption(
                    visibility: visibility,
                    isSelected: selectedVisibility == visibility,
                    showDescription: showDescription,
                    action: { selectedVisibility = visibility }
                )
            }
        }
    }
}

// MARK: - Visibility Option Row

private struct VisibilityOption: View {
    let visibility: PostVisibility
    let isSelected: Bool
    let showDescription: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: visibility.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? Color(hex: "#2C4F40") : .gray)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? Color(hex: "#2C4F40").opacity(0.1) : Color.gray.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(visibility.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ClubRalleyTheme.Colors.darkGreen)

                    if showDescription {
                        Text(visibility.description)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? Color(hex: "#2C4F40") : Color.gray.opacity(0.3))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "#2C4F40") : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - Compact Visibility Picker

struct CompactVisibilityPicker: View {
    @Binding var selectedVisibility: PostVisibility
    @State private var showingPicker = false

    var body: some View {
        Button(action: { showingPicker.toggle() }) {
            HStack(spacing: 6) {
                Image(systemName: selectedVisibility.iconName)
                    .font(.system(size: 14))
                Text(selectedVisibility.displayName)
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(Color(hex: "#2C4F40"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "#2C4F40").opacity(0.1))
            .cornerRadius(16)
        }
        .sheet(isPresented: $showingPicker) {
            VisibilityPickerSheet(selectedVisibility: $selectedVisibility)
        }
    }
}

// MARK: - Visibility Picker Sheet

struct VisibilityPickerSheet: View {
    @Binding var selectedVisibility: PostVisibility
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PostVisibilityPicker(selectedVisibility: $selectedVisibility)
                    .padding(20)

                Spacer()

                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#2C4F40"))
                        .cornerRadius(12)
                }
                .padding(20)
            }
            .navigationTitle("Post Visibility")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Visibility Badge

struct VisibilityBadge: View {
    let visibility: PostVisibility

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: visibility.iconName)
                .font(.system(size: 10))
            Text(visibility.displayName)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.gray)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}
