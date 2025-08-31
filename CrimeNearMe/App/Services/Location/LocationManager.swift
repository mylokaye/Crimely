//
//  LocationManager.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//


import Combine
import CoreLocation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var status: CLAuthorizationStatus?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func request() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        } else {
            // denied/restricted → leave coordinate nil (caller will fall back to Manchester)
            coordinate = nil
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let c = locations.last?.coordinate {
            coordinate = c
            manager.stopUpdatingLocation()
        }
    }
}
