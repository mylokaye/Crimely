//
//  LoadingView.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//

import SwiftUI

struct LoadingView: View {
    @State private var currentIndex = 0
    
    private let messages = [
        "Querying regional crime reports…",
        "Matching reported incidents with police categories…",
        "Plotting crime locations onto the map…",
        "Checking crimes reported recently…",
        "Calculating area safety index…",
        "Combining police and public safety datasets…",
        "Encrypting request over secure police API…",
        "Preparing crime insights for display…"
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "8E97FD").ignoresSafeArea()
            
            Text(messages[currentIndex])
                .multilineTextAlignment(.center)
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .onAppear { startCycling() }
        }
    }
    
    private func startCycling() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            withAnimation(.easeInOut) {
                currentIndex = (currentIndex + 1) % messages.count
            }
        }
    }
}

// MARK: - Helpers

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") { hexSanitized.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
