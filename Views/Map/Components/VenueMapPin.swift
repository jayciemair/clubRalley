//
//  VenueMapPin.swift
//  Club Ralley
//
//  Custom map pin for venue annotations
//

import SwiftUI

// MARK: - Venue Map Pin

struct VenueMapPin: View {
    let venue: Venue
    let isSelected: Bool

    private let darkGreen = Color(hex: "#2C4F40")

    var body: some View {
        VStack(spacing: 0) {
            // Pin circle
            ZStack {
                Circle()
                    .fill(isSelected ? darkGreen : .white)
                    .frame(width: isSelected ? 38 : 30, height: isSelected ? 38 : 30)
                    .shadow(color: .black.opacity(isSelected ? 0.2 : 0.15), radius: 4, x: 0, y: 2)

                Image(systemName: venue.iconName)
                    .font(.system(size: isSelected ? 16 : 13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : darkGreen)
            }

            // Triangle pointer
            Triangle()
                .fill(isSelected ? darkGreen : .white)
                .frame(width: isSelected ? 12 : 8, height: isSelected ? 6 : 4)
                .shadow(color: .black.opacity(isSelected ? 0 : 0.1), radius: 2, x: 0, y: 1)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
