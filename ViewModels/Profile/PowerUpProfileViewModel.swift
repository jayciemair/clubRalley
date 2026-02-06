//
//  PowerUpProfileViewModel.swift
//  Club Ralley
//
//  Shared state for Power Up Profile wizard flow
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PowerUpProfileViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentStep: PowerUpStep = .rosterPhoto
    @Published var data: PowerUpProfileData = PowerUpProfileData()
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var error: String?
    @Published var showError: Bool = false
    @Published var isComplete: Bool = false

    // Sports list for selection
    @Published var availableSports: [Sport] = []

    // MARK: - Dependencies

    private let powerUpService = PowerUpProfileService()
    private let imageUploadService = ImageUploadService.shared
    private let supabase = SupabaseManager.shared

    // MARK: - Computed Properties

    var canGoBack: Bool {
        currentStep.rawValue > 0
    }

    var canGoForward: Bool {
        currentStep.rawValue < PowerUpStep.allCases.count - 1
    }

    var isFirstStep: Bool {
        currentStep == .rosterPhoto
    }

    var isLastStep: Bool {
        currentStep == .funQuestions
    }

    var continueButtonText: String {
        if isLastStep {
            return "Complete"
        }
        // Photo step allows skipping
        if currentStep == .rosterPhoto && data.profilePhotoData == nil && data.profilePhotoURL == nil {
            return "Skip"
        }
        return "Continue"
    }

    var progress: Double {
        currentStep.progressValue
    }

    // MARK: - Initialization

    init() {
        Task {
            await loadExistingData()
            await loadSports()
        }
    }

    // MARK: - Navigation

    func goToNextStep() {
        guard canGoForward else {
            completeFlow()
            return
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = PowerUpStep(rawValue: currentStep.rawValue + 1) ?? currentStep
        }
    }

    func goToPreviousStep() {
        guard canGoBack else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = PowerUpStep(rawValue: currentStep.rawValue - 1) ?? currentStep
        }
    }

    func goToStep(_ step: PowerUpStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }

    // MARK: - Data Loading

    func loadExistingData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let existingData = try await powerUpService.loadExistingProfileData()
            data = existingData
            print("PowerUpProfileViewModel: Loaded existing profile data")
        } catch {
            print("PowerUpProfileViewModel: Failed to load existing data: \(error)")
            // Continue with empty data - user can fill in fresh
        }
    }

    func loadSports() async {
        // Lean schema doesn't have a sports table - use default sports list
        availableSports = defaultSports
        print("PowerUpProfileViewModel: Loaded \(availableSports.count) default sports")
    }

    // MARK: - Photo Management

    func updatePhoto(_ imageData: Data) async {
        isLoading = true
        defer { isLoading = false }

        data.profilePhotoData = imageData

        // Upload immediately so we have URL
        guard let userId = supabase.currentUser?.id else { return }

        do {
            let url = try await imageUploadService.uploadProfilePhoto(imageData: imageData, userId: userId)
            data.profilePhotoURL = url
            print("PowerUpProfileViewModel: Photo uploaded: \(url)")
        } catch {
            self.error = "Failed to upload photo: \(error.localizedDescription)"
            self.showError = true
        }
    }

    func removePhoto() {
        data.profilePhotoData = nil
        data.profilePhotoURL = nil
    }

    // MARK: - Sports Management

    func toggleSport(_ sport: Sport) {
        if let index = data.sportsWithSkills.firstIndex(where: { $0.sport.id == sport.id }) {
            data.sportsWithSkills.remove(at: index)
        } else {
            let sportWithSkill = SportWithSkill(sport: sport, skillLevel: .competitor)
            data.sportsWithSkills.append(sportWithSkill)
        }
    }

    func isSportSelected(_ sport: Sport) -> Bool {
        data.sportsWithSkills.contains { $0.sport.id == sport.id }
    }

    func updateSkillLevel(for sportId: UUID, to level: PowerUpSkillLevel) {
        if let index = data.sportsWithSkills.firstIndex(where: { $0.sport.id == sportId }) {
            data.sportsWithSkills[index].skillLevel = level
        }
    }

    // MARK: - Day Selection

    func toggleDay(_ day: Int) {
        if data.selectedDays.contains(day) {
            data.selectedDays.remove(day)
        } else {
            data.selectedDays.insert(day)
        }
        // Switch to specific days mode when manually selecting
        data.daySelection = .specificDays
    }

    func selectDayOption(_ option: DaySelection) {
        data.daySelection = option
        // Clear specific days when choosing preset
        if option != .specificDays {
            data.selectedDays.removeAll()
        }
    }

    // MARK: - Tag Selection (Brands & Classes)

    func toggleWorkoutBrand(_ brand: String) {
        if let index = data.workoutBrands.firstIndex(of: brand) {
            data.workoutBrands.remove(at: index)
        } else {
            data.workoutBrands.append(brand)
        }
    }

    func toggleWorkoutClass(_ classType: String) {
        if let index = data.workoutClasses.firstIndex(of: classType) {
            data.workoutClasses.remove(at: index)
        } else {
            data.workoutClasses.append(classType)
        }
    }

    // MARK: - Save & Complete

    func completeFlow() {
        Task {
            await saveAllData()
        }
    }

    func saveAllData() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await powerUpService.saveProfileData(data)
            isComplete = true
            print("PowerUpProfileViewModel: Profile data saved successfully")
        } catch {
            self.error = "Failed to save profile: \(error.localizedDescription)"
            self.showError = true
            print("PowerUpProfileViewModel: Failed to save: \(error)")
        }
    }

    // MARK: - Default Sports (Fallback)

    private var defaultSports: [Sport] {
        [
            Sport(id: UUID(), name: "Basketball", category: .team, iconName: "basketball.fill", isPopular: true),
            Sport(id: UUID(), name: "Football", category: .team, iconName: "football.fill", isPopular: true),
            Sport(id: UUID(), name: "Soccer", category: .team, iconName: "soccerball", isPopular: true),
            Sport(id: UUID(), name: "Tennis", category: .individual, iconName: "tennisball.fill", isPopular: true),
            Sport(id: UUID(), name: "Running", category: .individual, iconName: "figure.run", isPopular: true),
            Sport(id: UUID(), name: "Swimming", category: .waterSports, iconName: "figure.pool.swim", isPopular: true),
            Sport(id: UUID(), name: "Volleyball", category: .team, iconName: "volleyball.fill", isPopular: true),
            Sport(id: UUID(), name: "Golf", category: .individual, iconName: "figure.golf", isPopular: false),
            Sport(id: UUID(), name: "Cycling", category: .individual, iconName: "bicycle", isPopular: false),
            Sport(id: UUID(), name: "Yoga", category: .fitness, iconName: "figure.yoga", isPopular: true),
            Sport(id: UUID(), name: "Boxing", category: .combatSports, iconName: "figure.boxing", isPopular: false),
            Sport(id: UUID(), name: "Hiking", category: .recreational, iconName: "figure.hiking", isPopular: true)
        ]
    }
}
