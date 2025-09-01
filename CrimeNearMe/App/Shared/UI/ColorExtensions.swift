//
//  ColorExtensions.swift
//  CrimeNearMe
//
//  Shared color utilities and extensions
//

import SwiftUI

/// Extension to create SwiftUI Color from hexadecimal string values
extension Color {
    /// Initializes a Color from a hexadecimal string
    /// 
    /// Supports hex strings with or without the "#" prefix.
    /// Invalid hex strings will result in black color.
    /// 
    /// - Parameter hex: Hexadecimal color string (e.g., "FF0000", "#FF0000")
    /// 
    /// Example usage:
    /// ```swift
    /// let red = Color(hex: "FF0000")
    /// let blue = Color(hex: "#0000FF")
    /// ```
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        
        self.init(red: r, green: g, blue: b)
    }
}