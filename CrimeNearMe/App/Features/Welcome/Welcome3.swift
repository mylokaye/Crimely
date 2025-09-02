import SwiftUI

struct Welcome3: View {
    var body: some View {
        ZStack {
            Color.pink
                .ignoresSafeArea()
            VStack {
                Spacer()
                Text("Welcome 3")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 32)

                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)

                Spacer()
            }
            .padding()
        }
    }
}

struct Welcome3_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack { Welcome3() }
    }
}
