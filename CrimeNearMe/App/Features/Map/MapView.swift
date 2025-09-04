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
                        .font(.custom("Merriweather-var", size: 20).weight(.semibold))
                    Text("(\(count))")
                        .font(.custom("Merriweather-var", size: 20).weight(.regular))
                        .foregroundStyle(.secondary)
                }
                Text(subtitle)
                    .font(.custom("Merriweather-var", size: 17))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

// Pull-over resting state view (UIKit recreation in SwiftUI)
struct PullOverRestingView: View {
    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(.ultraThinMaterial)
                .frame(height: 49)
                .frame(maxWidth: .infinity)
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 0.5)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 49)
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

    private let collapsedHeight: CGFloat = 49 // Tab bar height

    var body: some View {
        VStack(spacing: 16) {
            if isExpanded {
                // Grabber
                Capsule()
                    .frame(width: 44, height: 5)
                    .opacity(0.18)
                    .padding(.top, 12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            isExpanded.toggle()
                        }
                    }

                // Rows when expanded
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(byCategory, id: \ .category) { item in
                            CrimeRowView(
                                iconName: icon(for: item.category),
                                title: item.category.capitalized,
                                count: item.count,
                                subtitle: subtitle(for: item.category)
                            )
                        }
                        Color.clear.frame(height: 12)
                    }
                    .padding(.vertical, 8)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear { onHeightChange(max(collapsedHeight + 80, proxy.size.height + 160)) }
                                .onChange(of: proxy.size.height) { h in onHeightChange(max(collapsedHeight + 80, h + 160)) }
                        }
                    )
                }
                .scrollIndicators(.never)
            } else {
                Capsule()
                    .frame(width: 44, height: 5)
                    .opacity(0.18)
                    .padding(.top, 8)
                    .contentShape(Rectangle())
                Text(place)
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(place.count > 10 ? 0.7 : 1.0)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 8)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThickMaterial)
                .shadow(color: Color.black.opacity(0.18), radius: 24, y: 8)
        )
        // Remove border for liquid glass effect
        .padding(.horizontal, 0)
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
