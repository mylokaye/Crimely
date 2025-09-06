import SwiftUI
import UIKit

extension CrimeDataCardStyle {
    // Layout metrics centralised for CrimeDataCard
    static let collapsedHeight: CGFloat = 9
    static let horizontalPadding: CGFloat = 20
    static let topPadding: CGFloat = 8
    static let bottomPadding: CGFloat = 20

    static let containerSpacing: CGFloat = 16
    static let listSectionSpacing: CGFloat = 18
    static let rowVerticalPadding: CGFloat = 2

    static let grabberSize = CGSize(width: 44, height: 5)
    static let grabberOpacityExpanded: Double = 0.18
    static let grabberOpacityCollapsed: Double = 0.08
    static let grabberTopPaddingExpanded: CGFloat = 12
    static let grabberTopPaddingCollapsed: CGFloat = 4

    static let expandedCornerRadius: CGFloat = 60
    static let collapsedCornerRadius: CGFloat = 30
    static let useCapsuleBackground: Bool = false
}

// A UIViewRepresentable to wrap UIVisualEffectView for use in SwiftUI
struct VisualEffectView: UIViewRepresentable {
    let effect: UIVisualEffect? // The visual effect to apply (e.g., blur, vibrancy)

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: effect)
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect // Update the effect if it changes
    }
}

extension View {
    /// Applies a blur (glass) background and clips with the provided corner radius.
    func glassEffectRounded(_ style: UIBlurEffect.Style, cornerRadius: CGFloat) -> some View {
        self
            .background(VisualEffectView(effect: UIBlurEffect(style: style)))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// Row used in the bottom card
struct CrimeRowView: View {
    let iconName: String // The name of the SF Symbol icon to display
    let title: String // The title of the crime category
    let count: Int // The number of crimes in this category
    let subtitle: String // A brief description of the crime category

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: iconName) // Display the icon for the crime category
                .font(.title3)
                .frame(width: 28, height: 28)
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .padding(6)
                .background(Circle().fill(Color(.systemBackground).opacity(0.6)))
            
            
            
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(title) // Display the title of the crime category
                        .font(.custom("Merriweather-var", size: 20).weight(.semibold))
                    Text("(\(count))") // Display the count of crimes in parentheses
                        .font(.custom("Merriweather-var", size: 20).weight(.regular))
                        .foregroundStyle(.secondary)
                }
                Text(subtitle) // Display the subtitle/description of the crime category
                    .font(.custom("Merriweather-var", size: 17))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, CrimeDataCardStyle.rowVerticalPadding)
    }
}

struct CrimeDataCard: View {
    let place: String // The name of the place (e.g., "Manchester")
    let totals: Totals // The total number of crimes and serious crimes
    let monthISO: String // The month in ISO format (e.g., "2025-06")
    let byCategory: [CategoryCount] // An array of crime data grouped by category
    let onProfile: () -> Void // A callback function triggered when the profile is tapped
    @Binding var isExpanded: Bool // A binding to track whether the card is expanded or collapsed
    let onHeightChange: (CGFloat) -> Void // A callback function to handle height changes

    private func subtitle(for category: String) -> String {
        // Returns a description for the given crime category
        switch category.lowercased() {
        case "violence", "violent-crime":
            return "Murder, Harassment, Common Assault, ABH & GBH."
        case "robbery", "theft-from-the-person", "burglary":
            return "Theft with force or threat; entering to commit a crime."
        case "shoplifting":
            return "Theft from a shop."
        case "vehicle crime", "vehicle-crime":
            return "Theft of/from a vehicle and damage."
        default:
            return "Reported incidents in this category."
        }
    }

    private func icon(for category: String) -> String {
        // Returns the SF Symbol icon name for the given crime category
        switch category.lowercased() {
        case "violence", "violent-crime": return "bolt.heart"
        case "robbery", "theft-from-the-person", "burglary": return "lock"
        case "shoplifting": return "bag"
        case "vehicle crime", "vehicle-crime": return "car"
        default: return "shield.lefthalf.filled"
        }
    }

