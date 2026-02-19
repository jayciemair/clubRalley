//
//  OverpassService.swift
//  Club Ralley
//
//  Queries the free OpenStreetMap Overpass API to discover sports venues
//  (courts, fields, gyms, pools, tracks) near a coordinate.
//  No API key required — zero cost.
//

import Foundation

// MARK: - Overpass Errors

enum OverpassError: Error {
    case rateLimited
    case timeout
    case badResponse(Int)
    case decodingFailed
    case invalidURL
}

// MARK: - Overpass Response Models

struct OverpassResponse: Codable {
    let elements: [OverpassElement]
}

struct OverpassElement: Codable {
    let type: String       // "node", "way", "relation"
    let id: Int64
    let lat: Double?       // present for nodes
    let lon: Double?       // present for nodes
    let center: OverpassCenter?  // present for ways/relations with `out center`
    let tags: [String: String]?
}

struct OverpassCenter: Codable {
    let lat: Double
    let lon: Double
}

// MARK: - Parsed Intermediate Model

struct OverpassVenue {
    let osmId: String          // "node/12345" or "way/67890"
    let name: String
    let latitude: Double
    let longitude: Double
    let type: String           // "court", "field", "gym", "park"
    let sports: [String]       // Club Ralley display names
}

// MARK: - OverpassService

class OverpassService {

    private let endpoint = "https://overpass-api.de/api/interpreter"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public API

    /// Discover sports venues within `radiusMeters` of the given coordinate.
    func discoverVenues(latitude: Double, longitude: Double, radiusMeters: Int = 5000) async throws -> [OverpassVenue] {
        let query = buildQuery(latitude: latitude, longitude: longitude, radiusMeters: radiusMeters)
        let elements = try await executeQuery(query)
        return elements.compactMap { parseElement($0) }
    }

    // MARK: - Query Builder

    private func buildQuery(latitude: Double, longitude: Double, radiusMeters: Int) -> String {
        let lat = String(format: "%.6f", latitude)
        let lng = String(format: "%.6f", longitude)
        let radius = radiusMeters

        return """
        [out:json][timeout:25];
        (
          nwr["leisure"="pitch"](around:\(radius),\(lat),\(lng));
          nwr["leisure"="sports_centre"](around:\(radius),\(lat),\(lng));
          nwr["leisure"="fitness_centre"](around:\(radius),\(lat),\(lng));
          nwr["leisure"="swimming_pool"](around:\(radius),\(lat),\(lng));
          nwr["leisure"="park"]["sport"](around:\(radius),\(lat),\(lng));
          nwr["leisure"="stadium"](around:\(radius),\(lat),\(lng));
          nwr["leisure"="track"](around:\(radius),\(lat),\(lng));
        );
        out center;
        """
    }

    // MARK: - Network

    private func executeQuery(_ query: String) async throws -> [OverpassElement] {
        guard var components = URLComponents(string: endpoint) else {
            throw OverpassError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "data", value: query)]

        guard let url = components.url else {
            throw OverpassError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 30

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw OverpassError.badResponse(0)
        }

        switch http.statusCode {
        case 200:
            break
        case 429:
            throw OverpassError.rateLimited
        case 504:
            throw OverpassError.timeout
        default:
            throw OverpassError.badResponse(http.statusCode)
        }

