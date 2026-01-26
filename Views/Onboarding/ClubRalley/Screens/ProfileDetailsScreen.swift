//
//  ProfileDetailsScreen.swift
//  Club Ralley
//
//  Profile details screen for date of birth, gender, and location
//

import SwiftUI

struct ProfileDetailsScreen: View {
    @EnvironmentObject var controller: ClubRalleyOnboardingController
    @State private var birthMonth = 1
    @State private var birthYear = 2000
    @State private var selectedGender: Gender?
    @State private var city = ""
    @State private var selectedState = ""
    @State private var bio = ""
    @State private var instagramHandle = ""
    
    private let months = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    
    private let states = [
        "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
        "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
        "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
        "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
        "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"
    ]
    
    var body: some View {
        OnboardingScrollableLayout {
            VStack(spacing: 32) {
                // Header
                OnboardingHeader(
                    title: controller.currentStep.title,
                    subtitle: controller.currentStep.subtitle
                )
                
                VStack(spacing: 24) {
                    // Date of Birth
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Date of Birth")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            // Month picker
                            Menu {
                                ForEach(1...12, id: \.self) { month in
                                    Button(months[month - 1]) {
                                        birthMonth = month
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(months[birthMonth - 1])
                                        .foregroundColor(.primary)
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
                            
                            // Year picker
                            Menu {
                                ForEach((1960...2010).reversed(), id: \.self) { year in
                                    Button(String(year)) {
                                        birthYear = year
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(String(birthYear))
                                        .foregroundColor(.primary)
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
                            .frame(width: 80)
                        }
                    }
                    
                    // Gender
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gender")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 8) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                GenderSelectionRow(
                                    gender: gender,
                                    isSelected: selectedGender == gender,
                                    onTap: { selectedGender = gender }
                                )
                            }
                        }
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Location")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            OnboardingTextField(
                                title: "",
                                placeholder: "City",
                                text: $city,
                                autocapitalization: .words
                            )
                            
                            Menu {
                                ForEach(states, id: \.self) { state in
                                    Button(state) {
                                        selectedState = state
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedState.isEmpty ? "State" : selectedState)
                                        .foregroundColor(selectedState.isEmpty ? .secondary : .primary)
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
                            .frame(width: 80)
                        }
                    }
                    
                    // Bio (optional)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bio (optional)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Tell people a bit about yourself...", text: $bio, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(OnboardingTextFieldStyle())
                    }
                    
                    // Instagram handle (optional)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instagram Handle (optional)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("@")
                                .foregroundColor(.secondary)
                                .padding(.leading, 12)
                            
                            TextField("username", text: $instagramHandle)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        .padding(.vertical, 12)
                        .padding(.trailing, 12)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Continue button
                ContinueButton(
                    title: "Continue",
                    isEnabled: canContinue,
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
        .onAppear {
            // Pre-populate if data exists
            let profile = controller.onboardingData.profile
            if let dob = profile.dateOfBirth {
                birthMonth = dob.month
                birthYear = dob.year
            }
            selectedGender = profile.gender
            city = profile.city
            selectedState = profile.state
            bio = profile.bio
            instagramHandle = profile.instagramHandle
        }
    }
    
    private var canContinue: Bool {
        selectedGender != nil &&
        !city.isEmpty &&
        !selectedState.isEmpty
    }
    
    private func saveAndContinue() {
        guard let gender = selectedGender else { return }
        
        let dateOfBirth = DateOfBirth(month: birthMonth, year: birthYear)
        
        controller.updateProfileDetails(
            dateOfBirth: dateOfBirth,
            gender: gender,
            city: city,
            state: selectedState,
            bio: bio,
            instagram: instagramHandle
        )
        controller.goToNextStep()
    }
}

// MARK: - Gender Selection Row

struct GenderSelectionRow: View {
    let gender: Gender
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(gender.displayName)
                    .foregroundColor(.primary)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color(.systemGray5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct ProfileDetailsScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileDetailsScreen()
                .environmentObject(ClubRalleyOnboardingController())
        }
    }
}