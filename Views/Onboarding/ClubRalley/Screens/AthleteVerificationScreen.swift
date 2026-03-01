//
//  AthleteVerificationScreen.swift
//  Club Ralley
//
//  Screen for athlete verification with sport/school selection and photo upload
//

import SwiftUI
import PhotosUI

struct AthleteVerificationScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController
    @State private var selectedSport: Sport?
    @State private var selectedSchool: School?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var verificationImage: UIImage?
    @State private var notes = ""
    @State private var isUploading = false
    @State private var uploadedImageURL: String?
    @State private var showingSportPicker = false
    @State private var showingSchoolPicker = false

    private var canContinue: Bool {
        selectedSport != nil && selectedSchool != nil && !isUploading
    }

    var body: some View {
        ClubRalleyScrollableLayout(
            canGoBack: controller.canGoBack,
            onBack: { controller.goToPreviousStep() },
            onContinue: { saveAndContinue() },
            continueEnabled: canContinue,
            continueText: isUploading ? "Uploading..." : "Continue"
        ) {
            VStack(spacing: 32) {
                ClubRalleyOnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: controller.currentStep.subtitle
                )

                VStack(spacing: 24) {
                    // Sport selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What sport did you play?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                            .padding(.horizontal, 24)

                        Button(action: { showingSportPicker = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: selectedSport != nil ? "sportscourt.fill" : "sportscourt")
                                    .font(.system(size: 18))
                                    .foregroundColor(selectedSport != nil ? Color(hex: "#2C4F40") : .gray)

                                Text(selectedSport?.name ?? "Select your sport")
                                    .font(.system(size: 17))
                                    .foregroundColor(selectedSport != nil ? .primary : .gray)

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedSport != nil ? Color(hex: "#2C4F40") : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 24)
                    }

                    // School selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What school did you attend?")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                            .padding(.horizontal, 24)

                        Button(action: { showingSchoolPicker = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: selectedSchool != nil ? "graduationcap.fill" : "graduationcap")
                                    .font(.system(size: 18))
                                    .foregroundColor(selectedSchool != nil ? Color(hex: "#2C4F40") : .gray)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selectedSchool?.name ?? "Select your school")
                                        .font(.system(size: 17))
                                        .foregroundColor(selectedSchool != nil ? .primary : .gray)

                                    if let school = selectedSchool {
                                        Text("\(school.division.displayName) \u{2022} \(school.state)")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedSchool != nil ? Color(hex: "#2C4F40") : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 24)
                    }

                    // Photo upload
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Verification photo")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                            .padding(.horizontal, 24)

                        Text("Upload a roster, team photo, or athletic ID")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 24)

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Group {
                                if let image = verificationImage {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 140)
                                            .clipped()
                                            .cornerRadius(12)

                                        if isUploading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .padding(8)
                                                .background(Color.black.opacity(0.5))
                                                .cornerRadius(8)
                                                .padding(8)
                                        }
                                    }
                                } else {
                                    VStack(spacing: 10) {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 28))
                                            .foregroundColor(Color(hex: "#2C4F40"))

                                        Text("Tap to upload")
                                            .font(.system(size: 15))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 120)
                                    .background(Color.gray.opacity(0.06))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6]))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Optional notes
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Additional notes")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                            Spacer()
                            Text("Optional")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 24)

                        TextField("Any context about your athletic background...", text: $notes, axis: .vertical)
                            .font(.system(size: 15))
                            .lineLimit(3...5)
                            .padding(14)
                            .background(Color.gray.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .padding(.horizontal, 24)
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.top, 20)
        }
        .sheet(isPresented: $showingSportPicker) {
            AthleteVerificationSportPicker(
                selectedSport: $selectedSport
            )
        }
        .sheet(isPresented: $showingSchoolPicker) {
            AthleteVerificationSchoolPicker(
                selectedSchool: $selectedSchool
            )
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    verificationImage = image
                    await uploadImage(data)
                }
            }
        }
    }

    private func uploadImage(_ data: Data) async {
        isUploading = true
        do {
            let imageURL = try await controller.uploadVerificationImage(data)
            uploadedImageURL = imageURL
        } catch {
            print("AthleteVerificationScreen: Failed to upload image: \(error)")
        }
        isUploading = false
    }

    private func saveAndContinue() {
        guard let sport = selectedSport, let school = selectedSchool else { return }
        controller.updateAthleteVerification(
            sport: sport,
            school: school,
            verificationImageURL: uploadedImageURL,
            notes: notes
        )
        controller.goToNextStep()
    }
}

// MARK: - Sport Picker

private struct AthleteVerificationSportPicker: View {
    @Binding var selectedSport: Sport?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private let sports = DefaultSports.all

