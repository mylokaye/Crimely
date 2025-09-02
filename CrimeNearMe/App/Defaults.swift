//
//  Defaults.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//

import CoreLocation

/// Contains default values and configuration constants for the application
/// 
/// This enum provides centralized configuration for geographic boundaries,
/// default locations, and polygon definitions used for API queries.
enum Defaults {
    /// The center coordinate of Manchester, used as fallback location
    static let manchesterCenter = CLLocationCoordinate2D(latitude: 53.4794, longitude: -2.2453)
    
    /// Bounding box coordinates defining the Manchester area boundaries
    /// Any coordinates outside this box will be clamped to manchesterCenter
    static let manchesterBBox = (minLat: 53.35, maxLat: 53.60, minLon: -2.40, maxLon: -2.10)

    /// Default radius in meters for location-based queries (1 mile)
    static let defaultRadiusMeters: Double = 1609

    /// Single polygon covering Manchester city centre (rough square area)
    /// Format: "lat1,lon1:lat2,lon2:lat3,lon3:lat4,lon4"
    static let manchesterPoly = "53.50,-2.30:53.50,-2.18:53.46,-2.18:53.46,-2.30"

    /// Array of four polygons covering the broader Manchester council area
    /// This provides better coverage for crime data queries by dividing the area into tiles
    static let manchesterPolys: [String] = [
        // NW tile - covers northwestern Manchester
        "53.55,-2.35:53.55,-2.245:53.48,-2.245:53.48,-2.35",
        // NE tile - covers northeastern Manchester  
        "53.55,-2.245:53.55,-2.14:53.48,-2.14:53.48,-2.245",
        // SW tile - covers southwestern Manchester
        "53.48,-2.35:53.48,-2.245:53.41,-2.245:53.41,-2.35",
        // SE tile - covers southeastern Manchester
        "53.48,-2.245:53.48,-2.14:53.41,-2.14:53.41,-2.245"
    ]
}
