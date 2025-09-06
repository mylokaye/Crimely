import SwiftUI

/// A struct to centralize customization options for the CrimeDataCard.
struct CrimeDataCardStyle {
    // MARK: - Expanded State

    /// Background color for the expanded state.
    static let expandedBackgroundColor: Color = Color.white.opacity(0)


    /// Grabber bar color for the expanded state.
    static let grabberBarExpandedColor: Color = Color.black.opacity(0.18)

    // MARK: - Collapsed State

    /// Background color for the collapsed state.
    static let collapsedBackgroundColor: Color = Color.blue.opacity(0)


    /// Grabber bar color for the collapsed state.
    static let grabberBarCollapsedColor: Color = Color.black.opacity(0.08)

    // MARK: - Effects

    /// Glass effect style for the card.
    @available(iOS 17.0, *)
    static let glassEffectStyle: Material = .regular
    
    
    
    
    // MARK: - Typography / Spacing
    /// Vertical padding for the city name when the card is collapsed
    static let collapsedCityVerticalPadding: CGFloat = 12
}
