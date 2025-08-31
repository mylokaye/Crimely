//
//  LoadingView.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//

import SwiftUI

struct LoadingView: View {
    @State private var currentIndex = 0
    @State private var progress: Double = 0
    @State private var dotAnimation = false
    @State private var shieldPulse = false
    
    private let messages = [
        "Querying regional crime reports",
        "Matching reported incidents",
        "Checking recent reported crimes",
        "Calculating area safety index",
        "Eliminating duplicate incidents",
        "Combining police safety datasets",
        "Encrypting requests over police API"
    ]
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(hex: "2D4A8B"),
                    Color(hex: "4A6BAE"),
                    Color(hex: "6B7ED6"),
                    Color(hex: "8E97FD"),
                    Color(hex: "B57FDD"),
                    Color(hex: "E291AA"),
                    Color(hex: "FF9A9E")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // MARK: - Text Animation Feature
                // Feature starts here
                VStack(spacing: 30) {
                    Text(messages[currentIndex])
                        .multilineTextAlignment(.center)
                        .font(.custom("Merriweather-var", size: 20).weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .frame(width: 320, height: 100)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(3)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.95).combined(with: .opacity).combined(with: .blur(radius: 2)),
                                removal: .scale(scale: 1.05).combined(with: .opacity).combined(with: .blur(radius: 2))
                            )
                        )
                // Feature ends here
                    
                    // MARK: - Loading Dots Animation
                    // Feature starts here
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 10, height: 10)
                                .scaleEffect(dotAnimation ? 1.4 : 0.6)
                                .opacity(dotAnimation ? 1.0 : 0.3)
                                .animation(
                                    Animation.spring(response: 0.4, dampingFraction: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.15),
                                    value: dotAnimation
                                )
                        }
                    }
                    // Feature ends here
                }
                
                Spacer()
            }
            
            // Shield icon in top right
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {}) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "2D4A8B").opacity(0.15))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: "2D4A8B").opacity(0.2), lineWidth: 1)
                                )
                                .scaleEffect(shieldPulse ? 1.05 : 1.0)
                                .animation(
                                    Animation.spring(response: 3.0, dampingFraction: 0.8)
                                        .repeatForever(autoreverses: true),
                                    value: shieldPulse
                                )
                            
                            Image(systemName: "shield.checkered")
                                .font(.title2)
                                .foregroundColor(Color(hex: "2D4A8B"))
                        }
                    }
                    .padding(.trailing, 24)
                }
                .padding(.top, 20)
                
                Spacer()
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Start text cycling with smooth transitions
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3)) {
                currentIndex = (currentIndex + 1) % messages.count
            }
        }
        
        // Start dot animation with slight delay for smoothness
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dotAnimation = true
        }
        
        // Start shield pulse with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            shieldPulse = true
        }
    }
}

// MARK: - Custom Progress View Style

struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 4)
                
                // Progress fill with shimmer effect
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.8),
                                Color.white,
                                Color.white.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0),
                        height: 4
                    )
                    .overlay(
                        // Shimmer overlay
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.6),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 50)
                        .offset(x: -25)
                        .animation(
                            Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                            value: configuration.fractionCompleted
                        )
                    )
            }
        }
    }
}

// MARK: - Custom Transitions

private struct BlurTransitionModifier: ViewModifier {
    let radius: CGFloat
    func body(content: Content) -> some View {
        content.blur(radius: radius)
    }
}

extension AnyTransition {
    static func blur(radius: CGFloat) -> AnyTransition {
        .modifier(
            active: BlurTransitionModifier(radius: radius),
            identity: BlurTransitionModifier(radius: 0)
        )
    }
}

// MARK: - Helpers

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") {
            hexSanitized.removeFirst()
        }
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
            .previewDevice("iPhone 15 Pro")
            .previewDisplayName("iPhone 15 Pro")
        
        LoadingView()
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE")
        
        LoadingView()
            .previewDevice("iPad Pro (11-inch)")
            .previewDisplayName("iPad Pro")
    }
}
