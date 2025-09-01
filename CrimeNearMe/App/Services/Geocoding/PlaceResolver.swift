//
//  PlaceResolver.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//

import CoreLocation

/// Actor-based service for resolving coordinates to human-readable place names
/// 
/// This service uses Core Location's reverse geocoding to convert coordinates
/// into user-friendly place names for display in the UI. It's implemented as
/// an actor to handle concurrent geocoding requests safely.
actor PlaceResolver {
    /// Shared singleton instance
    static let shared = PlaceResolver()
    
    /// Core Location geocoder for reverse geocoding operations
    private let geocoder = CLGeocoder()

    /// Resolves a coordinate to a human-readable place name
    /// 
    /// Attempts reverse geocoding to find the locality, administrative area,
    /// or other geographic identifiers. Falls back to "Manchester" if geocoding
    /// fails or returns no usable results.
    /// 
    /// - Parameter coord: The coordinate to resolve
    /// - Returns: Human-readable place name (e.g., "Manchester", "City Centre")
    func resolvePlaceName(for coord: CLLocationCoordinate2D) async -> String {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(.init(latitude: coord.latitude, longitude: coord.longitude))
            if let p = placemarks.first {
                // Try locality first, then fall back to administrative areas
                return p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? "Manchester"
            }
        } catch { 
            // Geocoding failed - network issues, rate limiting, or invalid coordinates
        }
        return "Manchester"
    }
}