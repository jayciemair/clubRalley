//
//  FindRalleysView.swift
//  Club Ralley
//
//  View for discovering and browsing nearby ralleys (pickup games).
//

import SwiftUI

// MARK: - Find Ralleys View

struct FindRalleysView: View {
    @EnvironmentObject var ralleyManager: RalleyManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "sportscourt.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(hex: "#2C4F40"))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Find Ralleys")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.black)
                                Text("Join pickup games near you")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }

                    // Quick Actions
                    HStack(spacing: 16) {
                        // Create Ralley Button
                        Button(action: {
                            ralleyManager.showingCreateRalley = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("Create Ralley")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#2C4F40"), Color(hex: "#3A6B4F")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color(hex: "#2C4F40").opacity(0.3), radius: 8, x: 0, y: 4)
                        }

                        // Filter Button
                        Button(action: {}) {
                            HStack(spacing: 8) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 16))
                                Text("Filter")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "#2C4F40"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "#2C4F40"), lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Nearby Ralleys
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Nearby Ralleys")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                            Spacer()
                            Text("2.5 mi")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 24)

                        // Ralley Cards
                        if ralleyManager.ralleys.isEmpty {
                            EmptyRalleysView()
                        } else {
                            VStack(spacing: 16) {
                                ForEach(ralleyManager.ralleys) { ralley in
                                    RalleyCardView(ralley: ralley)
                                        .environmentObject(ralleyManager)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }

                    Spacer(minLength: 100)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $ralleyManager.showingCreateRalley) {
                RalleyCreationView()
                    .environmentObject(ralleyManager)
            }
        }
    }
}

// MARK: - Ralley Card View

struct RalleyCardView: View {
    let ralley: ClubRalley
    @EnvironmentObject var ralleyManager: RalleyManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: ralley.organizer.photoURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(hex: "#2C4F40"))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(ralley.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    Text("\(ralley.dateTime.formatted(date: .omitted, time: .shortened)) • \(ralley.currentPlayers)/\(ralley.maxPlayers) players")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: ralley.sport.lowercased() == "basketball" ? "basketball.fill" : "tennisball.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#2C4F40"))
            }
            .padding(16)

            // Location & Details
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Text(ralley.location.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gray)
                Spacer()
                Text(ralley.cost == 0 ? "FREE" : "$\(ralley.cost)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#2C4F40"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#2C4F40").opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 16)

            // Join Button
            Button(action: {
                Task {
                    await ralleyManager.joinRalley(ralley.id)
                }
            }) {
                Text(ralley.currentPlayers >= ralley.maxPlayers ? "Full" : "Join Ralley")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ralley.currentPlayers >= ralley.maxPlayers ? .gray : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        ralley.currentPlayers >= ralley.maxPlayers
                            ? Color.gray.opacity(0.3)
                            : Color(hex: "#2C4F40")
                    )
                    .cornerRadius(10)
            }
            .disabled(ralley.currentPlayers >= ralley.maxPlayers)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Empty Ralleys View

struct EmptyRalleysView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sportscourt")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#2C4F40").opacity(0.6))

            Text("No ralleys nearby")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)

            Text("Be the first to create a pickup game in your area!")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
    }
}
