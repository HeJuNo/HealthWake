import SwiftUI

extension HTTPPostAction {
    @MainActor
    static func makeConfigView(config: Config, onChange: @escaping (Config) -> Void) -> AnyView {
        AnyView(HTTPConfigView(config: config, onChange: onChange))
    }
}

struct HTTPConfigView: View {
    @State private var config: HTTPPostAction.Config
    @State private var secret: String = ""
    @State private var headerName: String = ""
    @State private var headerValue: String = ""
    @State private var testResult: String?
    @State private var isSending = false
    private let onChange: (HTTPPostAction.Config) -> Void

    init(config: HTTPPostAction.Config, onChange: @escaping (HTTPPostAction.Config) -> Void) {
        _config = State(initialValue: config)
        self.onChange = onChange
    }

    private var model: HTTPConfigModel { HTTPConfigModel(config: config) }

    var body: some View {
        Form {
            addressSection
            headersSection
            secretSection
            bodySection
            testSection
            PlaceholderHelp()
        }
        .navigationTitle("HTTP Request")
        .onChange(of: config) { _, newValue in onChange(newValue) }
        .task {
            if let account = HTTPPostAction.keychainAccount(for: config) {
                secret = KeychainStore.get(account: account) ?? ""
            }
        }
    }

    private var addressSection: some View {
        Section {
            TextField("https://example.com/hook", text: $config.urlTemplate, axis: .vertical)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .accessibilityLabel("Request address")
            Picker("Method", selection: $config.method) {
                ForEach(["POST", "PUT", "PATCH", "GET"], id: \.self) { method in
                    Text(method).tag(method)
                }
            }
        } header: {
            Text("Address")
        } footer: {
            if let message = model.validationMessage() {
                Text(message).foregroundStyle(.orange)
            } else {
                Text(model.urlPreview())
            }
        }
    }

    private var headersSection: some View {
        Section("Headers") {
            ForEach(config.headers.keys.sorted(), id: \.self) { name in
                HStack {
                    Text(name)
                    Spacer()
                    Text(config.headers[name] ?? "")
                        .foregroundStyle(.secondary)
                }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        config.headers.removeValue(forKey: name)
                    }
                }
            }
            HStack {
                TextField("Name", text: $headerName)
                    .textInputAutocapitalization(.never)
                TextField("Value", text: $headerValue)
                    .textInputAutocapitalization(.never)
                Button("Add") {
                    let name = headerName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    config.headers[name] = headerValue
                    headerName = ""
                    headerValue = ""
                }
                .disabled(headerName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var secretSection: some View {
        Section {
            TextField("Header name, e.g. Authorization", text: Binding(
                get: { config.keychainHeaderName ?? "" },
                set: { config.keychainHeaderName = $0.isEmpty ? nil : $0 }
            ))
            .textInputAutocapitalization(.never)
            SecureField("Secret value", text: $secret)
                .onChange(of: secret) { _, newValue in saveSecret(newValue) }
        } header: {
            Text("Secret header")
        } footer: {
            Text("The value is kept in the keychain, never in the configuration file or in a backup of it.")
        }
    }

    private var bodySection: some View {
        Section {
            TextEditor(text: $config.bodyTemplate)
                .font(.system(.footnote, design: .monospaced))
                .frame(minHeight: 120)
                .accessibilityLabel("Request body template")
        } header: {
            Text("Body")
        } footer: {
            Text(model.bodyPreview())
                .font(.system(.caption2, design: .monospaced))
        }
    }

    private var testSection: some View {
        Section {
            Button {
                Task { await runTest() }
            } label: {
                if isSending {
                    ProgressView()
                } else {
                    Text("Test now")
                }
            }
            .disabled(isSending || model.validationMessage() != nil)
            if let testResult {
                Text(testResult)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
            }
        } footer: {
            Text("Sends one request with the example values above, right now.")
        }
    }

    private func saveSecret(_ value: String) {
        guard let account = HTTPPostAction.keychainAccount(for: config) else { return }
        if value.isEmpty {
            KeychainStore.remove(account: account)
        } else {
            try? KeychainStore.set(value, account: account)
        }
    }

    private func runTest() async {
        isSending = true
        testResult = await model.sendTest(secret: secret.isEmpty ? nil : secret)
        isSending = false
    }
}
