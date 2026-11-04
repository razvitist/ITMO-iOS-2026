import SwiftUI

struct CodingPage: View {
    @Bindable var viewModel: BatteryViewModel

    var body: some View {
        NavigationStack {
            ProtectedPage(viewModel: viewModel) {
                List {
                    Section {
                        LabeledContent("Charged today", value: Self.percent(viewModel.codingBonus.total))
                        if let updatedAt = viewModel.coding.updatedAt {
                            LabeledContent("Last check", value: updatedAt.formatted(date: .omitted, time: .shortened))
                        }
                        CheckButton(viewModel: viewModel)
                    } footer: {
                        Text("Every problem solved today charges the battery. Progress is checked when the app opens.")
                    }
                    Section("Websites") {
                        ForEach(CodingPlatform.allCases) { platform in
                            NavigationLink(value: platform) {
                                PlatformRow(viewModel: viewModel, platform: platform)
                            }
                        }
                    }
                }
                .refreshable { await viewModel.refreshCoding() }
            }
            .navigationTitle("Integrations")
            .navigationDestination(for: CodingPlatform.self) { platform in
                CodingPlatformPage(viewModel: viewModel, platform: platform)
            }
        }
    }

    static func percent(_ value: Double) -> String {
        "+" + value.formatted(.number.precision(.fractionLength(0...1))) + "%"
    }
}

private struct PlatformRow: View {
    let viewModel: BatteryViewModel
    let platform: CodingPlatform

    var body: some View {
        let account = viewModel.config.coding.account(platform)
        HStack(spacing: 12) {
            PlatformLogo(platform: platform, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(platform.title)
                    .font(.headline)
                Text(account.isEmpty ? "Not connected" : account)
                    .font(.subheadline)
                    .foregroundStyle(viewModel.codingErrors[platform] == nil ? .secondary : Color.red)
                    .lineLimit(1)
            }
            Spacer()
            if !account.isEmpty {
                Text(CodingPage.percent(viewModel.codingBonus.value(for: platform)))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CodingPlatformPage: View {
    @Bindable var viewModel: BatteryViewModel
    let platform: CodingPlatform

    var body: some View {
        let progress = viewModel.coding
        Form {
            Section {
                VStack(spacing: 12) {
                    PlatformLogo(platform: platform, size: 88)
                    Text(CodingPage.percent(viewModel.codingBonus.value(for: platform)) + " today")
                        .font(.title2.bold())
                        .monospacedDigit()
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section {
                switch platform {
                case .leetcode:
                    AccountField("Username", value: $viewModel.config.coding.leetcodeName)
                case .codewars:
                    AccountField("Username", value: $viewModel.config.coding.codewarsName)
                case .stepik:
                    AccountField("Profile ID", numeric: true, value: $viewModel.config.coding.stepikID)
                }
            } header: {
                Text("Account")
            } footer: {
                if let error = viewModel.codingErrors[platform] {
                    Text(error).foregroundStyle(.red)
                } else {
                    Text(platform.hint)
                }
            }

            Section("Charge") {
                switch platform {
                case .leetcode:
                    PercentStepper(title: "Easy problem", value: $viewModel.config.coding.leetcodeEasy)
                    PercentStepper(title: "Medium problem", value: $viewModel.config.coding.leetcodeMedium)
                    PercentStepper(title: "Hard problem", value: $viewModel.config.coding.leetcodeHard)
                case .codewars:
                    PercentStepper(title: "Per honor point", value: $viewModel.config.coding.codewarsHonor, step: 0.5)
                case .stepik:
                    PercentStepper(title: "Per solved step", value: $viewModel.config.coding.stepikStep, step: 0.5)
                }
            }

            Section("Solved today") {
                switch platform {
                case .leetcode:
                    LabeledContent("Easy", value: "\(progress.easy.today)")
                    LabeledContent("Medium", value: "\(progress.medium.today)")
                    LabeledContent("Hard", value: "\(progress.hard.today)")
                case .codewars:
                    LabeledContent("Honor earned", value: "\(progress.honor.today)")
                case .stepik:
                    LabeledContent("Steps solved", value: "\(progress.stepikToday)")
                }
                CheckButton(viewModel: viewModel)
            }
        }
        .navigationTitle(platform.title)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.refreshCoding() }
    }
}

private struct CheckButton: View {
    let viewModel: BatteryViewModel

    var body: some View {
        Button {
            Task { await viewModel.refreshCoding() }
        } label: {
            HStack {
                Text("Check now")
                Spacer()
                if viewModel.isRefreshingCoding { ProgressView() }
            }
        }
        .disabled(viewModel.isRefreshingCoding)
    }
}
