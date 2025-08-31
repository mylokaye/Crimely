//
//  CrimeCache.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//


import Foundation

final class CrimeCache {
    static let shared = CrimeCache()
    private var store: [String: [Crime]] = [:]

    private func key(lat: Double, lon: Double, month: String) -> String {
        "\(round(lat*1000)/1000),\(round(lon*1000)/1000),\(month)"
    }

    func get(lat: Double, lon: Double, month: String) -> [Crime]? {
        store[key(lat: lat, lon: lon, month: month)]
    }

    func set(lat: Double, lon: Double, month: String, crimes: [Crime]) {
        store[key(lat: lat, lon: lon, month: month)] = crimes
    }
}