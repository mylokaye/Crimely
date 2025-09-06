//
//  LocationManager.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//

import Combine
import CoreLocation

/// Observable location manager that handles Core Location permissions and updates
/// 
/// This class wraps Core Location functionality to provide a simple interface
/// for requesting location permissions and getting user coordinates. It automatically
/// handles authorization state changes and provides location updates through
/// published properties.
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    /// Current user coordinate (nil if location unavailable)
    @Published var coordinate: CLLocationCoordinate2D?
    
    /// Current authorization status for location services
    @Published var status: CLAuthorizationStatus?
    
    /// Core Location manager instance
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        // Set accuracy to 100 meters - sufficient for crime area queries
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Requests location permission and starts location updates if authorized
    /// 
    /// This method handles the complete location flow:
    /// 1. Requests permission if not yet determined
    /// 2. Starts location updates if already authorized
    /// 3. Sets coordinate to nil if permission denied
    func request() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        } else {
            // Permission denied/restricted → leave coordinate nil for fallback handling
            coordinate = nil
        }
    }

    // MARK: - CLLocationManagerDelegate
    
    /// Called when location authorization status changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    /// Called when location updates are received
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let c = locations.last?.coordinate {
            print("[DEBUG] LocationManager didUpdateLocations: \(c)")
            coordinate = c
            // Stop updates after getting first location to conserve battery
            manager.stopUpdatingLocation()
        } else {
            print("[DEBUG] LocationManager didUpdateLocations: No valid location")
        }
    }
}
