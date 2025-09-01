import SwiftUI
import CoreLocation

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
    
    private func saveLastLocation(_ coordinate: CLLocationCoordinate2D) {
        lastLatitude = coordinate.latitude
        lastLongitude = coordinate.longitude
    }
    
    private var lastKnownLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lastLatitude, longitude: lastLongitude)
    }
    
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
                print("ERROR loading data on app launch:", error.localizedDescription)
            }
        }
    }
    
    // Helper function
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
