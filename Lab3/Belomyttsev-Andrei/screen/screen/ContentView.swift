import DeviceActivity
import FamilyControls
import SwiftUI

struct ContentView: View {
    @State private var viewModel = BatteryViewModel()
    @State private var picking: AppKind?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.access {
                case .checking:
                    ProgressView()
                case .granted:
                    settings
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
            .navigationTitle("Screen Battery")
        }
        .task { await viewModel.authorize() }
        .onChange(of: scenePhase) { old, new in
            if old == .background, new != .background { viewModel.reloadReport() }
        }
        .sheet(item: $picking) { kind in
            AppPicker(title: kind.title, selection: viewModel.config[keyPath: kind.selection]) {
                viewModel.config[keyPath: kind.selection] = $0
            }
        }
    }

    private var settings: some View {
        VStack(spacing: 0) {
            DeviceActivityReport(.battery, filter: viewModel.filter)
                .frame(height: 200)
            Form {
                ForEach(AppKind.allCases) { kind in
                    let selection = viewModel.config[keyPath: kind.selection]
                    Section(kind.title) {
                        Button {
                            picking = kind
                        } label: {
                            LabeledContent("Selected", value: "\(selection.applicationTokens.count) apps, \(selection.categoryTokens.count) categories")
                        }
                        LabeledContent("Coefficient") {
                            Stepper(viewModel.config[keyPath: kind.rate].formatted() + " %/min",
                                    value: $viewModel.config[dynamicMember: kind.rate], in: 0...5, step: 0.5)
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

private enum AppKind: CaseIterable, Identifiable {
    case good, bad

    var id: Self { self }
    var title: String { self == .good ? "Good apps" : "Bad apps" }
    var selection: WritableKeyPath<BatteryConfig, FamilyActivitySelection> { self == .good ? \.good : \.bad }
    var rate: WritableKeyPath<BatteryConfig, Double> { self == .good ? \.goodRate : \.badRate }
}

private struct AppPicker: View {
    let title: String
    @State var selection: FamilyActivitySelection
    let onDone: (FamilyActivitySelection) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            onDone(selection)
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
