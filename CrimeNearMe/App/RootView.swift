import SwiftUI
import CoreLocation

struct RootView: View {
    @Binding var appState: AppState
    @StateObject private var locationManager = LocationManager()

    // Helper: clamp to Manchester if needed
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

    var body: some View {
        NavigationStack {
            switch appState {
            case .welcome:
                WelcomeView(locationManager: locationManager, appState: $appState)

            case .city(let anchor, let totals, let monthISO, let place, let byCategory):
                
                
                CitySummaryView(anchor: anchor,
                                totals: totals,
                                monthISO: monthISO,
                                place: place) {
                    appState = .map(anchor: anchor,
                                    totals: totals,
                                    monthISO: monthISO,
                                    place: place,
                                    byCategory: byCategory)
                }

            case .map(let anchor, let totals, let monthISO, let place, let byCategory):
                MapView(anchor: anchor,
                        totals: totals,
                        monthISO: monthISO,
                        place: place,
                        byCategory: byCategory)
            }
        }
    }
}

// MARK: - Preview

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample data for previews
        let anchor = CLLocationCoordinate2D(latitude: 53.4794, longitude: -2.2453)
        let totals = Totals(total: 16, serious: 3)
        let byCategory: [CategoryCount] = [
            CategoryCount(category: "Violence", count: 5),
            CategoryCount(category: "Other", count: 4),
            CategoryCount(category: "Public order", count: 3),
            CategoryCount(category: "Robbery", count: 2),
            CategoryCount(category: "Vehicle crime", count: 2)
        ]

        RootView(appState: .constant(.city(anchor: anchor,
                                           totals: totals,
                                           monthISO: "2025-06",
                                           place: "Manchester",
                                           byCategory: byCategory)))
        
        
    }
    
    
}
