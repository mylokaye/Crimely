//
// MapView.swift - V1 (Locked Working Version)
// Snapshot date: 2025-08-31
//

import SwiftUI
import MapKit
import CoreLocation

// -----------------------------
// MapKit feature toggles (edit here)
// -----------------------------
// This section provides easy-to-edit flags and guidance so you can turn
// common MapKit features on/off. SwiftUI's Map offers high-level style
// controls (mapStyle). For lower-level features (traffic, individual
// POI categories, road visibility) you will need to use an MKMapView
// wrapper (see commented example below).

private enum MapFeatureFlags {
    // High-level SwiftUI Map style. Change to: .standard, .mutedStandard, .satellite, .hybrid
    static let mapStyle: MapStyle = .standard

    // Fine-grained features (require MKMapView via UIViewRepresentable):
    // - showsTraffic: overlays traffic information
    // - showPointsOfInterest: show/hide POI symbols (restaurants, shops, transit, etc.)
    // - showsBuildings: 3D building extrusion
    // Note: these flags are informational here; to apply them, swap the SwiftUI Map
    // for the commented MKMapViewRepresentable below and wire these booleans in.
    static let showsTraffic = false
    static let showPointsOfInterest = true
    static let showsBuildings = true
}

// Example MKMapView wrapper for advanced feature control (commented out).
// To use it: 1) Uncomment the struct below and 2) replace the SwiftUI Map in
// the MapView body with MapRepresentable(...flags...). The example demonstrates
// toggling traffic, building display, and POI filters.
/*
import UIKit

struct MapRepresentable: UIViewRepresentable {
    let center: CLLocationCoordinate2D
    let showsTraffic: Bool
    let showPOI: Bool
    let showsBuildings: Bool

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.mapType = .standard
        mapView.showsTraffic = showsTraffic
        mapView.showsBuildings = showsBuildings

        // Control point-of-interest visibility (iOS 13+)
        if #available(iOS 13.0, *) {
            mapView.pointOfInterestFilter = showPOI ? .includingAll : .excludingAll
        }

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        let region = MKCoordinateRegion(center: center, latitudinalMeters: Defaults.defaultRadiusMeters * 2, longitudinalMeters: Defaults.defaultRadiusMeters * 2)
        uiView.setRegion(region, animated: true)
        uiView.showsTraffic = showsTraffic
        uiView.showsBuildings = showsBuildings
        if #available(iOS 13.0, *) {
            uiView.pointOfInterestFilter = showPOI ? .includingAll : .excludingAll
        }
    }
}
*/

private struct AnchorDot: View {
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.0))
                    .frame(width: 50, height: 50) // increased 50% from 50

                // Use mappin.circle.fill and apply a pulsing symbol effect on iOS 17+.
                if #available(iOS 17.0, *) {
                    Image(systemName: "mappin.and.ellipse.circle.fill")
                        .font(.title2)
                        .scaleEffect(1.5) // increase image size by 50%
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.blue, .white)
                } else {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .scaleEffect(1.5)
                        .foregroundStyle(.blue, .white)
                }
            }
            // Removed the visible place name text here per request.
            // Previously: Text(label).font(.custom("Merriweather", size: 18))
        }
        .accessibilityLabel(label)
    }
}

/*
// // Pull-over resting state view (UIKit recreation in SwiftUI)
struct PullOverRestingView: View {
    var body: some View {
        ZStack(alignment: .top) {
            if #available(iOS 17.0, *) {
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .fill(.ultraThinMaterial) // Provides a translucent material effect
                    .frame(height: 9) // Height of the main rounded rectangle
                    .frame(maxWidth: .infinity) // Makes it span the full width
                    .glassEffect(.regular) // Adds a glass-like effect (iOS 17+ only)
            } else {
                RoundedRectangle(cornerRadius: 0, style: .continuous)
                    .fill(.ultraThinMaterial) // Provides a translucent material effect
                    .frame(height: 9) // Height of the main rounded rectangle
                    .frame(maxWidth: .infinity) // Makes it span the full width
            }
            Rectangle()
                .fill(Color.black.opacity(0.01)) // Thin black line with slight transparency
                .frame(height: 0.5) // Height of the thin line
                .frame(maxWidth: .infinity) // Makes it span the full width
        }
        .frame(height: 19) // Total height of the pull-over resting view
    }
}
 */
struct MapView: View {
    let anchor: CLLocationCoordinate2D // The center coordinate for the map
    let totals: Totals // Total crime data to display
    let monthISO: String // The month in ISO format (e.g., "2025-06")
    let place: String // The name of the place (e.g., "Manchester")
    let byCategory: [CategoryCount] // Crime data grouped by category

    @State private var position: MapCameraPosition // The camera position for the map
    @State private var legacyRegion: MKCoordinateRegion // Fallback region for older iOS versions

    @StateObject private var locationManager = LocationManager() // Location manager to track user location

