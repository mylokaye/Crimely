//
//  AppState.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//

import CoreLocation

/// Represents the different states of the application navigation flow
/// 
/// The app follows a linear flow: welcome → loading → city summary → map view
enum AppState: Equatable {
    /// Initial welcome screen that requests location permission from the user
    case welcome
    
    /// Loading screen shown while fetching crime data from the API
    case loading
    
    /// City summary screen displaying crime statistics overview
    /// - anchor: The geographic center point for the data
    /// - totals: Overall crime count statistics
    /// - monthISO: The month for which data is displayed (YYYY-MM format)
    /// - place: Human-readable place name (e.g., "Manchester")
    /// - byCategory: Crime counts broken down by category
    case city(anchor: CLLocationCoordinate2D, totals: Totals, monthISO: String, place: String, byCategory: [CategoryCount])
    
    /// Map view showing detailed crime locations and categories
    /// - anchor: The geographic center point for the data
    /// - totals: Overall crime count statistics  
    /// - monthISO: The month for which data is displayed (YYYY-MM format)
    /// - place: Human-readable place name (e.g., "Manchester")
    /// - byCategory: Crime counts broken down by category
    case map(anchor: CLLocationCoordinate2D, totals: Totals, monthISO: String, place: String, byCategory: [CategoryCount])

    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.welcome, .welcome):
            return true
        case (.loading, .loading):
            return true
        case let (.city(la, lt, lm, lp, lbc), .city(ra, rt, rm, rp, rbc)):
            return la.latitude == ra.latitude &&
                   la.longitude == ra.longitude &&
                   lt == rt &&
                   lm == rm &&
                   lp == rp &&
                   lbc == rbc
        case let (.map(la, lt, lm, lp, lbc), .map(ra, rt, rm, rp, rbc)):
            return la.latitude == ra.latitude &&
                   la.longitude == ra.longitude &&
                   lt == rt &&
                   lm == rm &&
                   lp == rp &&
                   lbc == rbc
        default:
            return false
        }
    }
}

/// Represents aggregate crime count statistics
/// 
/// This structure holds both total crime counts and the subset that are considered serious crimes
struct Totals: Equatable {
    /// Total number of reported crimes
    let total: Int
    
    /// Number of crimes classified as serious (e.g., violence, robbery, drugs & weapons)
    let serious: Int
}
