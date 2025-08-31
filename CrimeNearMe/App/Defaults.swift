//
//  Defaults.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//


import CoreLocation

enum Defaults {
    static let manchesterCenter = CLLocationCoordinate2D(latitude: 53.4794, longitude: -2.2453)
    static let manchesterBBox = (minLat: 53.35, maxLat: 53.60, minLon: -2.40, maxLon: -2.10)

    static let defaultRadiusMeters: Double = 1609 // 1 mile

    // Polygon covering Manchester city centre (rough square)
    static let manchesterPoly = "53.50,-2.30:53.50,-2.18:53.46,-2.18:53.46,-2.30"

    // 4 tiles covering roughly the Manchester council area
    static let manchesterPolys: [String] = [
        // NW tile
        "53.55,-2.35:53.55,-2.245:53.48,-2.245:53.48,-2.35",
        // NE tile
        "53.55,-2.245:53.55,-2.14:53.48,-2.14:53.48,-2.245",
        // SW tile
        "53.48,-2.35:53.48,-2.245:53.41,-2.245:53.41,-2.35",
        // SE tile
        "53.48,-2.245:53.48,-2.14:53.41,-2.14:53.41,-2.245"
    ]
}
