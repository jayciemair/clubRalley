//
//  RosterView.swift
//  Club Ralley
//
//  Roster view displaying users in a grid layout with follow functionality
//

import SwiftUI

struct RosterView: View {
    @State private var users: [RosterUser] = RosterUser.mockUsers

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Roster")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "#2C4F40"))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach($users) { $user in
                            RosterUserCard(user: $user)
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 100)
                }
            }
            .background(Color(hex: "#F5F5F5"))
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Roster User Card

struct RosterUserCard: View {
    @Binding var user: RosterUser
    @State private var showingMessageAlert = false

    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: user.photoURL)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle().fill(Color(hex: "#2C4F40").opacity(0.2))
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            Text(user.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
                .lineLimit(1)

            Text(user.location)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
                .lineLimit(1)

            Text("\(user.mutuals) mutuals")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.gray)

            Spacer(minLength: 4)

            HStack(spacing: 8) {
                Button(action: { user.isFollowing.toggle() }) {
                    Text(user.isFollowing ? "Following" : "Follow")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(user.isFollowing ? .white : Color(hex: "#2C4F40"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(user.isFollowing ? Color(hex: "#2C4F40") : Color.white)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(hex: "#2C4F40"), lineWidth: 1)
                        )
                }

                Button(action: { showingMessageAlert = true }) {
                    Image(systemName: "message")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#2C4F40"))
                        .frame(width: 32, height: 32)
                        .background(Color.white)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(hex: "#2C4F40"), lineWidth: 1)
                        )
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        .alert("Coming Soon", isPresented: $showingMessageAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Direct messaging will be available in a future update.")
        }
    }
}

// MARK: - Roster User Model

struct RosterUser: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let photoURL: String
    let mutuals: Int
    var isFollowing: Bool

    static let mockUsers: [RosterUser] = [
        RosterUser(name: "Sam Marcus", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=201", mutuals: 21, isFollowing: false),
        RosterUser(name: "Gracie King", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=202", mutuals: 9, isFollowing: false),
        RosterUser(name: "Abby Smith", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=203", mutuals: 44, isFollowing: false),
        RosterUser(name: "Sarah Jay", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=204", mutuals: 9, isFollowing: false),
        RosterUser(name: "Maddie Moss", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=205", mutuals: 21, isFollowing: false),
        RosterUser(name: "Brandon Moss", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=206", mutuals: 44, isFollowing: false),
        RosterUser(name: "Jaycie Stone", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=207", mutuals: 9, isFollowing: false),
        RosterUser(name: "Whitney K", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=208", mutuals: 9, isFollowing: false),
        RosterUser(name: "Abby P", location: "Chicago, IL", photoURL: "https://picsum.photos/100/100?random=209", mutuals: 9, isFollowing: false)
    ]
}

#Preview {
    RosterView()
}