        do {
            let decoded = try JSONDecoder().decode(OverpassResponse.self, from: data)
            return decoded.elements
        } catch {
            throw OverpassError.decodingFailed
        }
    }

    // MARK: - Element Parsing

    private func parseElement(_ element: OverpassElement) -> OverpassVenue? {
        // Resolve coordinates: nodes have lat/lon directly, ways/relations use center
        let lat: Double
        let lon: Double
        if let directLat = element.lat, let directLon = element.lon {
            lat = directLat
            lon = directLon
        } else if let center = element.center {
            lat = center.lat
            lon = center.lon
        } else {
            return nil // No coordinates available
        }

        let tags = element.tags ?? [:]
        let leisure = tags["leisure"] ?? ""
        let sportTag = tags["sport"] ?? ""

        // Parse sports from semicolon-separated OSM tag
        let parsedSports = mapSports(from: sportTag)

        // Determine venue type
        let venueType = mapType(leisure: leisure, sports: parsedSports)

        // Generate name
        let name = tags["name"] ?? generateName(sports: parsedSports, type: venueType)

        let osmId = "\(element.type)/\(element.id)"

        return OverpassVenue(
            osmId: osmId,
            name: name,
            latitude: lat,
            longitude: lon,
            type: venueType,
            sports: parsedSports.isEmpty ? inferSports(from: leisure) : parsedSports
        )
    }

    // MARK: - OSM Tag Mapping

    /// Maps OSM `sport` tag values to Club Ralley display names.
    private func mapSports(from sportTag: String) -> [String] {
        guard !sportTag.isEmpty else { return [] }

        let osmSports = sportTag
            .split(separator: ";")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }

        return osmSports.compactMap { osmSportToDisplayName[$0] }
    }

    /// Maps OSM `leisure` + parsed sports to a Club Ralley venue type.
    private func mapType(leisure: String, sports: [String]) -> String {
        switch leisure {
        case "pitch":
            let courtSports: Set<String> = ["Basketball", "Tennis", "Volleyball", "Pickleball"]
            if sports.contains(where: { courtSports.contains($0) }) {
                return "court"
            }
            return "field"

        case "sports_centre", "fitness_centre", "swimming_pool":
            return "gym"

        case "stadium", "track":
            return "field"

        case "park":
            return "park"

        default:
            return "other"
        }
    }

    /// Generate a readable name when OSM has no `name` tag.
    private func generateName(sports: [String], type: String) -> String {
        if let firstSport = sports.first {
            let suffix: String
            switch type {
            case "court": suffix = "Court"
            case "field": suffix = "Field"
            case "gym": suffix = "Sports Center"
            case "park": suffix = "Park"
            default: suffix = "Venue"
            }
            return "\(firstSport) \(suffix)"
        }

        switch type {
        case "court": return "Sports Court"
        case "field": return "Sports Field"
        case "gym": return "Sports Center"
        case "park": return "Park"
        default: return "Sports Venue"
        }
    }

    /// Infer sports when the `sport` tag is missing but `leisure` gives us a hint.
    private func inferSports(from leisure: String) -> [String] {
        switch leisure {
        case "swimming_pool": return ["Swimming"]
        case "track": return ["Running"]
        case "fitness_centre": return ["CrossFit"]
        default: return []
        }
    }

    // MARK: - Sport Name Lookup

    /// OSM sport value → Club Ralley display name
    private let osmSportToDisplayName: [String: String] = [
        "basketball": "Basketball",
        "tennis": "Tennis",
        "soccer": "Soccer",
        "football": "Football",
        "american_football": "Football",
        "volleyball": "Volleyball",
        "pickleball": "Pickleball",
        "golf": "Golf",
        "swimming": "Swimming",
        "running": "Running",
        "cycling": "Cycling",
        "lacrosse": "Lacrosse",
        "baseball": "Baseball",
        "softball": "Softball",
        "cricket": "Cricket",
        "field_hockey": "Field Hockey",
        "ice_hockey": "Hockey",
        "rugby": "Rugby",
        "skateboard": "Skateboarding",
        "table_tennis": "Table Tennis",
        "badminton": "Badminton",
        "yoga": "Yoga",
        "gymnastics": "Gymnastics",
        "wrestling": "Wrestling",
        "boxing": "Boxing",
        "martial_arts": "Martial Arts",
        "climbing": "Climbing",
        "equestrian": "Equestrian",
        "archery": "Archery",
        "handball": "Handball",
        "rowing": "Rowing",
        "canoe": "Canoeing",
        "multi": "Multi-Sport",
    ]
}
