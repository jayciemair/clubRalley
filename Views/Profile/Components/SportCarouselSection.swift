//
//  SportCarouselSection.swift
//  Club Ralley
//
//  Horizontal sport carousel with tap-to-filter rally history
//

import SwiftUI

// MARK: - Sport Carousel Section

struct SportCarouselSection: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header — pill badge
            HStack(spacing: 8) {
                Text("My Sports")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#2D4A3E"))
                    .cornerRadius(20)

                Spacer()

                if viewModel.selectedSportFilter != nil {
                    Button(action: { viewModel.selectedSportFilter = nil }) {
                        Text("Show All")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D4A3E"))
                    }
                }
            }

            if viewModel.effectiveSportsWithSkills.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.effectiveSportsWithSkills) { sport in
                            ProfileSportCard(
                                sport: sport,
                                isSelected: viewModel.selectedSportFilter == sport.sportName
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if viewModel.selectedSportFilter == sport.sportName {
                                        viewModel.selectedSportFilter = nil
                                    } else {
                                        viewModel.selectedSportFilter = sport.sportName
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "#2D4A3E").opacity(0.3))
                Text("Add your sports")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#6B7B6E"))
            }
            .padding(.vertical, 24)
            Spacer()
        }
        .background(Color(hex: "#E8E4DA").opacity(0.5))
        .cornerRadius(14)
    }
}

// MARK: - Sport Card (Premium)

struct ProfileSportCard: View {
    let sport: UserSportSkill
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: SportIconMapper.iconName(for: sport.sportName))
                    .font(.system(size: 26))
                    .foregroundColor(isSelected ? .white : Color(hex: "#2D4A3E"))

                Text(sport.sportName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isSelected ? .white : Color(hex: "#2D4A3E"))
                    .lineLimit(1)

                Text(sport.skillLevel.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : Color(hex: "#6B7B6E"))
            }
            .frame(width: 110, height: 100)
            .background(isSelected ? Color(hex: "#2D4A3E") : Color(hex: "#F5F2EB"))
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(isSelected ? 0.15 : 0.06), radius: isSelected ? 8 : 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.clear : Color(hex: "#E8E4DA"), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
