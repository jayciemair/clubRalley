//
//  CityPickerSheet.swift
//  Club Ralley
//
//  Sheet for selecting a city on the map
//

import SwiftUI

// MARK: - City Picker Sheet

struct CityPickerSheet: View {
    @ObservedObject var viewModel: MapViewModel
    @Environment(\.dismiss) private var dismiss

    private let darkGreen = Color(hex: "#2C4F40")

    var body: some View {
        NavigationStack {
            List(MapCity.available) { city in
                Button(action: {
                    viewModel.selectCity(city)
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(city.name)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(ClubRalleyTheme.Colors.darkGreen)
                            Text(city.state)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if city.id == viewModel.selectedCity.id {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(darkGreen)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Select City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(darkGreen)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
