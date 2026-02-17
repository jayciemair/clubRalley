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
            // Section header
            HStack(spacing: 8) {
                Text("My Sports")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#2C4F40"))
                    .cornerRadius(14)

                Spacer()

                if viewModel.selectedSportFilter != nil {
                    Button(action: { viewModel.selectedSportFilter = nil }) {
                        Text("Show All")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "#2C4F40"))
                    }
                }
            }

            if viewModel.effectiveSportsWithSkills.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.effectiveSportsWithSkills) { sport in
                            ProfileSportCarouselCard(
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
                    .font(.system(size: 30))
                    .foregroundColor(Color.black.opacity(0.3))
                Text("No sports added yet — Join a ralley to get started!")
                    .font(.system(size: 14))
                    .foregroundColor(Color.black.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }
}

// MARK: - Sport Carousel Card

struct ProfileSportCarouselCard: View {
    let sport: UserSportSkill
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: SportIconMapper.iconName(for: sport.sportName))
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : Color(hex: "#2C4F40"))

                Text(sport.sportName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .black)
                    .lineLimit(1)

                Text(sport.skillLevel.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : Color.black.opacity(0.5))
            }
            .frame(width: 110, height: 100)
            .background(isSelected ? Color(hex: "#2C4F40") : Color(hex: "#E2E4D6"))
            .cornerRadius(14)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
