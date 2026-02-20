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
        VStack(alignment: .leading, spacing: 14) {
            // Section header — green pill + "Show All"
            HStack(spacing: 10) {
                ProfileSectionHeader(title: "My Sports")

                if viewModel.selectedSportFilter != nil {
                    Button(action: { viewModel.selectedSportFilter = nil }) {
                        Text("Show All")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "#7A8A81"))
                    }
                }

                Spacer()

                if viewModel.effectiveSportsWithSkills.count > 3 {
                    Text("Show All")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#7A8A81"))
                }
            }
            .padding(.horizontal, 22)

            if viewModel.effectiveSportsWithSkills.isEmpty {
                emptyState
                    .padding(.horizontal, 22)
            } else {
                // Horizontal scroll carousel
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
                    .padding(.horizontal, 22)
                }
            }
        }
        .padding(.bottom, 16)
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "#2C4F40").opacity(0.3))
                Text("Add your sports")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#7a8a81"))
            }
            .padding(.vertical, 24)
            Spacer()
        }
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Sport Card (Horizontal scroll — 130pt wide)

struct ProfileSportCard: View {
    let sport: UserSportSkill
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Circular icon container
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.2) : Color(hex: "#EDF0ED"))
                        .frame(width: 54, height: 54)

                    Image(systemName: SportIconMapper.iconName(for: sport.sportName))
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(isSelected ? .white : Color(hex: "#2C4F40"))
                }

                Text(sport.sportName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .black)
                    .lineLimit(1)

                Text(sport.skillLevel.displayName)
                    .font(.system(size: 11.5, weight: .regular, design: .rounded))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : Color(hex: "#7A8A81"))
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 16)
            .frame(width: 130)
            .background(isSelected ? Color(hex: "#2C4F40") : Color.white)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(isSelected ? 0.12 : 0.08), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
