//
//  PermissionBenefit.swift
//  Checkpoint
//
//  Model representing a benefit shown in permission request screens
//

import Foundation

struct PermissionBenefit: Identifiable, Equatable {
    let id = UUID()
    let iconSystemName: String
    let title: String
    let description: String?
}