    private var filteredSports: [Sport] {
        if searchText.isEmpty { return sports }
        return sports.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filteredSports) { sport in
                Button {
                    selectedSport = sport
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: sport.iconName)
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "#2C4F40"))
                            .frame(width: 28)

                        Text(sport.name)
                            .foregroundColor(.primary)

                        Spacer()

                        if selectedSport?.id == sport.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#2C4F40"))
                        }
                    }
                }
            }
            .navigationTitle("Select Sport")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search sports...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
    }
}

// MARK: - School Picker

private struct AthleteVerificationSchoolPicker: View {
    @Binding var selectedSchool: School?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    // Common colleges — in a real app this would come from an API
    private let schools: [School] = [
        School(id: UUID(), name: "University of Alabama", state: "AL", division: .d1, conference: "SEC", logoURL: nil),
        School(id: UUID(), name: "Arizona State University", state: "AZ", division: .d1, conference: "Big 12", logoURL: nil),
        School(id: UUID(), name: "Auburn University", state: "AL", division: .d1, conference: "SEC", logoURL: nil),
        School(id: UUID(), name: "Boston College", state: "MA", division: .d1, conference: "ACC", logoURL: nil),
        School(id: UUID(), name: "Clemson University", state: "SC", division: .d1, conference: "ACC", logoURL: nil),
        School(id: UUID(), name: "Duke University", state: "NC", division: .d1, conference: "ACC", logoURL: nil),
        School(id: UUID(), name: "Florida State University", state: "FL", division: .d1, conference: "ACC", logoURL: nil),
        School(id: UUID(), name: "Georgetown University", state: "DC", division: .d1, conference: "Big East", logoURL: nil),
        School(id: UUID(), name: "Harvard University", state: "MA", division: .d1, conference: "Ivy League", logoURL: nil),
        School(id: UUID(), name: "Indiana University", state: "IN", division: .d1, conference: "Big Ten", logoURL: nil),
        School(id: UUID(), name: "LSU", state: "LA", division: .d1, conference: "SEC", logoURL: nil),
        School(id: UUID(), name: "Michigan State University", state: "MI", division: .d1, conference: "Big Ten", logoURL: nil),
        School(id: UUID(), name: "Northwestern University", state: "IL", division: .d1, conference: "Big Ten", logoURL: nil),
        School(id: UUID(), name: "Ohio State University", state: "OH", division: .d1, conference: "Big Ten", logoURL: nil),
        School(id: UUID(), name: "Penn State University", state: "PA", division: .d1, conference: "Big Ten", logoURL: nil),
        School(id: UUID(), name: "Stanford University", state: "CA", division: .d1, conference: "ACC", logoURL: nil),
        School(id: UUID(), name: "UCLA", state: "CA", division: .d1, conference: "Big Ten", logoURL: nil),
        School(id: UUID(), name: "University of Florida", state: "FL", division: .d1, conference: "SEC", logoURL: nil),
        School(id: UUID(), name: "University of Georgia", state: "GA", division: .d1, conference: "SEC", logoURL: nil),
        School(id: UUID(), name: "University of Michigan", state: "MI", division: .d1, conference: "Big Ten", logoURL: nil),
        School(id: UUID(), name: "University of North Carolina", state: "NC", division: .d1, conference: "ACC", logoURL: nil),
        School(id: UUID(), name: "University of Oregon", state: "OR", division: .d1, conference: "Big Ten", logoURL: nil),
        School(id: UUID(), name: "University of Southern California", state: "CA", division: .d1, conference: "Big Ten", logoURL: nil),
        School(id: UUID(), name: "University of Texas", state: "TX", division: .d1, conference: "SEC", logoURL: nil),
        School(id: UUID(), name: "University of Virginia", state: "VA", division: .d1, conference: "ACC", logoURL: nil),
        School(id: UUID(), name: "University of Wisconsin", state: "WI", division: .d1, conference: "Big Ten", logoURL: nil),
        School(id: UUID(), name: "Vanderbilt University", state: "TN", division: .d1, conference: "SEC", logoURL: nil),
        School(id: UUID(), name: "Villanova University", state: "PA", division: .d1, conference: "Big East", logoURL: nil),
        School(id: UUID(), name: "Wake Forest University", state: "NC", division: .d1, conference: "ACC", logoURL: nil),
        School(id: UUID(), name: "Yale University", state: "CT", division: .d1, conference: "Ivy League", logoURL: nil)
    ]

    private var filteredSchools: [School] {
        if searchText.isEmpty { return schools }
        return schools.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.state.localizedCaseInsensitiveContains(searchText) ||
            ($0.conference?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredSchools) { school in
                Button {
                    selectedSchool = school
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(school.name)
                                .foregroundColor(.primary)
                                .font(.system(size: 16))

                            HStack(spacing: 6) {
                                Text(school.division.displayName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "#2C4F40"))

                                if let conference = school.conference {
                                    Text("\u{2022} \(conference)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }

                                Text("\u{2022} \(school.state)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }

                        Spacer()

                        if selectedSchool?.id == school.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#2C4F40"))
                        }
                    }
                }
            }
            .navigationTitle("Select School")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search schools...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
    }
}
