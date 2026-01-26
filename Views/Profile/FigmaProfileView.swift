//
//  FigmaProfileView.swift
//  Club Ralley
//
//  Profile view matching Figma design exactly
//

import SwiftUI

struct FigmaProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    ProfileHeaderSection()
                    
                    // Profile Info Section
                    ProfileInfoSection()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    
                    // Action Buttons
                    ActionButtonsSection()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    
                    // My Teams Section
                    MyTeamsSection()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    
                    // My Pics Section
                    MyPicsSection()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100) // Space for tab bar
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.loadGracieProfile()
        }
    }
}

// MARK: - Header Section

struct ProfileHeaderSection: View {
    var body: some View {
        HStack {
            // Back Button
            Button(action: {
                // Navigate back
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            // Profile Photo (smaller in header)
            AsyncImage(url: URL(string: "https://picsum.photos/60/60?random=50")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color(hex: "#2C4F40"))
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            
            Spacer()
            
            // Location
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text("Chicago, IL")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

// MARK: - Profile Info Section

struct ProfileInfoSection: View {
    var body: some View {
        VStack(spacing: 16) {
            // Name
            Text("Gracie King")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            
            // Social Handles (matching Figma icons)
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    Text("@Gking")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    Text("@gracieking24")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.gray)
                }
            }
            
            // Stats Row (more compact like Figma)
            HStack(spacing: 4) {
                Group {
                    Text("130")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    Text("followers")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                    
                    Text("20")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    Text("games played")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                    
                    Text("10")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    Text("wins")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                }
            }
            
            // Bio
            Text("Former D1 tennis player at Bucknell University\nClass of 2025")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            // Mutual Friends (matching Figma layout)
            VStack(spacing: 12) {
                Text("Also friends with")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.gray)
                
                HStack(spacing: -10) {
                    ForEach(0..<3, id: \.self) { index in
                        AsyncImage(url: URL(string: "https://picsum.photos/36/36?random=\(index + 100)")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color(hex: "#2C4F40").opacity(0.3))
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2.5)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Action Buttons Section

struct ActionButtonsSection: View {
    var body: some View {
        HStack(spacing: 16) {
            // Follow Button (primary)
            Button(action: {
                // Handle follow
            }) {
                Text("Follow")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#2C4F40"))
                    .cornerRadius(10)
            }
            
            // Message Button (secondary)
            Button(action: {
                // Handle message
            }) {
                Text("Message")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#2C4F40"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#2C4F40"), lineWidth: 1.5)
                    )
            }
        }
    }
}

// MARK: - My Teams Section

struct MyTeamsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Title
            HStack {
                Text("My Teams")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
            }
            
            // Team Cards
            HStack(spacing: 12) {
                // AVS Club Card
                VStack(spacing: 0) {
                    AsyncImage(url: URL(string: "https://picsum.photos/160/120?random=201")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(hex: "#2C4F40").opacity(0.1))
                    }
                    .frame(height: 120)
                    .clipped()
                    
                    VStack(spacing: 4) {
                        Text("AVS Club")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .frame(maxWidth: .infinity)
                
                // Basketball Club Card
                VStack(spacing: 0) {
                    AsyncImage(url: URL(string: "https://picsum.photos/160/120?random=202")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(hex: "#2C4F40").opacity(0.1))
                    }
                    .frame(height: 120)
                    .clipped()
                    
                    VStack(spacing: 4) {
                        Text("Basketball Club")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - My Pics Section

struct MyPicsSection: View {
    let photos = Array(1...4)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Title
            HStack {
                Text("My Pics")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
            }
            
            // Photo Grid (2x2)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(photos, id: \.self) { index in
                    AsyncImage(url: URL(string: "https://picsum.photos/180/180?random=\(index + 300)")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color(hex: "#2C4F40").opacity(0.1))
                    }
                    .frame(height: 180)
                    .clipped()
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Preview

struct FigmaProfileView_Previews: PreviewProvider {
    static var previews: some View {
        FigmaProfileView()
    }
}