    // Pull-over state (V1)
    @State private var isExpanded = false // Tracks whether the pull-over card is expanded
    @State private var cardContentHeight: CGFloat = 480 // Height of the expanded card content
    private let collapsedCardHeight: CGFloat = 100 // Height from bottom of the card when collapsed

    init(anchor: CLLocationCoordinate2D,
         totals: Totals,
         monthISO: String,
         place: String,
         byCategory: [CategoryCount]) {
        self.anchor = anchor
        self.totals = totals
        self.monthISO = monthISO
        self.place = place
        self.byCategory = byCategory

        let region = MKCoordinateRegion(
            center: anchor,
            latitudinalMeters: Defaults.defaultRadiusMeters * 2, // Latitude span for the map region
            longitudinalMeters: Defaults.defaultRadiusMeters * 2 // Longitude span for the map region
        )
        _position = State(initialValue: .region(region)) // Initialize the camera position
        _legacyRegion = State(initialValue: region) // Initialize the fallback region
    }

    var body: some View {
        ZStack {
            // Map
            Group {
                if #available(iOS 17.0, *) {
                    Map(position: $position) {
                        let annotationCoordinate = locationManager.coordinate ?? anchor
                        // Provide the label to the custom AnchorDot but keep the system annotation title empty
                        let annotationLabel = place

                        // Use the custom AnchorDot for the visible label (Merriweather, size 18).
                        // Pass an empty system label to Annotation so the map doesn't draw a second label.

                        Annotation("", coordinate: annotationCoordinate) {
                            AnchorDot(label: annotationLabel)
                        }
                    }
                    .mapStyle(MapFeatureFlags.mapStyle) // Use configured map style flag
                    .onAppear {
                        if let userLocation = locationManager.coordinate {
                            print("[DEBUG] User location onAppear: \(userLocation)")
                            let userRegion = MKCoordinateRegion(
                                center: userLocation,
                                latitudinalMeters: Defaults.defaultRadiusMeters * 2,
                                longitudinalMeters: Defaults.defaultRadiusMeters * 2
                            )
                            position = .region(userRegion)
                        } else {
                            print("[DEBUG] No user location available onAppear")
                        }
                    }
                    .onChange(of: locationManager.coordinate) { _, newLocation in
                        if let newLocation = newLocation {
                            print("[DEBUG] User location updated: \(newLocation)")
                            let userRegion = MKCoordinateRegion(
                                center: newLocation,
                                latitudinalMeters: Defaults.defaultRadiusMeters * 2,
                                longitudinalMeters: Defaults.defaultRadiusMeters * 2
                            )
                            position = .region(userRegion)
                        } else {
                            print("[DEBUG] User location update received but is nil")
                        }
                    }
                } else {
                    Map(coordinateRegion: $legacyRegion) // Fallback map for older iOS versions
                        .onAppear {
                            if let userLocation = locationManager.coordinate {
                                legacyRegion = MKCoordinateRegion(
                                    center: userLocation,
                                    latitudinalMeters: Defaults.defaultRadiusMeters * 2,
                                    longitudinalMeters: Defaults.defaultRadiusMeters * 2
                                )
                            }
                        }
                }
            }
            // Bottom card overlay
            VStack {
                Spacer()
                CrimeDataCard(
                    place: place,
                    totals: totals,
                    monthISO: monthISO,
                    byCategory: byCategory,
                    onProfile: {},
                    isExpanded: $isExpanded,
                    onHeightChange: { h in cardContentHeight = min(h, UIScreen.main.bounds.height * 0.9) }
                )
                .frame(height: isExpanded ? cardContentHeight : collapsedCardHeight) // Adjust height based on state
                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isExpanded) // Smooth animation for expansion
                .padding(.bottom, 16) // Move pullover up away from tab bar
                .padding(.horizontal, 16) // Add horizontal padding to left and right for tab bar spacing
            }
        }
        .navigationTitle(place) // Set the navigation title to the place name
        .navigationBarTitleDisplayMode(.inline) // Display the title inline
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(place).font(.custom("Merriweather", size: 18).weight(.semibold)) // Place name
                    Text("\(totals.total) reports • \(PoliceAPI.humanMonth(monthISO))")
                        .font(.custom("Merriweather", size: 18)) // Total reports and month
                        .foregroundStyle(.secondary) // Secondary text style
                }
            }
        }
    }
}

// MARK: - Previews
struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(
            anchor: CLLocationCoordinate2D(latitude: 53.4794, longitude: -2.2453),
            totals: Totals(total: 16, serious: 3),
            monthISO: "2025-06",
            place: "Manchester",
            byCategory: [
                CategoryCount(category: "Violence", count: 5),
                CategoryCount(category: "Robbery", count: 2),
                CategoryCount(category: "Shoplifting", count: 4),
                CategoryCount(category: "Vehicle crime", count: 3)
            ]
        )
    }
}