    var body: some View {
        VStack(spacing: CrimeDataCardStyle.containerSpacing) {
            if isExpanded {
                Capsule()
                
                
                
                    .frame(width: CrimeDataCardStyle.grabberSize.width, height: CrimeDataCardStyle.grabberSize.height) // The grabber bar at the top of the card
                    .opacity(CrimeDataCardStyle.grabberOpacityExpanded) // The transparency of the grabber bar
                    .padding(.top, CrimeDataCardStyle.grabberTopPaddingExpanded)
                
                 
                
                    .contentShape(Rectangle())
                
                
                
                
                    .onTapGesture {
                        // Toggle the expanded state when the grabber is tapped
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            isExpanded.toggle()
                            print("isExpanded: \(isExpanded)") // Debug print
                        }
                    }
                
                
                ScrollView {
                    VStack(alignment: .leading, spacing: CrimeDataCardStyle.listSectionSpacing) {
                        ForEach(byCategory, id: \ .category) { item in
                            CrimeRowView(
                                iconName: icon(for: item.category), // Icon for the crime category
                                title: item.category.capitalized, // Capitalized category name
                                count: item.count, // Number of crimes in this category
                                subtitle: subtitle(for: item.category) // Description of the category
                            )
                        }
                        Color.clear.frame(height: 12) // Spacer at the bottom of the scroll view
                    }
                    .padding(.vertical, 8)
                    
                    
                    
                    .background(
                        
                        
                    
                        
                        GeometryReader { proxy in
                            Color.clear
                            
                            
                                .onAppear { onHeightChange(max(CrimeDataCardStyle.collapsedHeight + 80, proxy.size.height + 160)) }
                                .onChange(of: proxy.size.height) { _, newHeight in
                                    onHeightChange(max(CrimeDataCardStyle.collapsedHeight + 80, newHeight + 160))
                                }
                        }
                    )
                }
                .scrollIndicators(.never) // Disable scroll indicators
            } else {
                Capsule()
                
             
                
                
                    .frame(width: CrimeDataCardStyle.grabberSize.width, height: CrimeDataCardStyle.grabberSize.height) // The grabber bar at the top of the card
                    .opacity(CrimeDataCardStyle.grabberOpacityCollapsed) // The transparency of the grabber bar
                    .padding(.top, CrimeDataCardStyle.grabberTopPaddingCollapsed) // Adjusts the top spacing for the collapsed state
                    .contentShape(Rectangle())
                Text(place) // Display the name of the place
                
                
                
                    .font(.system(size: 18))
                         .fontWeight(.regular)
                         .foregroundStyle(.primary)
                         .lineLimit(1)
                         .minimumScaleFactor(place.count > 10 ? 0.7 : 1.0)
                         .frame(maxWidth: .infinity, alignment: .center) // or .center if you prefer
                         .padding(.vertical, CrimeDataCardStyle.rowVerticalPadding) // match your rows
                 
                
                
            }
        }
        .padding(.horizontal, CrimeDataCardStyle.horizontalPadding) // Horizontal padding for the card content
        .padding(.top, CrimeDataCardStyle.topPadding) // Top padding for the card content
        .padding(.bottom, CrimeDataCardStyle.bottomPadding) // Bottom padding for the card content
        .frame(maxWidth: .infinity) // Make the card span the full width
        .background(
            ZStack {
                if CrimeDataCardStyle.useCapsuleBackground {
                    if #available(iOS 26.0, *) {
                        Capsule()
                            .fill(isExpanded ? CrimeDataCardStyle.expandedBackgroundColor : CrimeDataCardStyle.collapsedBackgroundColor)
                            .glassEffect(.regular.interactive())
                    } else {
                        // Fallback on earlier versions
                    }
                } else {
                    RoundedRectangle(
                        cornerRadius: isExpanded ? CrimeDataCardStyle.expandedCornerRadius : CrimeDataCardStyle.collapsedCornerRadius,
                        style: .continuous
                    )
                    .fill(isExpanded ? CrimeDataCardStyle.expandedBackgroundColor : CrimeDataCardStyle.collapsedBackgroundColor)
                    .glassEffectRounded(.regular, cornerRadius: isExpanded ? CrimeDataCardStyle.expandedCornerRadius : CrimeDataCardStyle.collapsedCornerRadius)
                }
            }
        )
        .background(
            Color.white.opacity(0.1) // Add a simple black background with 50% transparency
        )
        .onChange(of: isExpanded) { _, newValue in
            print("isExpanded changed to: \(newValue)") // Debug print to observe state changes
        }
        .padding(.horizontal, 0) // Remove additional horizontal padding
        .gesture(
            DragGesture(minimumDistance: 8) // Enable drag gestures for the card
                .onEnded { value in
                    let threshold: CGFloat = 60 // The drag threshold to toggle expansion
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        if value.translation.height < -threshold { isExpanded = true }
                        if value.translation.height > threshold { isExpanded = false }
                    }
                }
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Crime data summary for \(place). Total \(totals.total) in \(PoliceAPI.humanMonth(monthISO)).")
    }
}

struct CrimeDataCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CrimeDataCard(
                place: "Manchester", // Sample place name
                totals: Totals(total: 16, serious: 3), // Sample totals
                monthISO: "2025-06", // Sample month
                byCategory: [
                    CategoryCount(category: "Violence", count: 5), // Sample category
                    CategoryCount(category: "Robbery", count: 2),
                    CategoryCount(category: "Shoplifting", count: 4),
                    CategoryCount(category: "Vehicle crime", count: 3)
                ],
                onProfile: {}, // Empty callback for profile action
                isExpanded: .constant(false), // Collapsed state
                onHeightChange: { _ in } // Empty callback for height changes
            )
            .previewDisplayName("Collapsed State")

            CrimeDataCard(
                place: "Manchester", // Sample place name
                totals: Totals(total: 16, serious: 3), // Sample totals
                monthISO: "2025-06", // Sample month
                byCategory: [
                    CategoryCount(category: "Violence", count: 5), // Sample category
                    CategoryCount(category: "Robbery", count: 2),
                    CategoryCount(category: "Shoplifting", count: 4),
                    CategoryCount(category: "Vehicle crime", count: 3)
                ],
                onProfile: {}, // Empty callback for profile action
                isExpanded: .constant(true), // Expanded state
                onHeightChange: { _ in } // Empty callback for height changes
            )
            .previewDisplayName("Expanded State")
        }
    }
}
