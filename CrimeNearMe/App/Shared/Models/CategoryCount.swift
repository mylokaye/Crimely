//
//  CategoryCount.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//

import Foundation

/// Represents the count of crimes for a specific category
/// 
/// This structure is used to display crime statistics grouped by category type.
/// Categories are display-friendly groupings (e.g., "Violence", "Robbery") 
/// rather than raw API categories (e.g., "violent-crime", "theft-from-the-person").
struct CategoryCount: Identifiable, Hashable {
    /// Unique identifier (same as category name for simplicity)
    let id: String
    
    /// Display name of the crime category (e.g., "Violence", "Vehicle crime")
    let category: String
    
    /// Number of crimes reported in this category
    let count: Int

    /// Creates a new category count
    /// - Parameters:
    ///   - category: The display name of the crime category
    ///   - count: The number of crimes in this category
    init(category: String, count: Int) {
        self.id = category
        self.category = category
        self.count = count
    }
}