//
//  WelcomeView.swift
//  CrimeNearMe
//
//  Welcome and onboarding screen with location permission request
//

import SwiftUI
import CoreLocation

/// Brand color constants used throughout the welcome flow
private enum Brand {
    /// Primary brand blue color (#8E97FD)
    static let base = Color(red: 142/255, green: 151/255, blue: 253/255)
    
    /// Darker variant of brand blue (#7F88F0)
    static let baseDark = Color(red: 127/255, green: 136/255, blue: 240/255)
    
    /// Button accent color - warm yellow (#FFE1B3)
    static let button = Color(red: 255/255, green: 225/255, blue: 179/255)
}

/// Welcome screen that handles user onboarding and location permission requests
/// 
/// This view presents the initial app interface with brand messaging and guides
/// users through location permission setup. It automatically fetches crime data
/// once permission is granted and transitions to the city summary view.
struct WelcomeView: View {
    /// Location manager for handling permission requests and coordinate updates
    @ObservedObject var locationManager: LocationManager
    
    /// Binding to the current application state for navigation
    @Binding var appState: AppState
    
    /// Loading state indicator for button and UI updates
    @State private var isLoading = false
    
    /// Controls button interactivity during location processing
    @State private var buttonEnabled = true
    
    /// Controls display of data attribution sheet
    @State private var showAttribution = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(colors: [Brand.base, Brand.baseDark], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            // Concentric vector overlay (bottom)
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

                // Headline
                VStack(alignment: .leading, spacing: 8) {
                    // "Find crimes in your local area" with bold 'crimes'
                    Text(highlightedHeadline)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Bottom card with CTA and note
                VStack(spacing: 14) {
                    Button {
                        Task { await handleButtonTap() }
                    } label: {
                        Text(primaryButtonTitle)
                            .font(.headline)
                            .tracking(0.5)
                            .foregroundStyle(Color.black.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Brand.button)
                    )
                    .padding(.horizontal)
                    .disabled(!buttonEnabled || isLoading)
                    .overlay(alignment: .center) {
                        if isLoading { ProgressView().tint(.black).frame(height: 56) }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.white.opacity(0.9))
                        Text("We use your location to show crimes near you.")
                            .foregroundStyle(.white.opacity(0.9))
                            .font(.callout)
                    }
                    .padding(.bottom, 22)
                }
                .background(Color.white.opacity(0.0))
            }
        }
        .sheet(isPresented: $showAttribution) {
            VStack(spacing: 12) {
                Spacer()
                Text("Sources")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.blue)
                Text("Data from data.police.uk (Open Government Licence)")
                    .font(.system(size: 15))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .presentationDetents([.fraction(0.33)])
            .presentationDragIndicator(.hidden)
        }
    }
    
    /// Creates attributed string with emphasized "crimes" text
    private var highlightedHeadline: AttributedString {
        var s = AttributedString("Find crimes in your local area")
        if let range = s.range(of: "crimes") {
            s[range].font = .system(size: 34, weight: .heavy)
        }
        return s
    }

    /// Dynamic button title based on current app state
    private var primaryButtonTitle: String {
        switch appState {
        case .welcome: return "ALLOW LOCATION ACCESS"
        default: return "NEXT"
        }
    }
    
    /// Accessibility label for the primary button
    private var buttonLabel: String {
        switch appState {
        case .welcome: return "Allow location"
        default: return "Next"
        }
    }
    
    /// Handles the main button tap action for location permission and data loading
    /// 
    /// This method orchestrates the complete onboarding flow:
    /// 1. Requests location permission from the user
    /// 2. Waits for coordinate response with timeout
    /// 3. Validates coordinates are within Manchester bounds
    /// 4. Shows placeholder city summary immediately
    /// 5. Fetches real crime data in background
    /// 6. Updates the city summary with actual data
    private func handleButtonTap() async {
        print("handleButtonTap fired; state=\(appState)")
        switch appState {
        case .welcome:
            buttonEnabled = false
            isLoading = true
            locationManager.request()
            
            // Wait up to ~3s for a coordinate, then clamp/fallback to Manchester
            var coord = locationManager.coordinate
            let start = Date()
            while coord == nil && Date().timeIntervalSince(start) < 3 {
                try? await Task.sleep(for: .milliseconds(150))
                coord = locationManager.coordinate
            }
            let anchor = validateManchesterCoordinate(coord)
            AppLogger.location.debug("Location resolved to: \(anchor.latitude), \(anchor.longitude)")
            
            // Immediately route to City Summary with placeholders to avoid flashing the map
            let placeholderTotals = Totals(total: 0, serious: 0)
            let placeholderMonth = PoliceAPI.isoMonth(Date())
            let placeholderPlace = await PlaceResolver.shared.resolvePlaceName(for: anchor)
            withAnimation(.easeInOut) {
                appState = .city(
                    anchor: anchor,
                    totals: placeholderTotals,
                    monthISO: placeholderMonth,
                    place: placeholderPlace,
                    byCategory: []
                )
            }

            // Continue computing real data in the background, then refresh the City Summary
            Task {
                do {
                    let (months, crimes) = try await PoliceAPI.shared.crimesLastMonths(
                        monthsBack: 6,
                        polys: Defaults.manchesterPolys,
                        from: Date()
                    )
                    AppLogger.api.debug("Months queried: \(months), total crimes: \(crimes.count)")
                    let monthISO = months.first ?? PoliceAPI.isoMonth(Date())

                    let seriousCount = crimes.filter { crime in
                        if let spec = CategoryGrouping.mapping[crime.category] {
                            return spec.isSerious
                        }
                        let label = crime.category.replacingOccurrences(of: "-", with: " ").capitalized
                        return CategoryGrouping.isSeriousGroup(label)
                    }.count
                    let totals = Totals(total: crimes.count, serious: seriousCount)
                    let place = await PlaceResolver.shared.resolvePlaceName(for: anchor)

                    // Build byCategory using display groups
                    let byCategory: [CategoryCount] = CategoryGrouping.groupedCounts(from: crimes)

                    await MainActor.run {
                        appState = .city(anchor: anchor, totals: totals, monthISO: monthISO, place: place, byCategory: byCategory)
                    }
                } catch {
                    // Leave placeholder city summary; optionally show a small error chip there
                    AppLogger.error.error("Failed to fetch crime data: \(error.localizedDescription)")
                }
            }
            
            isLoading = false
            buttonEnabled = true
            
        default:
            break
        }
    }
}

/// Validates that coordinates are within Manchester boundaries
/// - Parameter c: Optional coordinate to validate
/// - Returns: Valid Manchester coordinate or center as fallback
private func validateManchesterCoordinate(_ c: CLLocationCoordinate2D?) -> CLLocationCoordinate2D {
    guard let c = c else { return Defaults.manchesterCenter }
    if c.latitude < Defaults.manchesterBBox.minLat ||
        c.latitude > Defaults.manchesterBBox.maxLat ||
        c.longitude < Defaults.manchesterBBox.minLon ||
        c.longitude > Defaults.manchesterBBox.maxLon {
        return Defaults.manchesterCenter
    }
    return c
}

// MARK: - Preview
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(locationManager: LocationManager(),
                    appState: .constant(.welcome))
        .previewDisplayName("Welcome Preview")
    }
}
