//
//  CategoryGrouping.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//

import Foundation

/// Handles mapping and grouping of UK Police API crime categories
/// 
/// The UK Police API provides detailed crime categories with hyphenated names
/// (e.g., "violent-crime", "theft-from-the-person"). This enum maps these to 
/// user-friendly display groups and classifies their severity level.
enum CategoryGrouping {
    /// Specification for a crime category group
    struct GroupSpec: Hashable {
        /// Display name for the grouped category
        let name: String
        
        /// Whether this category is considered serious/high-priority
        let isSerious: Bool
    }

    /// Maps raw police.uk category IDs to display groups and severity classification
    /// 
    /// Categories marked as serious include violent crimes, robbery, and drug/weapon offenses.
    /// Less serious categories include theft, public order, and vehicle crimes.
    static let mapping: [String: GroupSpec] = [
        // Robbery-related crimes (serious)
        "robbery": GroupSpec(name: "Robbery", isSerious: true),
        "theft-from-the-person": GroupSpec(name: "Robbery", isSerious: true),

        // Theft & Shoplifting (non-serious property crimes)
        "bicycle-theft": GroupSpec(name: "Theft & Shoplifting", isSerious: false),
        "shoplifting": GroupSpec(name: "Theft & Shoplifting", isSerious: false),

        // Vehicle-related crimes (non-serious property crimes)
        "vehicle-crime": GroupSpec(name: "Vehicle crime", isSerious: false),

        // Violence (serious personal crimes)
        "violent-crime": GroupSpec(name: "Violence", isSerious: true),

        // Other/miscellaneous crimes (generally non-serious)
        "other-crime": GroupSpec(name: "Other", isSerious: false),
        "other-theft": GroupSpec(name: "Other", isSerious: false),

        // Public order and anti-social behavior (non-serious)
        "public-order": GroupSpec(name: "Public order", isSerious: false),
        "anti-social-behaviour": GroupSpec(name: "Public order", isSerious: false),

        // Drugs & Weapons (serious due to public safety implications)
        "drugs": GroupSpec(name: "Drugs & Weapons", isSerious: true),
        "possession-of-weapons": GroupSpec(name: "Drugs & Weapons", isSerious: true),

        // Burglary & Arson (property crimes, moderate severity)
        "burglary": GroupSpec(name: "Burglary & Arson", isSerious: false),
        "criminal-damage-arson": GroupSpec(name: "Burglary & Arson", isSerious: false)
    ]

    /// Groups crimes by category and returns sorted counts
    /// 
    /// Takes a list of raw crimes and groups them into user-friendly categories.
    /// Unknown categories are converted to title-case display names.
    /// 
    /// - Parameter crimes: Array of Crime objects to group
    /// - Returns: Array of CategoryCount objects sorted by count (highest first)
    static func groupedCounts(from crimes: [Crime]) -> [CategoryCount] {
        var buckets: [String: Int] = [:]
        for c in crimes {
            if let spec = mapping[c.category] {
                buckets[spec.name, default: 0] += 1
            } else {
                // Fallback: convert raw category to title-case for display
                let fallback = c.category.replacingOccurrences(of: "-", with: " ").capitalized
                buckets[fallback, default: 0] += 1
            }
        }
        return buckets.map { CategoryCount(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    /// Determines if a display group name represents serious crimes
    /// 
    /// This is used for UI styling and prioritization - serious crimes
    /// may be highlighted or counted separately in statistics.
    /// 
    /// - Parameter name: Display name of the crime category group
    /// - Returns: True if the category represents serious crimes
    static func isSeriousGroup(_ name: String) -> Bool {
        let seriousGroups: Set<String> = ["Robbery", "Violence", "Drugs & Weapons"]
        return seriousGroups.contains(name)
    }
}