import SwiftUI
import CoreLocation

// Main tab bar view
struct MainTabView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var appState: AppState = .welcome

    var body: some View {
        TabView {
            SummaryWithMapView()
            .tabItem {
                Label("Map", systemImage: "map")
            }

            InfoView()
            .tabItem {
                Label("Info", systemImage: "info.circle")
            }
            
            LoadingView()
                .tabItem {
                    Label("Loading", systemImage: "info.circle")
                }
        }
        .onAppear {
            locationManager.request()
        }
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

struct SummaryWithMapView: View {
    var body: some View {
        VStack(spacing: -10) {
            Divider() // Divider separates the map from the top content
            // Top spacing of the map is implicitly set by the Divider above
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
}
