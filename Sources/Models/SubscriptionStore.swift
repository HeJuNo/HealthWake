import Foundation

/// Ablage der Abonnements: eine JSON-Datei, bei jeder Aenderung ganz neu
/// geschrieben. Es sind wenige Eintraege, und eine Aenderung betrifft immer
/// den Anker -- also ohnehin die ganze Datei.
actor SubscriptionStore {
    private let fileURL: URL
    private var subscriptions: [Subscription] = []
    private var didLoad = false

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// Liest die Datei. Eine fehlende Datei ist kein Fehler, sondern der
    /// Anfangszustand.
    func load() async throws {
        didLoad = true
        guard let data = try? Data(contentsOf: fileURL) else {
            subscriptions = []
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        subscriptions = try decoder.decode([Subscription].self, from: data)
    }

    func all() async -> [Subscription] {
        await ensureLoaded()
        return subscriptions
    }

    func upsert(_ subscription: Subscription) async throws {
        await ensureLoaded()
        if let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) {
            subscriptions[index] = subscription
        } else {
            subscriptions.append(subscription)
        }
        try write()
    }

    func remove(id: UUID) async throws {
        await ensureLoaded()
        subscriptions.removeAll { $0.id == id }
        try write()
    }

    func subscription(forTypeIdentifier identifier: String) async -> Subscription? {
        await ensureLoaded()
        return subscriptions.first { $0.typeIdentifier == identifier }
    }

    private func ensureLoaded() async {
        guard !didLoad else { return }
        try? await load()
    }

    private func write() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(subscriptions)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: .atomic)
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: fileURL.path
        )
    }
}
