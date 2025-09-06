//
// MapView.swift - V1 (Locked Working Version)
// Snapshot date: 2025-08-31
//

import SwiftUI
import MapKit
import CoreLocation
import UIKit

// -----------------------------
// MapKit feature toggles (edit here)
// Minimum iOS version: iOS 18+
// -----------------------------
// With iOS 18+ we assume modern MapKit APIs are present. Toggle these flags
// to control Map style and fine-grained features. Hiding POIs uses
// MKMapView.preferredConfiguration (MKStandardMapConfiguration) which is
// available on the targeted runtime.

private enum MapFeatureFlags {
    // High-level SwiftUI Map style. Change to: .standard, .mutedStandard, .satellite, .hybrid
    static let mapStyle: MapStyle = .standard

    // Fine-grained features (applied via MKMapView wrapper):
    static let showsTraffic = false
    static let showPointsOfInterest = false // set false to hide POIs
    static let showsBuildings = false
}

// MKMapView wrapper for advanced feature control.
struct MapRepresentable: UIViewRepresentable {
    let center: CLLocationCoordinate2D
    let showsTraffic: Bool
    let showPOI: Bool
    let showsBuildings: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.showsTraffic = showsTraffic
        mapView.showsBuildings = showsBuildings

        // Use preferredConfiguration directly (iOS 18+ target)
        var config = MKStandardMapConfiguration(elevationStyle: .flat)
        config.pointOfInterestFilter = showPOI ? .includingAll : .excludingAll
        mapView.preferredConfiguration = config

        // Add a single annotation for the anchor
        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        mapView.addAnnotation(annotation)

        let region = MKCoordinateRegion(center: center, latitudinalMeters: Defaults.defaultRadiusMeters * 2, longitudinalMeters: Defaults.defaultRadiusMeters * 2)
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.showsTraffic = showsTraffic
        uiView.showsBuildings = showsBuildings

        var config = MKStandardMapConfiguration(elevationStyle: .flat)
        config.pointOfInterestFilter = showPOI ? .includingAll : .excludingAll
        uiView.preferredConfiguration = config

        if let annotation = uiView.annotations.first as? MKPointAnnotation {
            annotation.coordinate = center
        } else {
            let annotation = MKPointAnnotation()
            annotation.coordinate = center
            uiView.addAnnotation(annotation)
        }

        let region = MKCoordinateRegion(center: center, latitudinalMeters: Defaults.defaultRadiusMeters * 2, longitudinalMeters: Defaults.defaultRadiusMeters * 2)
        uiView.setRegion(region, animated: true)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: MapRepresentable
        init(_ parent: MapRepresentable) { self.parent = parent }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            let id = "Anchor"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
            if view == nil {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: id)
                view?.canShowCallout = false
            } else {
                view?.annotation = annotation
            }

            // Prefer bundled PinkMarker, then PinMarker. Resize to 30x30 points for the annotation view
            let targetSize = CGSize(width: 30, height: 30)
            if let source = UIImage(named: "PinkMarker") ?? UIImage(named: "PinMarker") {
                let rendererFormat = UIGraphicsImageRendererFormat.default()
                rendererFormat.opaque = false
                let img = UIGraphicsImageRenderer(size: targetSize, format: rendererFormat).image { _ in
                    // Draw the source image into the target rect preserving its original rendering
                    source.draw(in: CGRect(origin: .zero, size: targetSize))
                }
                view?.image = img
            } else if let symbolImage = UIImage(systemName: "mappin.circle.fill") {
                // Last-resort: rasterize SF Symbol to 30x30
                let rendererFormat = UIGraphicsImageRendererFormat.default()
                rendererFormat.opaque = false
                let img = UIGraphicsImageRenderer(size: targetSize, format: rendererFormat).image { _ in
                    symbolImage.withTintColor(UIColor.systemBlue).draw(in: CGRect(origin: .zero, size: targetSize))
                }
                view?.image = img
            }
            return view
        }
    }
}

private struct AnchorDot: View {
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.50))
                    .frame(width: 50, height: 50)

                // Use a bundled image asset named "PinkMarker" instead of an SF Symbol.
                // Prefer PinkMarker; fall back to PinMarker, otherwise use an SF Symbol with effects.
                Group {
                    if UIImage(named: "PinkMarker") != nil {
                        Image("PinkMarker")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                    } else if UIImage(named: "PinMarker") != nil {
                        Image("PinMarker")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                    } else {
                        Image(systemName: "shield.lefthalf.filled")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.pink, .white)
                            .symbolEffect(.pulse.byLayer, options: .repeat(.continuous))
                    }
                }
            }
        }
        .accessibilityLabel(label)
    }
}

struct MapView: View {
    let anchor: CLLocationCoordinate2D // The center coordinate for the map
    let totals: Totals // Total crime data to display
    let monthISO: String // The month in ISO format (e.g., "2025-06")
    let place: String // The name of the place (e.g., "Manchester")
    let byCategory: [CategoryCount] // Crime data grouped by category

    @State private var position: MapCameraPosition // The camera position for the map

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
    }

    var body: some View {
        ZStack {
            // Map
            Group {
                // Determine the annotation coordinate once
                let annotationCoordinate = locationManager.coordinate ?? anchor

                // If POIs are disabled in the flags, use the MapRepresentable wrapper
                // which applies MKMapView.preferredConfiguration to exclude POIs.
                if MapFeatureFlags.showPointsOfInterest == false {
                    MapRepresentable(
                        center: annotationCoordinate,
                        showsTraffic: MapFeatureFlags.showsTraffic,
                        showPOI: MapFeatureFlags.showPointsOfInterest,
                        showsBuildings: MapFeatureFlags.showsBuildings
                    )
                    .ignoresSafeArea()
                } else {
                    // Use SwiftUI Map unconditionally (iOS 18+ target)
                    Map(position: $position) {
                        // Provide the label to the custom AnchorDot but keep the system annotation title empty
                        let annotationLabel = place

                        Annotation("", coordinate: annotationCoordinate) {
                            AnchorDot(label: annotationLabel)
                        }
                    }
                    .mapStyle(MapFeatureFlags.mapStyle) // Use configured map style flag
                    .ignoresSafeArea()
                    .onAppear {
                        if let userLocation = locationManager.coordinate {
                            let userRegion = MKCoordinateRegion(
                                center: userLocation,
                                latitudinalMeters: Defaults.defaultRadiusMeters * 2,
                                longitudinalMeters: Defaults.defaultRadiusMeters * 2
                            )
                            position = .region(userRegion)
                        }
                    }
                    .onChange(of: locationManager.coordinate) { _, newLocation in
                        if let newLocation = newLocation {
                            let userRegion = MKCoordinateRegion(
                                center: newLocation,
                                latitudinalMeters: Defaults.defaultRadiusMeters * 2,
                                longitudinalMeters: Defaults.defaultRadiusMeters * 2
                            )
                            position = .region(userRegion)
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
