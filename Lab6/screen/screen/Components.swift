import FamilyControls
import SwiftUI

struct ProtectedPage<Content: View>: View {
    let viewModel: BatteryViewModel
    @ViewBuilder let content: Content

    var body: some View {
        Group {
            if viewModel.isLocked {
                ContentUnavailableView {
                    Label("Locked", systemImage: "lock.fill")
                } description: {
                    Text("\(viewModel.config.protection.title) is required to see and change these settings.")
                } actions: {
                    Button("Unlock", action: viewModel.beginUnlock)
                        .buttonStyle(.borderedProminent)
                }
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
