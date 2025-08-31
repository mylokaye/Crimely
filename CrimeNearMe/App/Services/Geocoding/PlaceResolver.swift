//
//  PlaceResolver.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//


import CoreLocation

actor PlaceResolver {
    static let shared = PlaceResolver()
    private let geocoder = CLGeocoder()

    func resolvePlaceName(for coord: CLLocationCoordinate2D) async -> String {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(.init(latitude: coord.latitude, longitude: coord.longitude))
            if let p = placemarks.first {
                return p.locality ?? p.subAdministrativeArea ?? p.administrativeArea ?? "Manchester"
            }
        } catch { }
        return "Manchester"
    }
}