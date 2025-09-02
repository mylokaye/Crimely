//
//  GeoMath.swift
//  CrimeNearMe
//
//  Geographic utility functions for distance calculations
//

import CoreLocation

/// Calculates the great-circle distance between two coordinates using the Haversine formula
/// 
/// This function provides accurate distance calculations for geographic coordinates
/// on the Earth's surface. It's used for proximity calculations and filtering.
/// 
/// - Parameters:
///   - a: First coordinate point
///   - b: Second coordinate point
/// - Returns: Distance in meters between the two points
@inline(__always)
func haversineDistanceMeters(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
    let r = 6_371_000.0 // Earth's radius in meters
    let dLat = (b.latitude - a.latitude) * .pi / 180
    let dLon = (b.longitude - a.longitude) * .pi / 180
    let la1 = a.latitude * .pi / 180
    let la2 = b.latitude * .pi / 180
    let h = sin(dLat/2)*sin(dLat/2) + sin(dLon/2)*sin(dLon/2) * cos(la1)*cos(la2)
    return 2*r*asin(min(1, sqrt(h)))
}