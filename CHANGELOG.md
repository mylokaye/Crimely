# CrimesNearMe

An iOS app that shows recent crime data in your local area, helping you stay informed about safety in your neighborhood.

## What it does

CrimesNearMe is a location-based iOS application that:

- **Finds crimes near you**: Uses your current location to fetch and display recent crime reports in your area
- **Shows crime statistics**: Provides a summary of total incidents and highlights serious crimes
- **Interactive map view**: Displays crime locations on an interactive map with detailed information
- **Crime categorization**: Organizes crimes by type and severity for easy understanding
- **Location-focused**: Currently optimized for the Manchester area in the UK

## Features

### 🛡️ Safety-First Design
- Clean, intuitive interface focused on presenting crime data clearly
- Privacy-conscious location usage (only when the app is in use)
- Reliable data from official government sources

### 📍 Location Services
- Requests location permission on first launch
- Remembers your last location for faster subsequent launches
- Falls back to Manchester city center if location is unavailable

### 📊 Crime Data Visualization
- **Welcome Screen**: Initial onboarding and location permission request
- **City Summary**: Overview of recent crime statistics in your area
- **Interactive Map**: Detailed view showing crime locations and categories
- **Historical Data**: Shows crime data from recent months when available

### 🏛️ Official Data Source
- Uses the UK Police API (data.police.uk) for accurate, up-to-date crime information
- Data is provided under the Open Government Licence
- Covers various crime categories including theft, violence, anti-social behavior, and more

## How it works

1. **Launch**: The app asks for location permission to show relevant crime data
2. **Data Fetching**: Retrieves recent crime reports from the UK Police API for your area
3. **Analysis**: Categorizes crimes by type and identifies serious incidents
4. **Display**: Shows crime statistics in an easy-to-understand format
5. **Map View**: Provides detailed geographic visualization of crime locations

## Technical Details

- **Platform**: iOS (Swift/SwiftUI)
- **Location Services**: Core Location framework
- **Data Source**: UK Police API (data.police.uk)
- **Geographic Scope**: Currently focused on Manchester, UK area
- **Data Coverage**: Shows crimes from recent months (up to 6 months back)

## Privacy

- Location data is only used to fetch relevant crime information
- Location is only accessed when the app is in use
- No personal data is stored or transmitted beyond what's necessary for the app's function
- All crime data comes from publicly available government sources

## Data Attribution

Crime data provided by data.police.uk under the Open Government Licence.

## Changelog Workflow

Every time you make a significant change and commit/tag:
1. Open `CHANGELOG.md` and add a new entry using the template at the top.
2. Stage all changes (including the changelog):
   ```bash
   git add .
   ```
3. Commit with a descriptive message:
   ```bash
   git commit -m "Describe your change and update CHANGELOG"
   ```
4. Tag the commit:
   ```bash
   git tag vX.Y-feature-or-fix
   ```
5. Push the commit and tag:
   ```bash
   git push origin main --tags
   ```

This ensures your changelog always reflects the latest changes and tags. See `CHANGELOG.md` for the template and examples.
