//
//  CrimeCache.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//

import Foundation

/// Simple in-memory cache for crime data to reduce API calls
/// 
/// This cache stores crime data by location and month to avoid redundant
/// API requests during a single app session. The cache key combines
/// rounded coordinates with the month to provide reasonable granularity.
final class CrimeCache {
    /// Shared singleton instance
    static let shared = CrimeCache()
    
    /// In-memory storage dictionary mapping cache keys to crime arrays
    private var store: [String: [Crime]] = [:]

    /// Generates a cache key from coordinates and month
    /// 
    /// Coordinates are rounded to 3 decimal places (~110 meter precision)
    /// to allow for slight coordinate variations while maintaining locality.
    /// 
    /// - Parameters:
    ///   - lat: Latitude coordinate
    ///   - lon: Longitude coordinate
    ///   - month: Month string in YYYY-MM format
    /// - Returns: Cache key string
    private func key(lat: Double, lon: Double, month: String) -> String {
        "\(round(lat*1000)/1000),\(round(lon*1000)/1000),\(month)"
    }

    /// Retrieves cached crime data for the specified location and month
    /// - Parameters:
    ///   - lat: Latitude coordinate
    ///   - lon: Longitude coordinate
    ///   - month: Month string in YYYY-MM format
    /// - Returns: Cached crime array or nil if not found
    func get(lat: Double, lon: Double, month: String) -> [Crime]? {
        store[key(lat: lat, lon: lon, month: month)]
    }

    /// Stores crime data in the cache for the specified location and month
    /// - Parameters:
    ///   - lat: Latitude coordinate
    ///   - lon: Longitude coordinate
    ///   - month: Month string in YYYY-MM format
    ///   - crimes: Array of crimes to cache
    func set(lat: Double, lon: Double, month: String, crimes: [Crime]) {
        store[key(lat: lat, lon: lon, month: month)] = crimes
    }
}