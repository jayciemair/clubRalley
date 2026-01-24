//
//  UserProfileDataResponse.swift
//  Checkpoint
//
//  Model representing user profile data from Supabase
//

import Foundation

struct UserProfileDataResponse: Decodable {
    let user_id: UUID
    let accountability_anchors: [String]?
}
