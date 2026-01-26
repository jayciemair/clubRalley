//
//  ProfileTeamsSection.swift
//  Club Ralley
//
//  Teams section for profile view matching Figma design
//

import SwiftUI

struct ProfileTeamsSection: View {
    let teams: [UserTeam]
    @State private var showingAllTeams = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.md) {
            // Section header
            HStack {
                Button(action: {
                    showingAllTeams = true
                }) {
                    Text("My Teams")
                        .font(ClubRalleyTheme.Typography.headline)
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                        .padding(.horizontal, ClubRalleyTheme.Spacing.md)
                        .padding(.vertical, ClubRalleyTheme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(ClubRalleyTheme.Colors.accent)
                        )
                }
                .clubRalleyButtonStyle(.primary)
                
                Spacer()
            }
            
            // Teams grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: ClubRalleyTheme.Spacing.md
            ) {
                ForEach(Array(teams.prefix(4).enumerated()), id: \.offset) { index, team in
                    TeamCardView(team: team, cardIndex: index)
                }
            }
        }
        .sheet(isPresented: $showingAllTeams) {
            AllTeamsView(teams: teams)
        }
    }
}

struct TeamCardView: View {
    let team: UserTeam
    let cardIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: ClubRalleyTheme.Spacing.sm) {
            // Team image
            AsyncImage(url: URL(string: team.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(cardBackgroundColor)
                    .overlay(
                        VStack {
                            Image(systemName: sportIcon)
                                .font(.largeTitle)
                                .foregroundColor(.white)
                            
                            Text(team.sport)
                                .font(ClubRalleyTheme.Typography.caption)
                                .foregroundColor(.white)
                        }
                    )
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: ClubRalleyTheme.CornerRadius.medium))
            
            // Team info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(team.name)
                        .font(ClubRalleyTheme.Typography.bodyBold)
                        .foregroundColor(ClubRalleyTheme.Colors.text)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if team.isCurrentTeam {
                        Circle()
                            .fill(ClubRalleyTheme.Colors.success)
                            .frame(width: 8, height: 8)
                    }
                }
                
                if let school = team.school {
                    Text(school)
                        .font(ClubRalleyTheme.Typography.caption)
                        .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                        .lineLimit(1)
                }
                
                if let years = team.years {
                    Text(years)
                        .font(ClubRalleyTheme.Typography.caption2)
                        .foregroundColor(ClubRalleyTheme.Colors.secondaryText)
                }
            }
        }
        .padding(ClubRalleyTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: ClubRalleyTheme.CornerRadius.medium)
                .fill(ClubRalleyTheme.Colors.background)
                .clubRalleyShadow(ClubRalleyTheme.Shadows.light)
        )
    }
    
    private var cardBackgroundColor: Color {
        let colors = [
            ClubRalleyTheme.Colors.accent,
            ClubRalleyTheme.Colors.sageGreen,
            Color.blue,
            Color.orange
        ]
        return colors[cardIndex % colors.count]
    }
    
    private var sportIcon: String {
        switch team.sport.lowercased() {
        case "basketball":
            return "basketball.fill"
        case "football":
            return "football.fill"
        case "soccer":
            return "soccerball"
        case "tennis":
            return "tennisball.fill"
        case "volleyball":
            return "volleyball.fill"
        case "baseball":
            return "baseball.fill"
        case "swimming":
            return "figure.pool.swim"
        default:
            return "sportscourt.fill"
        }
    }
}

struct AllTeamsView: View {
    let teams: [UserTeam]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: ClubRalleyTheme.Spacing.md
                ) {
                    ForEach(Array(teams.enumerated()), id: \.offset) { index, team in
                        TeamCardView(team: team, cardIndex: index)
                    }
                }
                .padding(ClubRalleyTheme.Spacing.md)
            }
            .navigationTitle("All Teams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ClubRalleyTheme.Colors.accent)
                }
            }
        }
    }
}

// MARK: - Preview

struct ProfileTeamsSection_Previews: PreviewProvider {
    static var previews: some View {
        let mockTeams = [
            UserTeam(
                id: UUID(),
                name: "AVS Club",
                sport: "Soccer",
                level: "Club",
                school: "Bucknell University",
                years: "2021-2025",
                imageURL: nil,
                isCurrentTeam: true,
                achievements: []
            ),
            UserTeam(
                id: UUID(),
                name: "Basketball Club",
                sport: "Basketball",
                level: "D1",
                school: "Bucknell University", 
                years: "2020-2024",
                imageURL: nil,
                isCurrentTeam: false,
                achievements: []
            )
        ]
        
        ProfileTeamsSection(teams: mockTeams)
            .padding()
    }
}