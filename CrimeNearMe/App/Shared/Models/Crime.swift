//
//  Crime.swift
//  CrimeNearMe
//
//  Robust model for parsing UK Police API crime data with flexible field handling
//

import Foundation
import CoreLocation

/// Represents a single crime incident from the UK Police API
/// 
/// This model handles the sometimes inconsistent data format from the police.uk API,
/// providing fallback values for missing or malformed fields to ensure reliable parsing.
struct Crime: Decodable, Identifiable {
    /// Unique identifier for the crime incident
    let id: String
    
    /// Crime category (e.g., "violent-crime", "burglary", "vehicle-crime")
    let category: String
    
    /// Month when the crime was reported (YYYY-MM format)
    let month: String
    
    /// Location information including coordinates and street details
    let location: Location

    /// Nested structure containing crime location data
    struct Location: Decodable {
        /// Latitude as string (API provides coordinates as strings)
        let latitude: String
        
        /// Longitude as string (API provides coordinates as strings)
        let longitude: String
        
        /// Optional street information where the crime occurred
        let street: Street?

        /// Street details including ID and name
        struct Street: Decodable {
            /// Optional street identifier
            let id: Int?
            
            /// Optional street name
            let name: String?
        }
    }

    /// Converts string coordinates to CLLocationCoordinate2D for map display
    /// - Returns: CoreLocation coordinate with fallback to (0,0) for invalid data
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: Double(location.latitude) ?? 0,
            longitude: Double(location.longitude) ?? 0
        )
    }

    /// Custom decoding keys to handle flexible ID field formats from the API
    private enum CodingKeys: String, CodingKey {
        case id
        case persistentID = "persistent_id"
        case category
        case month
        case location
    }

    /// Custom decoder that handles inconsistent API data formats
    /// 
    /// The UK Police API sometimes provides:
    /// - ID as string, integer, or missing entirely
    /// - Persistent ID as an alternative identifier
    /// - Missing category or month fields
    /// - Empty or invalid location coordinates
    /// 
    /// This decoder provides sensible fallbacks for all scenarios.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // Flexible ID handling: try string ID, then integer ID, then persistent ID, finally generate UUID
        if let s = try? c.decode(String.self, forKey: .id), !s.isEmpty {
            self.id = s
        } else if let i = try? c.decode(Int.self, forKey: .id) {
            self.id = String(i)
        } else if let p = try? c.decode(String.self, forKey: .persistentID), !p.isEmpty {
            self.id = p
        } else {
            self.id = UUID().uuidString
        }

        // Provide fallbacks for missing core fields
        self.category = (try? c.decode(String.self, forKey: .category)) ?? "unknown"
        self.month = (try? c.decode(String.self, forKey: .month)) ?? "----"

        // Location is required but coordinates can be invalid strings
        self.location = (try? c.decode(Location.self, forKey: .location))
            ?? Location(latitude: "0", longitude: "0", street: nil)
    }
}
