//
//  CategoryGrouping.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//


import Foundation

enum CategoryGrouping {
    struct GroupSpec: Hashable {
        let name: String
        let isSerious: Bool
    }

    // Map raw police.uk categories → (display group name, isSerious)
    static let mapping: [String: GroupSpec] = [
        // Robbery
        "robbery": GroupSpec(name: "Robbery", isSerious: true),
        "theft-from-the-person": GroupSpec(name: "Robbery", isSerious: true),

        // Theft & Shoplifting
        "bicycle-theft": GroupSpec(name: "Theft & Shoplifting", isSerious: false),
        "shoplifting": GroupSpec(name: "Theft & Shoplifting", isSerious: false),

        // Vehicle crime
        "vehicle-crime": GroupSpec(name: "Vehicle crime", isSerious: false),

        // Violence (renamed from Violent crime)
        "violent-crime": GroupSpec(name: "Violence", isSerious: true),

        // Other
        "other-crime": GroupSpec(name: "Other", isSerious: false),
        "other-theft": GroupSpec(name: "Other", isSerious: false),

        // Public order
        "public-order": GroupSpec(name: "Public order", isSerious: false),
        "anti-social-behaviour": GroupSpec(name: "Public order", isSerious: false),

        // Drugs & Weapons
        "drugs": GroupSpec(name: "Drugs & Weapons", isSerious: true),
        "possession-of-weapons": GroupSpec(name: "Drugs & Weapons", isSerious: true),

        // Burglary & Arson
        "burglary": GroupSpec(name: "Burglary & Arson", isSerious: false),
        "criminal-damage-arson": GroupSpec(name: "Burglary & Arson", isSerious: false)
    ]

    static func groupedCounts(from crimes: [Crime]) -> [CategoryCount] {
        var buckets: [String: Int] = [:]
        for c in crimes {
            if let spec = mapping[c.category] {
                buckets[spec.name, default: 0] += 1
            } else {
                // Fallback: show raw as title-cased bucket
                let fallback = c.category.replacingOccurrences(of: "-", with: " ").capitalized
                buckets[fallback, default: 0] += 1
            }
        }
        return buckets.map { CategoryCount(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    static func isSeriousGroup(_ name: String) -> Bool {
        // Any group that corresponds to at least one serious raw category is serious
        let seriousGroups: Set<String> = ["Robbery", "Violence", "Drugs & Weapons"]
        return seriousGroups.contains(name)
    }
}