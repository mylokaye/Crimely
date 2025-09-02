# CrimeNearMe iOS Application

CrimeNearMe is an iOS app built with SwiftUI that displays crime data near the user's location using the UK Police API. The app targets iOS 26.0 and provides interactive maps and summaries of local crime statistics.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Platform Requirements
- **macOS with Xcode required** for building, testing, and running the app
- **Linux environment limitations**: Can only compile Foundation-based code (models, API classes) but NOT SwiftUI, CoreLocation, or UIKit components
- Swift 6.1.2+ available on Linux for limited testing of non-UI components

### Building and Testing on macOS
- **NEVER CANCEL builds or tests** - iOS builds can take 5-15 minutes, tests can take 3-8 minutes
- Bootstrap and build the app:
  - Open `CrimeNearMe.xcodeproj` in Xcode
  - Select "CrimeNearMe" scheme
  - `xcodebuild -scheme CrimeNearMe -project CrimeNearMe.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 15' build` -- takes 5-15 minutes. NEVER CANCEL. Set timeout to 30+ minutes.
- Run unit tests:
  - `xcodebuild test -scheme CrimeNearMe -project CrimeNearMe.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 15'` -- takes 3-8 minutes. NEVER CANCEL. Set timeout to 20+ minutes.
- Run UI tests:
  - UI tests are in `CrimeNearMeUITests/` and test app launch and basic navigation
  - Use same command as unit tests - both test targets run together

### Running the App
- **ALWAYS run the building steps first**
- Run in iOS Simulator:
  - Open `CrimeNearMe.xcodeproj` in Xcode
  - Select iPhone simulator (iPhone 15 or later)
  - Press Run (⌘R) or use `xcodebuild -scheme CrimeNearMe -project CrimeNearMe.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 15' -allowProvisioningUpdates`
- Location simulation:
  - Uses `manchester.gpx` file for simulated location data in Manchester, UK
  - Enable location simulation in Xcode's Debug menu → Location → Custom Location or GPX file

### Limited Testing on Linux
- Can compile Foundation-only components like models and API classes
- Cannot build SwiftUI, CoreLocation, or UIKit-dependent code
- Example workflow for API testing:
  ```bash
  # Create temporary Swift package for testing Foundation-only code
  mkdir /tmp/api_test && cd /tmp/api_test
  swift package init --type library --name CrimeAPITest
  # Copy Crime.swift, PoliceAPI.swift (remove CoreLocation imports)
  swift build  # Takes ~5-30 seconds
  swift test   # Takes ~10-60 seconds
  ```

## Validation

### Manual Validation Requirements
- **ALWAYS manually test app functionality after making changes**
- **CRITICAL**: Run through complete user scenarios, not just app launch
- Essential validation workflow:
  1. App launches and shows welcome screen with location permission prompt
  2. Grant location permission → app shows loading screen
  3. Loading completes → displays crime summary for Manchester area
  4. Tap summary cards → navigates to detailed map view
  5. Verify crime data displays correctly with proper categories and counts
  6. Test map interactions (zoom, pan, crime markers)
- **Cannot interact with iOS Simulator UI from Linux** - validation requires macOS environment
- Always test with Manchester location data (default) as the app is geo-restricted to Manchester, UK

### Code Quality Checks
- No specific linters configured - rely on Xcode's built-in Swift warnings and errors
- Check console for debug output from PoliceAPI calls to verify data fetching
- Ensure proper error handling in API calls and location services

## Common Tasks

### Repository Structure
```
.
├── CrimeNearMe.xcodeproj/          # Xcode project file
├── CrimeNearMe/                    # Main app source code
│   ├── App/                        # Core app functionality
│   │   ├── Features/               # UI screens (Welcome, Map, CitySummary)
│   │   ├── Services/               # API and location services
│   │   ├── Shared/                 # Models and utilities
│   │   └── Resources/              # manchester.gpx location file
│   ├── Assets.xcassets             # App icons and images
│   ├── CrimeNearMeApp.swift       # Main app entry point
│   └── Info.plist                 # App configuration
├── CrimeNearMeTests/              # Unit tests
├── CrimeNearMeUITests/            # UI/integration tests
├── .github/workflows/             # CI/CD (iOS and Swift workflows)
├── bg.jpg                         # Background assets
├── welcomepolice                  # Welcome screen asset
└── Merriweather-var.ttf          # Custom font
```

### Key Files to Check When Making Changes
- **App/Services/API/PoliceAPI.swift**: Always test API changes with actual network calls
- **App/Shared/Models/Crime.swift**: Verify JSON parsing with real Police API data
- **CrimeNearMeApp.swift**: Main app logic - check location handling and state management
- **App/Features/Welcome/WelcomeView.swift**: Entry point - verify location permission flow
- **App/Features/Map/MapView.swift**: Core functionality - test map rendering and crime markers

### Debugging Notes
- App includes debug print statements for API calls and location updates
- Check Xcode console for `[DEBUG]` messages during development
- Common issues: location permissions, API rate limits, network connectivity
- App falls back to Manchester city center if location is outside Manchester boundaries

### CI/CD Information
- GitHub Actions runs on `macos-latest`
- Two workflows: `ios.yml` (full iOS build/test) and `swift.yml` (Swift-only)
- Builds use automatic scheme detection and iPhone simulator
- Tests include both unit tests (Swift Testing) and UI tests (XCTest)

## Platform Limitations

### What Works on Linux
- Viewing and editing Foundation-based Swift files
- Basic syntax checking of Swift code
- Limited compilation of models and utility classes
- Git operations and file management

### What Requires macOS
- Full iOS app compilation and linking
- Running any tests that import SwiftUI, CoreLocation, or UIKit
- iOS Simulator for testing actual app functionality
- Xcode-specific features (Interface Builder, asset management)
- Performance profiling and iOS-specific debugging

### What Does NOT Work
- Building the complete iOS app on Linux
- Running iOS Simulator or app on Linux
- Testing location services or map functionality without iOS environment
- UI testing or screenshot capture of the running app
