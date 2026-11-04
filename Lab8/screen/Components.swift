import FamilyControls
import SwiftUI

struct ProtectedPage<Content: View>: View {
    let viewModel: BatteryViewModel
    @ViewBuilder let content: Content

    var body: some View {
        Group {
            if viewModel.isLocked {
                LockedView(config: viewModel.config, unlock: viewModel.beginUnlock)
            } else {
                content
            }
        }
        .toolbar {
            if viewModel.config.isProtected, !viewModel.isLocked {
                Button("Lock", systemImage: "lock", action: viewModel.lock)
            }
        }
    }
}

private struct LockedView: View {
    let config: BatteryConfig
    let unlock: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(.tint.opacity(0.1))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(.tint.opacity(0.18))
                    .frame(width: 100, height: 100)
                Image(systemName: "lock.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.tint)
                    .symbolEffect(.bounce, value: appeared)
            }
            VStack(spacing: 10) {
                Text("Locked")
                    .font(.largeTitle.bold())
                Text(config.protection.lockedMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Label(badge, systemImage: config.protection.symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.tint)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.tint.opacity(0.12), in: .capsule)
            Spacer()
            Button(action: unlock) {
                Label("Unlock", systemImage: "lock.open.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
        .onAppear { appeared.toggle() }
    }

    private var badge: String {
        switch config.protection {
        case .math, .morse: "\(config.protection.title) · \(config.difficulty.title)"
        default: config.protection.title
        }
    }
}

private extension Protection {
    var symbol: String {
        switch self {
        case .none: "lock.open"
        case .password: "key.fill"
        case .math: "function"
        case .morse: "waveform"
        }
    }

    var lockedMessage: String {
        switch self {
        case .none: "These settings are open."
        case .password: "Enter your password to see and change these settings."
        case .math: "Solve a math task to see and change these settings."
        case .morse: "Decode a Morse code word to see and change these settings."
        }
    }
}

struct ChallengeSheet: View {
    let challenge: Challenge
    let submit: (String) -> Bool
    @State private var answer = ""
    @State private var isWrong = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                if !challenge.prompt.isEmpty {
                    Section {
                        Text(challenge.prompt)
                            .font(.title2.monospaced())
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier("challengePrompt")
                    }
                }
                Section {
                    Group {
                        if challenge.kind == .password {
                            SecureField("Password", text: $answer)
                        } else {
                            TextField("Answer", text: $answer)
                                .keyboardType(challenge.kind == .math ? .numberPad : .asciiCapable)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit(check)
                    .accessibilityIdentifier("challengeAnswer")
                } footer: {
                    if isWrong {
                        Text("Wrong answer, try again.")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(challenge.kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Unlock", action: check)
                        .disabled(answer.isEmpty)
                }
            }
        }
    }

    private func check() {
        guard !submit(answer) else { return }
        isWrong = true
        answer = ""
    }
}

struct URLField: View {
    @Binding var url: String
    @State private var text: String
    @FocusState private var isFocused: Bool

    init(url: Binding<String>) {
        _url = url
        _text = State(initialValue: url.wrappedValue)
    }

    var body: some View {
        TextField("Server link", text: $text, prompt: Text("https://example.com/usage"))
            .keyboardType(.URL)
            .textContentType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .focused($isFocused)
            .onSubmit { url = text }
            .onChange(of: isFocused) { _, focused in
                if !focused { url = text }
            }
    }
}

struct AppPicker: View {
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

struct AccountField: View {
    let prompt: String
    let numeric: Bool
    @Binding var value: String
    @State private var text: String
    @FocusState private var isFocused: Bool

    init(_ prompt: String, numeric: Bool = false, value: Binding<String>) {
        self.prompt = prompt
        self.numeric = numeric
        _value = value
        _text = State(initialValue: value.wrappedValue)
    }

    var body: some View {
        TextField(prompt, text: $text)
            .keyboardType(numeric ? .numberPad : .asciiCapable)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .focused($isFocused)
            .onSubmit { value = text }
            .onChange(of: isFocused) { _, focused in
                if !focused { value = text }
            }
    }
}

struct PercentStepper: View {
    let title: String
    @Binding var value: Double
    var range = CodingConfig.rateRange
    var step = 1.0

    var body: some View {
        Stepper(value: $value, in: range, step: step) {
            LabeledContent(title, value: value.formatted() + "%")
        }
        .sensoryFeedback(.selection, trigger: value)
    }
}
