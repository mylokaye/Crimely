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

// Pull-over resting state view (UIKit recreation in SwiftUI)
struct PullOverRestingView: View {
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(.ultraThinMaterial)
                .frame(height: 29)
                .frame(maxWidth: .infinity)
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 0.5)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 49)
    }
}

struct MapView: View {
    let anchor: CLLocationCoordinate2D
    let totals: Totals
    let monthISO: String
    let place: String
    let byCategory: [CategoryCount]

    @State private var position: MapCameraPosition
    @State private var legacyRegion: MKCoordinateRegion

    // Pull-over state (V1)
    @State private var isExpanded = false
    @State private var cardContentHeight: CGFloat = 480
    private let collapsedCardHeight: CGFloat = 70 // Tab bar height

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
            latitudinalMeters: Defaults.defaultRadiusMeters * 2,
            longitudinalMeters: Defaults.defaultRadiusMeters * 2
        )
        _position = State(initialValue: .region(region))
        _legacyRegion = State(initialValue: region)
    }

    var body: some View {
        ZStack {
            // Map
            Group {
                if #available(iOS 17.0, *) {
                    Map(position: $position) {
                        Annotation(place, coordinate: anchor) { AnchorDot(label: place) }
                    }
                    .mapStyle(.standard)
                } else {
                    Map(coordinateRegion: $legacyRegion)
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
                .frame(height: isExpanded ? cardContentHeight : collapsedCardHeight)
                .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isExpanded)
                .padding(.bottom, 16) // Move pullover up away from tab bar
                .padding(.horizontal, 16) // Add horizontal padding to left and right for tab bar spacing
            }
        }
        .navigationTitle(place)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(place).font(.custom("Merriweather-var", size: 18).weight(.semibold))
                    Text("\(totals.total) reports • \(PoliceAPI.humanMonth(monthISO))")
                        .font(.custom("Merriweather-var", size: 18))
                        .foregroundStyle(.secondary)
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
