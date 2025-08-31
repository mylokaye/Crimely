//
//  Crime.swift
//  CrimeNearMe
//
//  More forgiving model for Police.uk API
//

import Foundation
import CoreLocation

struct Crime: Decodable, Identifiable {
    let id: String
    let category: String
    let month: String
    let location: Location

    struct Location: Decodable {
        let latitude: String
        let longitude: String
        let street: Street?

        struct Street: Decodable {
            let id: Int?
            let name: String?
        }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: Double(location.latitude) ?? 0,
            longitude: Double(location.longitude) ?? 0
        )
    }

    // Custom decoding to handle flexible IDs and optional fields
    private enum CodingKeys: String, CodingKey {
        case id
        case persistentID = "persistent_id"
        case category
        case month
        case location
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // ID: can be string, int, missing
        if let s = try? c.decode(String.self, forKey: .id), !s.isEmpty {
            self.id = s
        } else if let i = try? c.decode(Int.self, forKey: .id) {
            self.id = String(i)
        } else if let p = try? c.decode(String.self, forKey: .persistentID), !p.isEmpty {
            self.id = p
        } else {
            self.id = UUID().uuidString
        }

        self.category = (try? c.decode(String.self, forKey: .category)) ?? "unknown"
        self.month = (try? c.decode(String.self, forKey: .month)) ?? "----"

        // Location is always expected, but latitude/longitude can be empty strings
        self.location = (try? c.decode(Location.self, forKey: .location))
            ?? Location(latitude: "0", longitude: "0", street: nil)
    }
}
