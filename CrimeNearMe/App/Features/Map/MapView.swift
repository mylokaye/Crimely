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

// Row used in the bottom card
private struct CrimeRowView: View {
    let iconName: String
    let title: String
    let count: Int
    let subtitle: String
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: iconName)
                .font(.title3)
                .frame(width: 28, height: 28)
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .padding(6)
                .background(Circle().fill(Color(.systemBackground).opacity(0.6)))
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                    Text("(\(count))")
                        .font(.title3.weight(.regular))
                        .foregroundStyle(.secondary)
                }
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// Bottom overlay card (pull-over)
private struct CrimeDataCard: View {
    let place: String
    let totals: Totals
    let monthISO: String
    let byCategory: [CategoryCount]
    let onProfile: () -> Void
    @Binding var isExpanded: Bool
    let onHeightChange: (CGFloat) -> Void

    // Simple mapping used in V1
    private func subtitle(for category: String) -> String {
        switch category.lowercased() {
        case "violence", "violent-crime":
            return "Murder, Harassment, Common Assault, ABH & GBH."
        case "robbery", "theft-from-the-person", "burglary":
            return "Theft with force or threat; entering to commit a crime."
        case "shoplifting":
            return "Theft from a shop."
        case "vehicle crime", "vehicle-crime":
            return "Theft of/from a vehicle and damage."
        default:
            return "Reported incidents in this category."
        }
    }

    private func icon(for category: String) -> String {
        switch category.lowercased() {
        case "violence", "violent-crime": return "bolt.heart"
        case "robbery", "theft-from-the-person", "burglary": return "lock"
        case "shoplifting": return "bag"
        case "vehicle crime", "vehicle-crime": return "car"
        default: return "shield.lefthalf.filled"
        }
    }

    private let collapsedHeight: CGFloat = 96

    var body: some View {
        VStack(spacing: 12) {
            // Grabber
            Capsule().frame(width: 44, height: 5).opacity(0.15)
                .contentShape(Rectangle())
                .onTapGesture { withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { isExpanded.toggle() } }

            // Header (V1 title)
            HStack {
                Spacer()
                Text("Crime Data")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button(action: onProfile) {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Circle().fill(Color.blue))
                }
                .accessibilityLabel("Profile")
            }
            .padding(.bottom, 4)

            // Rows when expanded
            if isExpanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(byCategory, id: \.category) { item in
                            CrimeRowView(
                                iconName: icon(for: item.category),
                                title: item.category.capitalized,
                                count: item.count,
                                subtitle: subtitle(for: item.category)
                            )
                        }
                        Color.clear.frame(height: 8)
                    }
                    .padding(.vertical, 4)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear { onHeightChange(max(collapsedHeight + 60, proxy.size.height + 140)) }
                                .onChange(of: proxy.size.height) { h in onHeightChange(max(collapsedHeight + 60, h + 140)) }
                        }
                    )
                }
                .scrollIndicators(.never)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.ultraThinMaterial)
        )
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color.black.opacity(0.06))
        )
        .shadow(color: Color.black.opacity(0.12), radius: 18, y: -2)
        .padding(.horizontal)
        .gesture(
            DragGesture(minimumDistance: 8)
                .onEnded { value in
                    let threshold: CGFloat = 60
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        if value.translation.height < -threshold { isExpanded = true }
                        if value.translation.height > threshold { isExpanded = false }
                    }
                }
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Crime data summary for \(place). Total \(totals.total) in \(PoliceAPI.humanMonth(monthISO)).")
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
    private let collapsedCardHeight: CGFloat = 96

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
        .overlay(alignment: .bottom) {
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
            .padding(.bottom)
        }
        .navigationTitle(place)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(place).font(.headline)
                    Text("\(totals.total) reports • \(PoliceAPI.humanMonth(monthISO))")
                        .font(.caption)
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
