import Foundation

/// Ablage der Abonnements: eine JSON-Datei, bei jeder Aenderung ganz neu
/// geschrieben. Es sind wenige Eintraege, und eine Aenderung betrifft immer
/// den Anker -- also ohnehin die ganze Datei.
actor SubscriptionStore {
    private let fileURL: URL
    private var subscriptions: [Subscription] = []
    private var didLoad = false
    /// Gesetzt, wenn eine unlesbare Datei beiseitegelegt wurde. Die App
    /// meldet das im Protokoll -- stillschweigend von vorn anzufangen waere
    /// der schlimmere Weg.
    private(set) var corruptFileURL: URL?

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// Liest die Datei. Eine fehlende Datei ist kein Fehler, sondern der
    /// Anfangszustand. Eine unlesbare Datei schon: sie wird beiseitegelegt,
    /// nicht ueberschrieben -- sonst waeren beim naechsten Speichern alle
    /// Abonnements, Filter und Anker weg.
    func load() async throws {
        didLoad = true
        guard let data = try? Data(contentsOf: fileURL) else {
            subscriptions = []
            return
        }
        let decoder = JSONCoding.exactDecoder()
        do {
            subscriptions = try decoder.decode([Subscription].self, from: data)
        } catch {
            subscriptions = []
            setAside(data)
            throw error
        }
    }

    private func setAside(_ data: Data) {
        let stamp = Int(Date().timeIntervalSince1970)
        let aside = fileURL.deletingLastPathComponent()
            .appendingPathComponent(fileURL.lastPathComponent + ".corrupt-\(stamp)")
        try? data.write(to: aside, options: .atomic)
        try? FileManager.default.removeItem(at: fileURL)
        corruptFileURL = aside
    }

    /// Schreibt die Einstellung eines Abonnements und laesst den Fortschritt
    /// in Ruhe. Noetig, weil die Oberflaeche eine Kopie vom Oeffnen des
    /// Bildschirms haelt: schriebe sie den ganzen Datensatz zurueck, fiele
    /// der Anker auf den damaligen Stand -- und HealthKit lieferte alles
    /// seitdem noch einmal.
    func updateConfiguration(_ subscription: Subscription) async throws {
        await ensureLoaded()
        guard let index = subscriptions.firstIndex(where: { $0.id == subscription.id }) else {
            try await upsert(subscription)
            return
        }
        var merged = subscription
        merged.anchorData = subscriptions[index].anchorData
        merged.lastSampleAt = subscriptions[index].lastSampleAt
        merged.lastTriggeredAt = subscriptions[index].lastTriggeredAt
        subscriptions[index] = merged
        try write()
    }

    /// Schreibt den Fortschritt und laesst die Einstellung in Ruhe -- die
    /// Gegenrichtung desselben Problems.
    func updateProgress(
        id: UUID,
        anchorData: Data?,
        lastSampleAt: Date?,
        lastTriggeredAt: Date?
    ) async throws {
        await ensureLoaded()
        guard let index = subscriptions.firstIndex(where: { $0.id == id }) else { return }
        subscriptions[index].anchorData = anchorData
        subscriptions[index].lastSampleAt = lastSampleAt
        subscriptions[index].lastTriggeredAt = lastTriggeredAt
        try write()
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
        let encoder = JSONCoding.exactEncoder()
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
