//
// MapView.swift - V1 (Locked Working Version)
// Snapshot date: 2025-08-31
//

import SwiftUI
import MapKit
import CoreLocation

// Lightweight anchor marker
private struct AnchorDot: View {
    let label: String
    var body: some View {
        ZStack {
            Circle().fill(Color.blue.opacity(0.20)).frame(width: 28, height: 28)
            Image(systemName: "mappin.circle.fill").font(.title2).foregroundStyle(.red, .white)
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
                        Annotation(place, coordinate: anchor) { AnchorDot(label: place) }
                    }
                    .mapStyle(.standard) // Standard map style
                } else {
                    Map(coordinateRegion: $legacyRegion) // Fallback map for older iOS versions
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
