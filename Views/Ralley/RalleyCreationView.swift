//
//  RalleyCreationView.swift
//  Club Ralley
//
//  Form view for creating new ralleys (pickup games).
//

import SwiftUI

// MARK: - Ralley Creation View

struct RalleyCreationView: View {
    @EnvironmentObject var ralleyManager: RalleyManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var sport = ""
    @State private var selectedDate = Date()
    @State private var locationName = ""
    @State private var maxPlayers = 4
    @State private var cost = 0
    @State private var description = ""
    @State private var requirements = ""
    @State private var isCreating = false
    @State private var showingSuccessMessage = false

    // Privacy settings
    @State private var visibility: RalleyVisibility = .anyone
    @State private var joinType: RalleyJoinType = .open

    var canCreate: Bool {
        !title.isEmpty && !sport.isEmpty && !locationName.isEmpty && maxPlayers > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Create New Ralley")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.top, 8)

                    VStack(spacing: 20) {
                        // Basic Info
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Basic Information")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)

                            VStack(spacing: 12) {
                                TextField("Ralley title (e.g. Basketball Pickup)", text: $title)
                                    .textFieldStyle(CustomTextFieldStyle())

                                TextField("Sport (e.g. Basketball, Tennis)", text: $sport)
                                    .textFieldStyle(CustomTextFieldStyle())

                                DatePicker("Date & Time", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                    .font(.system(size: 16, weight: .medium))
                                    .padding(.vertical, 8)
                            }
                        }

                        // Location & Players
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Location & Players")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)

                            VStack(spacing: 12) {
                                TextField("Location name (e.g. Central Park Courts)", text: $locationName)
                                    .textFieldStyle(CustomTextFieldStyle())

                                HStack {
                                    Text("Max Players:")
                                        .font(.system(size: 16, weight: .medium))
                                    Spacer()
                                    Stepper(value: $maxPlayers, in: 2...20) {
                                        Text("\(maxPlayers)")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color(hex: "#2C4F40"))
                                    }
                                }
                                .padding(.vertical, 8)

                                HStack {
                                    Text("Cost per person:")
                                        .font(.system(size: 16, weight: .medium))
                                    Spacer()
                                    Stepper(value: $cost, in: 0...100, step: 5) {
                                        Text(cost == 0 ? "FREE" : "$\(cost)")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color(hex: "#2C4F40"))
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }

                        // Additional Details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Additional Details")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)

                            VStack(spacing: 12) {
                                TextField("Description (optional)", text: $description, axis: .vertical)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .lineLimit(3, reservesSpace: false)

                                TextField("Requirements (optional)", text: $requirements, axis: .vertical)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .lineLimit(2, reservesSpace: false)
                            }
                        }

                        // Privacy Settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Privacy Settings")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)

                            VStack(spacing: 12) {
                                // Visibility Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Who can see this ralley?")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)

                                    ForEach(RalleyVisibility.allCases, id: \.self) { option in
                                        Button(action: { visibility = option }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: option.iconName)
                                                    .font(.system(size: 16))
                                                    .foregroundColor(visibility == option ? .white : Color(hex: "#2C4F40"))
                                                    .frame(width: 32, height: 32)
                                                    .background(visibility == option ? Color(hex: "#2C4F40") : Color.gray.opacity(0.1))
                                                    .cornerRadius(8)

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(option.displayName)
                                                        .font(.system(size: 15, weight: .medium))
                                                        .foregroundColor(.black)
                                                    Text(option.description)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.gray)
                                                }

                                                Spacer()

                                                if visibility == option {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(Color(hex: "#2C4F40"))
                                                }
                                            }
                                            .padding(12)
                                            .background(visibility == option ? Color(hex: "#2C4F40").opacity(0.1) : Color.gray.opacity(0.05))
                                            .cornerRadius(12)
                                        }
                                    }
                                }

                                Divider().padding(.vertical, 4)

                                // Join Type Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("How can people join?")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)

                                    ForEach(RalleyJoinType.allCases, id: \.self) { option in
                                        Button(action: { joinType = option }) {
                                            HStack(spacing: 12) {
                                                Image(systemName: option.iconName)
                                                    .font(.system(size: 16))
                                                    .foregroundColor(joinType == option ? .white : Color(hex: "#2C4F40"))
                                                    .frame(width: 32, height: 32)
                                                    .background(joinType == option ? Color(hex: "#2C4F40") : Color.gray.opacity(0.1))
                                                    .cornerRadius(8)

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(option.displayName)
                                                        .font(.system(size: 15, weight: .medium))
                                                        .foregroundColor(.black)
                                                    Text(option.description)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.gray)
                                                }

                                                Spacer()

                                                if joinType == option {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(Color(hex: "#2C4F40"))
                                                }
                                            }
                                            .padding(12)
                                            .background(joinType == option ? Color(hex: "#2C4F40").opacity(0.1) : Color.gray.opacity(0.05))
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                        }

                        // Create Button
                        Button(action: {
                            createRalley()
                        }) {
                            HStack(spacing: 8) {
                                if isCreating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                Text(isCreating ? "Creating..." : "Create Ralley")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                canCreate
                                    ? Color(hex: "#2C4F40")
                                    : Color.gray.opacity(0.3)
                            )
                            .cornerRadius(12)
                            .shadow(color: Color(hex: "#2C4F40").opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(!canCreate || isCreating)
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
        .overlay(
            Group {
                if showingSuccessMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            Text("Ralley created successfully!")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#2C4F40"))
                        .cornerRadius(25)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingSuccessMessage)
                }
            }
        )
    }

    private func createRalley() {
        guard canCreate && !isCreating else { return }

        isCreating = true

        Task { @MainActor in
            await ralleyManager.createRalley(
                title: title,
                sport: sport,
                dateTime: selectedDate,
                locationName: locationName,
                address: "",
                city: "San Francisco",
                state: "CA",
                maxPlayers: maxPlayers,
                cost: Double(cost),
                description: description.isEmpty ? "Join us for a fun game of \(sport)!" : description,
                requirements: requirements,
                visibility: visibility,
                joinType: joinType
            )

            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            showingSuccessMessage = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showingSuccessMessage = false
                dismiss()
            }

            isCreating = false
        }
    }
}

// MARK: - Custom Text Field Style

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
}
