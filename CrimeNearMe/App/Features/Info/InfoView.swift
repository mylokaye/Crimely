import SwiftUI

struct InfoView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Info")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            Spacer()
        }
        .navigationTitle("Info")
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView()
    }
}
