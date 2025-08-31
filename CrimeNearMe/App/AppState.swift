//
//  AppState.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//

import CoreLocation

enum AppState: Equatable {
    case welcome        // first screen - asks for permission
    case city(anchor: CLLocationCoordinate2D, totals: Totals, monthISO: String, place: String, byCategory: [CategoryCount])
    case map(anchor: CLLocationCoordinate2D, totals: Totals, monthISO: String, place: String, byCategory: [CategoryCount])

    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.welcome, .welcome):
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

struct Totals: Equatable {
    let total: Int
    let serious: Int
}
