//
//  ServerSavingsCalculation.swift
//  Checkpoint
//
//  Model representing server-calculated savings result
//

import Foundation

struct ServerSavingsCalculation: Decodable {
    let total_saved: Double
    let bets_avoided: Int
    let gambling_days_prevented: Int
}
