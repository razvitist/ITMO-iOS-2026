import SwiftUI

struct ContentView: View {
    @State private var number = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("\(number)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .contentTransition(.numericText(value: Double(number)))

                Button("Generate random number") {
                    withAnimation {
                        number = Int.random(in: 1...100)
                    }
                }
                .buttonStyle(.borderedProminent)

                NavigationLink("Open second screen") {
                    SecondView()
                }
                .buttonStyle(.bordered)
            }
            .navigationTitle("Main")
        }
    }
}

struct SecondView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .imageScale(.large)
                .font(.system(size: 48))
            Text("This is the second screen")
                .font(.title2)
        }
        .navigationTitle("Second")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
