import SwiftUI

struct Welcome1: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pink
                    .ignoresSafeArea()
                VStack {
                    Spacer()
                    Text("Welcome 1")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 32)

                    NavigationLink(destination: Welcome2()) {
                        HStack {
                            Text("Next")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                        }
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct Welcome1_Previews: PreviewProvider {
    static var previews: some View {
        Welcome1()
    }
}
