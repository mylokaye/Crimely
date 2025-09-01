import SwiftUI
import CoreLocation

/// The main entry point for the CrimeNearMe iOS application.
/// 
/// This app displays crime statistics for the Manchester area using data from the UK Police API.
/// It manages user onboarding, location permissions, and navigation between different app states.
@main
struct CrimeNearMeApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("lastLatitude") private var lastLatitude: Double = Defaults.manchesterCenter.latitude
    @AppStorage("lastLongitude") private var lastLongitude: Double = Defaults.manchesterCenter.longitude
    @State private var appState: AppState = .welcome
    @StateObject private var locationManager = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            RootView(appState: $appState)
                .onAppear {
                    // Check if user has already completed onboarding
                    if hasCompletedOnboarding {
                        // Skip welcome and go straight to loading
                        appState = .loading
                        loadLatestData()
                    }
                }
                .onChange(of: appState) { newState in
                    // Mark onboarding as complete and save location when we move past welcome
                    if case .city(let anchor, _, _, _, _) = newState, !hasCompletedOnboarding {
                        hasCompletedOnboarding = true
                        saveLastLocation(anchor)
                    }
                }
        }
    }
    
    /// Saves the user's current location coordinates to persistent storage
    /// - Parameter coordinate: The location coordinate to save
    private func saveLastLocation(_ coordinate: CLLocationCoordinate2D) {
        lastLatitude = coordinate.latitude
        lastLongitude = coordinate.longitude
    }
    
    /// Retrieves the last known location from persistent storage
    /// - Returns: The last saved location coordinate, or Manchester center as fallback
    private var lastKnownLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lastLatitude, longitude: lastLongitude)
    }
    
    /// Loads the latest crime data for the user's location
    /// 
    /// This method handles the complete data loading flow:
    /// 1. Attempts to get fresh location from LocationManager
    /// 2. Falls back to stored location if needed
    /// 3. Fetches crime data from the Police API
    /// 4. Processes and categorizes the crime data
    /// 5. Updates the app state with the results
    private func loadLatestData() {
        Task {
            // Add a small delay to show loading screen
            try? await Task.sleep(for: .milliseconds(300))
            
            // Try to get fresh location, fallback to stored location
            locationManager.request()
            
            // Wait a bit for location update
            var anchor = lastKnownLocation
            let start = Date()
            while locationManager.coordinate == nil && Date().timeIntervalSince(start) < 2 {
                try? await Task.sleep(for: .milliseconds(150))
            }
            
            if let freshLocation = locationManager.coordinate {
                anchor = clampToManchesterIfNeeded(freshLocation)
                saveLastLocation(anchor)
            }
            
            do {
                let (months, crimes) = try await PoliceAPI.shared.crimesLastMonths(
                    monthsBack: 6,
                    polys: Defaults.manchesterPolys,
                    from: Date()
                )
                
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
                let byCategory = CategoryGrouping.groupedCounts(from: crimes)
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        appState = .map(
                            anchor: anchor,
                            totals: totals,
                            monthISO: monthISO,
                            place: place,
                            byCategory: byCategory
                        )
                    }
                }
            } catch {
                // Fallback to placeholder data
                let placeholderTotals = Totals(total: 0, serious: 0)
                let placeholderMonth = PoliceAPI.isoMonth(Date())
                let placeholderPlace = await PlaceResolver.shared.resolvePlaceName(for: anchor)
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        appState = .map(
                            anchor: anchor,
                            totals: placeholderTotals,
                            monthISO: placeholderMonth,
                            place: placeholderPlace,
                            byCategory: []
                        )
                    }
                }
                AppLogger.error.error("Failed to load data on app launch: \(error.localizedDescription)")
            }
        }
    }
    
    /// Ensures the coordinate is within Manchester boundaries, clamps to center if outside
    /// - Parameter c: The coordinate to validate
    /// - Returns: The validated coordinate or Manchester center if outside bounds
    private func clampToManchesterIfNeeded(_ c: CLLocationCoordinate2D?) -> CLLocationCoordinate2D {
        guard let c = c else { return Defaults.manchesterCenter }
        if c.latitude < Defaults.manchesterBBox.minLat ||
            c.latitude > Defaults.manchesterBBox.maxLat ||
            c.longitude < Defaults.manchesterBBox.minLon ||
            c.longitude > Defaults.manchesterBBox.maxLon {
            return Defaults.manchesterCenter
        }
        return c
    }
}
