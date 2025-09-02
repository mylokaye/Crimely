//
//  AttributionFooter.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//

import SwiftUI

/// Footer component displaying data attribution and licensing information
/// 
/// This view shows required attribution for UK Police data under the Open Government Licence.
/// Tapping the text opens the official licence documentation in the user's browser.
struct AttributionFooter: View {
    var body: some View {
        Text("Contains public sector information licensed under the Open Government Licence v3.0")
            .font(.footnote)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
            .onTapGesture {
                // Open the official Open Government Licence documentation
                if let url = URL(string: "https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/") {
                    UIApplication.shared.open(url)
                }
            }
    }
}