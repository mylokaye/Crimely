import SwiftUI
import CoreLocation

/// The root view component that manages navigation between different app states
/// 
/// This view acts as the main navigation controller, rendering different screens
/// based on the current AppState. It handles transitions between welcome, loading,
/// city summary, and map views.
struct RootView: View {
    /// Binding to the current application state
    @Binding var appState: AppState
    
    /// Location manager instance for handling location updates
    @StateObject private var locationManager = LocationManager()

    /// Ensures coordinates are within Manchester boundaries
    /// - Parameter c: Optional coordinate to validate
    /// - Returns: Valid coordinate within Manchester bounds or Manchester center as fallback
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
        MainTabView()
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

        Group {
            RootView(appState: .constant(.welcome))
                .previewDisplayName("Welcome State")
            
            RootView(appState: .constant(.loading))
                .previewDisplayName("Loading State")
            
            RootView(appState: .constant(.city(anchor: anchor,
                                               totals: totals,
                                               monthISO: "2025-06",
                                               place: "Manchester",
                                               byCategory: byCategory)))
                .previewDisplayName("City State")
        }
    }
}
