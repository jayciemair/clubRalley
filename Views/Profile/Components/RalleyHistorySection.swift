//
//  RalleyHistorySection.swift
//  Club Ralley
//
//  Rally history section with sport filtering and hosted/attended badges
//

import SwiftUI

// MARK: - Rally History Section

struct RalleyHistorySection: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header — green pill
            HStack(spacing: 10) {
                ProfileSectionHeader(title: "Rally History")

                if let sport = viewModel.selectedSportFilter {
                    Text(sport)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#2C4F40"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "#E2E4D6"))
                        .cornerRadius(50)
                }

                Spacer()

                Text("\(viewModel.filteredRalleys.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }

            if viewModel.filteredRalleys.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.filteredRalleys) { ralley in
                        RalleyHistoryCard(ralley: ralley)
                    }
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 16)
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "#2C4F40").opacity(0.3))
                Text(emptyStateMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#7a8a81"))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 24)
            Spacer()
        }
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var emptyStateMessage: String {
        if let sport = viewModel.selectedSportFilter {
            return "No ralleys in \(sport) yet — join one to get started!"
        }
        return "No ralleys yet — join one to get started!"
    }
}

// MARK: - Rally History Card

struct RalleyHistoryCard: View {
    let ralley: ClubRalley

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: ralley.dateTime)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Sport icon in circle
            ZStack {
                Circle()
                    .fill(Color(hex: "#edf0ed"))
                    .frame(width: 44, height: 44)

                Image(systemName: SportIconMapper.iconName(for: ralley.sport))
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }

            // Title + details
            VStack(alignment: .leading, spacing: 4) {
                Text(ralley.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(formattedDate)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#7a8a81"))

                    Text("·")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#7a8a81"))

                    HStack(spacing: 2) {
                        Image(systemName: "person.2")
                            .font(.system(size: 10))
                        Text("\(ralley.currentPlayers)/\(ralley.maxPlayers)")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(Color(hex: "#7a8a81"))
                }
            }

            Spacer()

            // Hosted / Attended badge
            Text(ralley.isCaptain ? "Hosted" : "Attended")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(ralley.isCaptain ? .white : .black)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(ralley.isCaptain ? Color(hex: "#2C4F40") : Color(hex: "#E2E4D6"))
                .cornerRadius(50)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
