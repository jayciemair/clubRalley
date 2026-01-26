//
//  AthleteVerificationScreen.swift
//  Club Ralley
//
//  Screen for athlete verification with photo upload and sport/school selection
//

import SwiftUI
import PhotosUI

struct AthleteVerificationScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController
    @State private var selectedSport: Sport?
    @State private var selectedSchool: School?
    @State private var searchText = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var verificationImage: UIImage?
    @State private var notes = ""
    @State private var showingSportPicker = false
    @State private var showingSchoolPicker = false
    @State private var isUploading = false
    
    // Mock data - in real app this would come from API
    @State private var availableSports: [Sport] = []
    @State private var availableSchools: [School] = []
    
    var body: some View {
        OnboardingScrollableLayout {
            VStack(spacing: 32) {
                // Header
                OnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: controller.currentStep.subtitle
                )
                
                VStack(spacing: 24) {
                    // Sport selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What sport do/did you play?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Button(action: { showingSportPicker = true }) {
                            HStack {
                                if let sport = selectedSport {
                                    HStack {
                                        Image(systemName: "sportscourt.fill")
                                            .foregroundColor(.blue)
                                        Text(sport.name)
                                            .foregroundColor(.primary)
                                    }
                                } else {
                                    HStack {
                                        Image(systemName: "sportscourt")
                                            .foregroundColor(.secondary)
                                        Text("Select your sport")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                    
                    // School selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What school do/did you attend?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Button(action: { showingSchoolPicker = true }) {
                            HStack {
                                if let school = selectedSchool {
                                    HStack {
                                        Image(systemName: "graduationcap.fill")
                                            .foregroundColor(.purple)
                                        VStack(alignment: .leading) {
                                            Text(school.name)
                                                .foregroundColor(.primary)
                                            Text("\(school.division.displayName) • \(school.state)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                } else {
                                    HStack {
                                        Image(systemName: "graduationcap")
                                            .foregroundColor(.secondary)
                                        Text("Select your school")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding(12)
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                    
                    // Photo upload
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upload verification photo")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Upload a photo that shows your athletic involvement (roster, team photo, athletic ID, etc.)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        PhotosPickerUploadView(
                            selectedPhoto: $selectedPhoto,
                            verificationImage: $verificationImage,
                            isUploading: $isUploading
                        )
                    }
                    
                    // Optional notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Additional notes (optional)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Add any additional context about your athletic background...", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(OnboardingTextFieldStyle())
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Continue button
                ContinueButton(
                    title: isUploading ? "Uploading..." : "Continue",
                    isEnabled: canContinue && !isUploading,
                    action: {
                        saveAndContinue()
                    }
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    controller.goToPreviousStep()
                }
            }
        }
        .sheet(isPresented: $showingSportPicker) {
            SportPickerView(
                sports: availableSports,
                selectedSport: $selectedSport
            )
        }
        .sheet(isPresented: $showingSchoolPicker) {
            SchoolPickerView(
                schools: availableSchools,
                selectedSchool: $selectedSchool
            )
        }
        .task {
            await loadMockData()
        }
        .onChange(of: selectedPhoto) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    verificationImage = image
                    await uploadImage(data)
                }
            }
        }
    }
    
    private var canContinue: Bool {
        selectedSport != nil && 
        selectedSchool != nil && 
        verificationImage != nil
    }
    
    private func loadMockData() async {
        // Mock sports data
        availableSports = [
            Sport(id: UUID(), name: "Basketball", category: .team, iconName: "basketball", isPopular: true),
            Sport(id: UUID(), name: "Football", category: .team, iconName: "football", isPopular: true),
            Sport(id: UUID(), name: "Soccer", category: .team, iconName: "soccer", isPopular: true),
            Sport(id: UUID(), name: "Tennis", category: .individual, iconName: "tennis", isPopular: true),
            Sport(id: UUID(), name: "Swimming", category: .individual, iconName: "swimming", isPopular: true),
            Sport(id: UUID(), name: "Track & Field", category: .individual, iconName: "track", isPopular: true),
            Sport(id: UUID(), name: "Baseball", category: .team, iconName: "baseball", isPopular: true),
            Sport(id: UUID(), name: "Volleyball", category: .team, iconName: "volleyball", isPopular: true)
        ]
        
        // Mock schools data
        availableSchools = [
            School(id: UUID(), name: "University of California, Los Angeles", state: "CA", division: .d1, conference: "Pac-12", logoURL: nil),
            School(id: UUID(), name: "Stanford University", state: "CA", division: .d1, conference: "Pac-12", logoURL: nil),
            School(id: UUID(), name: "University of Southern California", state: "CA", division: .d1, conference: "Pac-12", logoURL: nil),
            School(id: UUID(), name: "Duke University", state: "NC", division: .d1, conference: "ACC", logoURL: nil),
            School(id: UUID(), name: "University of North Carolina", state: "NC", division: .d1, conference: "ACC", logoURL: nil),
            School(id: UUID(), name: "Harvard University", state: "MA", division: .d1, conference: "Ivy League", logoURL: nil)
        ]
    }
    
    private func uploadImage(_ data: Data) async {
        isUploading = true
        
        do {
            let imageURL = try await controller.uploadVerificationImage(data)
            // Store the uploaded URL (in real app)
        } catch {
            // Handle upload error
            print("Failed to upload image: \(error)")
        }
        
        isUploading = false
    }
    
    private func saveAndContinue() {
        guard let sport = selectedSport,
              let school = selectedSchool else { return }
        
        controller.updateAthleteVerification(
            sport: sport,
            school: school,
            verificationImageURL: "mock-uploaded-url",
            notes: notes
        )
        controller.goToNextStep()
    }
}

// MARK: - Photo Upload Component

struct PhotosPickerUploadView: View {
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var verificationImage: UIImage?
    @Binding var isUploading: Bool
    
    var body: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            VStack(spacing: 16) {
                if let image = verificationImage {
                    // Show selected image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                    
                    if isUploading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Uploading...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Tap to change photo")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                } else {
                    // Upload placeholder
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [8]))
                                .frame(height: 120)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title)
                                    .foregroundColor(.blue)
                                
                                Text("Upload Photo")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text("Accepted formats: JPG, PNG, HEIC")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Sport Picker

struct SportPickerView: View {
    let sports: [Sport]
    @Binding var selectedSport: Sport?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(sports) { sport in
                Button(action: {
                    selectedSport = sport
                    dismiss()
                }) {
                    HStack {
                        Text(sport.name)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedSport?.id == sport.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Sport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - School Picker

struct SchoolPickerView: View {
    let schools: [School]
    @Binding var selectedSchool: School?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredSchools: [School] {
        if searchText.isEmpty {
            return schools
        } else {
            return schools.filter { school in
                school.name.localizedCaseInsensitiveContains(searchText) ||
                school.state.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredSchools) { school in
                Button(action: {
                    selectedSchool = school
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(school.name)
                            .foregroundColor(.primary)
                        
                        Text("\(school.division.displayName) • \(school.state)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let conference = school.conference {
                            Text(conference)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    if selectedSchool?.id == school.id {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Select School")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search schools...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct AthleteVerificationScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AthleteVerificationScreen()
                .environmentObject(ClubRalleyOnboardingController())
        }
    }
}