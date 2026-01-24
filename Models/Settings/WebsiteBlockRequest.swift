//
//  WebsiteBlockRequest.swift
//  Checkpoint
//
//  Model representing a user's website block request
//

import Foundation

struct WebsiteBlockRequest: Codable {
    let id: UUID?
    let userId: UUID
    let domain: String
    let status: String
    let reviewedBy: UUID?
    let reviewNotes: String?
    let createdAt: Date?
    let updatedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case domain
        case status
        case reviewedBy = "reviewed_by"
        case reviewNotes = "review_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
