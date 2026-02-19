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
        VStack(alignment: .leading, spacing: 16) {
            // Header — pill badge
            HStack(spacing: 8) {
                Text("Rally History")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#2D4A3E"))
                    .cornerRadius(20)

                if let sport = viewModel.selectedSportFilter {
                    Text(sport)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#2D4A3E"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: "#E8E4DA"))
                        .cornerRadius(10)
                }

                Spacer()

                Text("\(viewModel.filteredRalleys.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#2D4A3E"))
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
                Text(emptyStateMessage)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#6B7B6E"))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 24)
            Spacer()
        }
        .background(Color(hex: "#E8E4DA").opacity(0.5))
        .cornerRadius(14)
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
            // Sport icon circle
            Image(systemName: SportIconMapper.iconName(for: ralley.sport))
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "#2D4A3E"))
                .frame(width: 44, height: 44)
                .background(Color(hex: "#E8E4DA"))
                .clipShape(Circle())

            // Title + details
            VStack(alignment: .leading, spacing: 4) {
                Text(ralley.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D4A3E"))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(formattedDate)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#6B7B6E"))

                    Text("·")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#6B7B6E"))

                    HStack(spacing: 2) {
                        Image(systemName: "person.2")
                            .font(.system(size: 10))
                        Text("\(ralley.currentPlayers)/\(ralley.maxPlayers)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color(hex: "#6B7B6E"))
                }
            }

            Spacer()

            // Hosted / Attended badge
            Text(ralley.isCaptain ? "Hosted" : "Attended")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ralley.isCaptain ? .white : Color(hex: "#2D4A3E"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(ralley.isCaptain ? Color(hex: "#2D4A3E") : Color(hex: "#E8E4DA"))
                .cornerRadius(8)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
