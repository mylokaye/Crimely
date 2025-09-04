import SwiftUI

// Row used in the bottom card
struct CrimeRowView: View {
    let iconName: String
    let title: String
    let count: Int
    let subtitle: String
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: iconName)
                .font(.title3)
                .frame(width: 28, height: 28)
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .padding(6)
                .background(Circle().fill(Color(.systemBackground).opacity(0.6)))
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.custom("Merriweather-var", size: 20).weight(.semibold))
                    Text("(\(count))")
                        .font(.custom("Merriweather-var", size: 20).weight(.regular))
                        .foregroundStyle(.secondary)
                }
                Text(subtitle)
                    .font(.custom("Merriweather-var", size: 17))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

struct CrimeDataCard: View {
    let place: String
    let totals: Totals
    let monthISO: String
    let byCategory: [CategoryCount]
    let onProfile: () -> Void
    @Binding var isExpanded: Bool
    let onHeightChange: (CGFloat) -> Void

    private func subtitle(for category: String) -> String {
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
        switch category.lowercased() {
        case "violence", "violent-crime": return "bolt.heart"
        case "robbery", "theft-from-the-person", "burglary": return "lock"
        case "shoplifting": return "bag"
        case "vehicle crime", "vehicle-crime": return "car"
        default: return "shield.lefthalf.filled"
        }
    }

    private let collapsedHeight: CGFloat = 49 // Tab bar height

    var body: some View {
        VStack(spacing: 16) {
            if isExpanded {
                Capsule()
                    .frame(width: 44, height: 5)
                    .opacity(0.18)
                    .padding(.top, 12)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            isExpanded.toggle()
                        }
                    }
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(byCategory, id: \ .category) { item in
                            CrimeRowView(
                                iconName: icon(for: item.category),
                                title: item.category.capitalized,
                                count: item.count,
                                subtitle: subtitle(for: item.category)
                            )
                        }
                        Color.clear.frame(height: 12)
                    }
                    .padding(.vertical, 8)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear { onHeightChange(max(collapsedHeight + 80, proxy.size.height + 160)) }
                                .onChange(of: proxy.size.height) { h in onHeightChange(max(collapsedHeight + 80, h + 160)) }
                        }
                    )
                }
                .scrollIndicators(.never)
            } else {
                Capsule()
                    .frame(width: 44, height: 5)
                    .opacity(0.18)
                    .padding(.top, 8)
                    .contentShape(Rectangle())
                Text(place)
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(place.count > 10 ? 0.7 : 1.0)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 8)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThickMaterial)
                .shadow(color: Color.black.opacity(0.18), radius: 24, y: 8)
        )
        .padding(.horizontal, 0)
        .gesture(
            DragGesture(minimumDistance: 8)
                .onEnded { value in
                    let threshold: CGFloat = 60
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
