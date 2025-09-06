import SwiftUI
import CoreLocation
import MapKit
import UIKit

private enum Brand {
    // #8E97FD, #7F88F0, #FFE1B3
    static let base = Color(red: 142/255, green: 151/255, blue: 253/255)
    static let baseDark = Color(red: 127/255, green: 136/255, blue: 240/255)
    static let button = Color(red: 255/255, green: 225/255, blue: 179/255)
}

@available(iOS 17.0, *)
struct CitySummaryView: View {
    let anchor: CLLocationCoordinate2D
    let totals: Totals
    let monthISO: String
    let place: String
    let onShowAll: () -> Void

    // Animated total
    @State private var displayedTotal: Int = 0
    @State private var headlineVisible = false
    @State private var isPrewarmingMap = false

    private func prewarmMapTiles() {
        guard !isPrewarmingMap else { return }
        isPrewarmingMap = true

        // Match the region you’ll use on the map screen (roughly 1 mile radius)
        let region = MKCoordinateRegion(
            center: anchor,
            latitudinalMeters: Defaults.defaultRadiusMeters * 2,
            longitudinalMeters: Defaults.defaultRadiusMeters * 2
        )

        let opts = MKMapSnapshotter.Options()
        opts.region = region
        opts.mapType = .standard
        opts.traitCollection = UITraitCollection(userInterfaceStyle: .unspecified)
        opts.showsBuildings = true
        opts.pointOfInterestFilter = .includingAll

        let snapshotter = MKMapSnapshotter(options: opts)
        snapshotter.start(with: .global(qos: .utility)) { _, _ in
            // We don’t need the image; this warms Apple Maps tile cache & renderer
            DispatchQueue.main.async { self.isPrewarmingMap = false }
        }
    }

    // RAG accent for the big stat
    private var accent: Color {
        if totals.total == 0 { return .blue }
        switch totals.total {
        case ...5:   return .green
        case 6...20: return .orange
        default:     return .red
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(colors: [Brand.base, Brand.baseDark], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // Concentric rings overlay
            Image("Vector")
                .resizable()
                .scaledToFit()
                .opacity(0.35)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 180)

            VStack(spacing: 24) {
                // Top brand row
                HStack(spacing: 8) {
                    Image(systemName: "shield.fill")
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Crime Map")
                        .font(.headline.weight(.semibold))
                        .tracking(1.0)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 24)
                .padding(.horizontal)

                Spacer(minLength: 20)

                // Center emblem
                Image(systemName: "checkmark.shield")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(.white)
                    .padding(.top, 12)

                Spacer()

                // Big headline group
                VStack(alignment: .center, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("\(displayedTotal)")
                            .font(.system(size: 48, weight: .heavy))
                            .contentTransition(.numericText(value: Double(displayedTotal)))
                            .animation(.easeOut(duration: 0.8), value: displayedTotal)
                            .foregroundStyle(.white)
                        Text("Crimes")
                            .font(.system(size: 48, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    Text("reported near you")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.95))
                    Text("recently")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.95))
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal)

                // Bottom CTA
                VStack(spacing: 14) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onShowAll()
                    } label: {
                        Text("SHOW ALL")
                            .font(.headline)
                            .tracking(1.0)
                            .foregroundStyle(Color.black.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                 
                    .padding(.horizontal)
                    .padding(.bottom, 22)
                }
            }
        }
        .onAppear {
            prewarmMapTiles()
            displayedTotal = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                    displayedTotal = totals.total
                }
            }
        }
        .onChange(of: totals.total) { new in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                displayedTotal = new
            }
        }
    }

    // MARK: - Strings

    private var headline: String {
        if totals.total == 0 {
            return "Good news — no incidents recorded in \(place) recently."
        } else {
            return "Crimes reported near you recently."
        }
    }

    private var accessibilityLine: String {
        "\(totals.total) reports in \(place), data from \(PoliceAPI.humanMonth(monthISO))"
    }
}

// MARK: - Small components

private struct MonthChip: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.blue.opacity(0.12))
            )
            .overlay(
                Capsule().stroke(Color.blue.opacity(0.35), lineWidth: 0.5)
            )
    }
}
