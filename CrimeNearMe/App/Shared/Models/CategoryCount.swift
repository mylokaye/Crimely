//
//  CategoryCount.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//


// START FILE: Shared/Models/CategoryCount.swift
import Foundation

struct CategoryCount: Identifiable, Hashable {
    let id: String
    let category: String
    let count: Int

    init(category: String, count: Int) {
        self.id = category
        self.category = category
        self.count = count
    }
}
// END FILE: Shared/Models/CategoryCount.swift