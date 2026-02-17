//
//  SportIconMapper.swift
//  Club Ralley
//
//  Centralized sport icon mapping used across all components
//

import SwiftUI

struct SportIconMapper {

    /// Returns the SF Symbol name for a given sport
    static func iconName(for sport: String) -> String {
        switch sport.lowercased() {
        case "tennis": return "tennisball.fill"
        case "basketball": return "basketball.fill"
        case "soccer", "football": return "soccerball"
        case "volleyball": return "volleyball.fill"
        case "baseball": return "baseball.fill"
        case "golf": return "figure.golf"
        case "swimming": return "figure.pool.swim"
        case "pickleball": return "figure.pickleball"
        case "running": return "figure.run"
        case "cycling": return "figure.outdoor.cycle"
        case "hiking": return "figure.hiking"
        case "yoga": return "figure.yoga"
        case "crossfit", "fitness": return "dumbbell.fill"
        case "lacrosse": return "figure.lacrosse"
        case "hockey": return "hockey.puck.fill"
        case "skiing": return "figure.skiing.downhill"
        case "snowboarding": return "figure.snowboarding"
        case "surfing": return "figure.surfing"
        case "boxing": return "figure.boxing"
        case "martial arts", "mma": return "figure.martial.arts"
        case "rowing": return "figure.rowing"
        case "climbing": return "figure.climbing"
        case "table tennis", "ping pong": return "figure.table.tennis"
        case "badminton": return "figure.badminton"
        case "wrestling": return "figure.wrestling"
        case "cricket": return "cricket.ball.fill"
        case "rugby": return "figure.rugby"
        case "softball": return "figure.softball"
        case "track and field", "track": return "figure.track.and.field"
        case "fencing": return "figure.fencing"
        default: return "sportscourt.fill"
        }
    }
}
