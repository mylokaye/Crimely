import SwiftUI

@main
struct CrimeNearMeApp: App {
    @State private var appState: AppState = .welcome
    var body: some Scene {
        WindowGroup {
            RootView(appState: $appState)
        }
    }
}
