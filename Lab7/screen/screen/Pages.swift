import DeviceActivity
import FamilyControls
import SwiftUI

struct BatteryPage: View {
    let viewModel: BatteryViewModel

    var body: some View {
        DeviceActivityReport(.battery, filter: viewModel.filter)
            .onAppear(perform: viewModel.reloadReport)
    }
}

struct AppsPage: View {
    @Bindable var viewModel: BatteryViewModel
    @State private var picking: AppKind?

    var body: some View {
        NavigationStack {
            ProtectedPage(viewModel: viewModel) {
                Form {
                    ForEach(AppKind.allCases) { kind in
                        let selection = viewModel.config[keyPath: kind.selection]
                        let rate = $viewModel.config[dynamicMember: kind.rate]
                        Section(kind.title) {
                            Button {
                                picking = kind
                            } label: {
                                LabeledContent("Selected", value: "\(selection.applicationTokens.count) apps, \(selection.categoryTokens.count) categories")
                            }
                            LabeledContent("Coefficient", value: rate.wrappedValue.formatted() + " %/min")
                                .accessibilityIdentifier("\(kind.rawValue)Coefficient")
                            Slider(value: rate, in: BatteryConfig.rateRange, step: 0.5)
                                .sensoryFeedback(.selection, trigger: rate.wrappedValue)
                                .accessibilityIdentifier("\(kind.rawValue)Rate")
                        }
                    }
                    Section {
                        Toggle("Block bad apps at 0%", isOn: $viewModel.config.blockEnabled)
                    } header: {
                        Text("Blocking")
                    } footer: {
                        Text("When the battery reaches 0%, Screen Time shields bad apps until good apps charge it above 0% or the day ends.")
                    }
                }
            }
            .navigationTitle("Apps")
        }
        .sheet(item: $picking) { kind in
            AppPicker(title: kind.title, selection: viewModel.config[keyPath: kind.selection]) {
                viewModel.config[keyPath: kind.selection] = $0
            }
        }
    }
}

struct ServerPage: View {
    @Bindable var viewModel: BatteryViewModel

    var body: some View {
        NavigationStack {
            ProtectedPage(viewModel: viewModel) {
                Form {
                    ForEach(AppKind.allCases) { kind in
                        let link = viewModel.config[keyPath: kind.url]
                        Section {
                            URLField(url: $viewModel.config[dynamicMember: kind.url])
                                .accessibilityIdentifier("\(kind.rawValue)Link")
                        } header: {
                            Text(kind.title)
                        } footer: {
                            if !link.isEmpty, BatteryConfig.endpoint(from: link) == nil {
                                Text("Enter a valid https:// link.")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    if let error = viewModel.monitorError {
                        Section {
                            Text(error)
                                .foregroundStyle(.red)
                        }
                    }
                    Section("Stored requests") {
                        Picker("Keep last", selection: $viewModel.config.logLimit) {
                            ForEach(BatteryConfig.logLimits, id: \.self) { Text("\($0)").tag($0) }
                        }
                        Button("Clear log", role: .destructive, action: viewModel.clearLog)
                            .disabled(viewModel.requestLog.isEmpty)
                    }
                    Section {
                        ForEach(viewModel.requestLog, id: \.self) { line in
                            Text(line)
                                .font(.caption.monospaced())
                        }
                    } header: {
                        HStack {
                            Text("Requests (\(viewModel.requestLog.count)/\(viewModel.config.logLimit))")
                            Spacer()
                            Button("Refresh", action: viewModel.reloadLog)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Server")
        }
    }
}

struct SecurityPage: View {
    @Bindable var viewModel: BatteryViewModel
    @State private var password = ""

    var body: some View {
        NavigationStack {
            ProtectedPage(viewModel: viewModel) {
                Form {
                    Section {
                        Picker("Protection", selection: $viewModel.config.protection) {
                            ForEach(Protection.allCases) { Text($0.title).tag($0) }
                        }
                    } footer: {
                        Text("Protects app selection, coefficients, blocking, links and these settings.")
                    }
                    if let example = Challenge.example(viewModel.config.protection, viewModel.config.difficulty) {
                        Section("Difficulty") {
                            Picker("Difficulty", selection: $viewModel.config.difficulty) {
                                ForEach(Difficulty.allCases) { Text($0.title).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            LabeledContent("Example") {
                                Text(example)
                                    .font(.body.monospaced())
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                    if viewModel.config.protection == .password {
                        Section {
                            SecureField("New password", text: $password)
                            Button("Save password") {
                                viewModel.setPassword(password)
                                password = ""
                            }
                            .disabled(password.count < 4)
                        } footer: {
                            Text(viewModel.config.passwordHash.isEmpty
                                 ? "Set a password of at least 4 characters to turn protection on."
                                 : "Password is set.")
                        }
                    }
                }
            }
            .navigationTitle("Security")
        }
    }
}
