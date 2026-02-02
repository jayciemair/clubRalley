//
//  RalleyFilterSheet.swift
//  Club Ralley
//
//  Filter sheet for ralley discovery
//

import SwiftUI

// MARK: - Date Filter Enum

enum DateFilter: String, CaseIterable {
    case all = "all"
    case today = "today"
    case thisWeek = "this_week"
    case thisMonth = "this_month"

    var displayName: String {
        switch self {
        case .all: return "All Dates"
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        }
    }
}

// MARK: - Ralley Filter Sheet

struct RalleyFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSport: String?
    @Binding var selectedDate: DateFilter

    var body: some View {
        NavigationStack {
            List {
                // Sport Section
                Section("Sport") {
                    Button(action: { selectedSport = nil }) {
                        HStack {
                            Text("All Sports")
                            Spacer()
                            if selectedSport == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "#2C4F40"))
                            }
                        }
                    }
                    .foregroundColor(.primary)

                    ForEach(RalleySport.supportedSports) { sport in
                        Button(action: { selectedSport = sport.name }) {
                            HStack {
                                Image(systemName: sport.iconName)
                                    .foregroundColor(Color(hex: "#2C4F40"))
                                Text(sport.name)
                                Spacer()
                                if selectedSport == sport.name {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "#2C4F40"))
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                // Date Section
                Section("Date") {
                    ForEach(DateFilter.allCases, id: \.self) { filter in
                        Button(action: { selectedDate = filter }) {
                            HStack {
                                Text(filter.displayName)
                                Spacer()
                                if selectedDate == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "#2C4F40"))
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Filter Ralleys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedSport = nil
                        selectedDate = .all
                    }
                    .foregroundColor(Color(hex: "#2C4F40"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#2C4F40"))
                }
            }
        }
    }
}

// MARK: - Sport Filter Pill

struct SportFilterPill: View {
    let name: String
    let iconName: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 14))
                Text(name)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Color(hex: "#2C4F40"))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color(hex: "#2C4F40") : Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: "#2C4F40").opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Filter Tag

struct FilterTag: View {
    let text: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 13, weight: .medium))
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .foregroundColor(Color(hex: "#2C4F40"))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(hex: "#2C4F40").opacity(0.1))
        .cornerRadius(16)
    }
}
