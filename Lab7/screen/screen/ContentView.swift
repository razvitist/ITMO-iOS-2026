import SwiftUI

struct ContentView: View {
    @State private var viewModel = BatteryViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch viewModel.access {
            case .checking:
                ProgressView()
            case .granted:
                TabView {
                    Tab("Battery", systemImage: "battery.75percent") {
                        BatteryPage(viewModel: viewModel)
                    }
                    Tab("Apps", systemImage: "square.grid.2x2") {
                        AppsPage(viewModel: viewModel)
                    }
                    Tab("Server", systemImage: "network") {
                        ServerPage(viewModel: viewModel)
                    }
                    Tab("Security", systemImage: "lock.shield") {
                        SecurityPage(viewModel: viewModel)
                    }
                }
            case .denied:
                ContentUnavailableView {
                    Label("Screen Time access", systemImage: "hourglass")
                } description: {
                    Text(viewModel.errorMessage ?? "Allow access to track good and bad apps.")
                } actions: {
                    Button("Allow") { Task { await viewModel.authorize() } }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .task { await viewModel.authorize() }
        .onChange(of: scenePhase) { old, new in
            if new == .background { viewModel.lock() }
            if old == .background, new != .background { viewModel.becameActive() }
        }
        .sheet(item: $viewModel.challenge) { challenge in
            ChallengeSheet(challenge: challenge, submit: viewModel.submit)
        }
    }
}

#Preview {
    ContentView()
}
