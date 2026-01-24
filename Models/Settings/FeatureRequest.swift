//
//  FeatureRequest.swift
//  Checkpoint
//
//  Model representing a user's feature request
//

import Foundation

struct FeatureRequest: Codable {
    let id: UUID?
    let userId: UUID
    let featureDescription: String
    let createdAt: Date?
    let updatedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case featureDescription = "feature_description"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
