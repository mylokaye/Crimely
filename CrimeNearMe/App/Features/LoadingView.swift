//
//  LoadingView.swift
//  CrimeNearMe
//
//  Created by Mylo on 30/08/2025.
//

import SwiftUI

/// Loading screen displayed while fetching crime data from the API
///
/// This view provides an engaging loading experience with animated text messages,
/// pulsing dots, and gradient backgrounds. It cycles through various status messages
/// to give users feedback about the data loading process.
struct LoadingView: View {
    /// Current index in the messages array for text animation
    @State private var currentIndex = 0
    
    /// Progress value for potential progress bar (currently unused)
    @State private var progress: Double = 0
    
    /// Controls the dot loading animation state
    @State private var dotAnimation = false
    
    /// Controls the shield icon pulse animation
    @State private var shieldPulse = false
    
    
    
    /// Array of status messages shown during loading
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
            // Gradient background with slow hue cycling (iOS 18+)
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
            .phaseAnimator([0.0, 1.0]) { content, phase in
                content.hueRotation(.degrees(phase * 360))
            } animation: { _ in
                .linear(duration: 30).repeatForever(autoreverses: false)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // MARK: - Animated Status Messages
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
                    
                    // MARK: - Animated Loading Dots
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
                }
                
                Spacer()
            }
            
            // Shield icon in top right
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {}) {

                        ZStack {
                            // Liquid Glass circle
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    // glass rim
                                    Circle().strokeBorder(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.7),
                                                     Color.white.opacity(0.15),
                                                     Color.white.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                                )
                                .background(
                                    // subtle inner glow
                                    Circle().fill(
                                        RadialGradient(
                                            colors: [Color.white.opacity(0.18),
                                                     Color.white.opacity(0.05),
                                                     .clear],
                                            center: .topLeading,
                                            startRadius: 0,
                                            endRadius: 120
                                        )
                                    )
                                )
                                .overlay(
                                    // inner shadow for depth
                                    Circle()
                                        .strokeBorder(Color.black.opacity(0.25), lineWidth: 1)
                                        .blur(radius: 2)
                                        .offset(y: 1)
                                        .mask(Circle())
                                )
                                .overlay(
                                    // moving highlight
                                    Circle()
                                        .trim(from: 0.0, to: 0.55)
                                        .stroke(Color.white.opacity(0.45), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                        .rotationEffect(.degrees(shieldPulse ? -18 : 12))
                                        .blur(radius: 2)
                                        .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: shieldPulse)
                                )
                                .frame(width: 50, height: 50)
                                .scaleEffect(shieldPulse ? 1.05 : 1.0)
                                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)

                            Image(systemName: "shield.checkered")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
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
    
    ///
    
    /// Initializes all animations when the view appears
    ///
    /// Starts three types of animations with staggered timing:
    /// 1. Text message cycling every 2 seconds
    /// 2. Dot loading animation with spring effects
    /// 3. Shield pulse animation for visual interest
    private func startAnimations() {
        // Cycle through status messages with smooth spring transitions
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3)) {
                currentIndex = (currentIndex + 1) % messages.count
            }
        }
        
        // Start dot animation with slight delay for smoothness
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dotAnimation = true
        }
        
        // Start shield pulse animation with additional delay
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
         
                // Progress fill with shimmer effect
                RoundedRectangle(cornerRadius: 50)
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
