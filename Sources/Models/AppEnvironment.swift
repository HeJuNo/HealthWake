import Foundation
import SwiftUI

/// Der Objektgraph der App an einer Stelle. Haelt die Ablagen, die
/// Verarbeitungskette und den Observer, und besitzt den globalen Schalter.
@MainActor
final class AppEnvironment: ObservableObject {
    let subscriptions: SubscriptionStore
    let samples: SampleStore
    let queue: ActionQueue
    let log: EventLog
    let pipeline: TriggerPipeline
    let observer: HealthObserver

    /// Der globale Schalter aus den Einstellungen. Aus heisst: keine
    /// Hintergrundzustellung, keine Aktion, kein Hintergrundbetrieb.
    @Published var isGloballyEnabled: Bool {
        didSet { defaults.set(isGloballyEnabled, forKey: Self.enabledKey) }
    }

    private static let enabledKey = "healthwake.deliveryEnabled"

    private let store: any HealthStoring
    private let defaults: UserDefaults

    init(
        store: any HealthStoring,
        directory: URL,
        registry: [AnyHealthAction] = ActionRegistry.all,
        defaults: UserDefaults = .standard
    ) {
        self.store = store
        self.defaults = defaults
        subscriptions = SubscriptionStore(fileURL: directory.appendingPathComponent("subscriptions.json"))
        samples = SampleStore(directory: directory.appendingPathComponent("samples", isDirectory: true))
        queue = ActionQueue(fileURL: directory.appendingPathComponent("queue.jsonl"))
        log = EventLog(fileURL: directory.appendingPathComponent("log.json"))
        pipeline = TriggerPipeline(
            store: store,
            subscriptions: subscriptions,
            samples: samples,
            queue: queue,
            log: log,
            registry: registry
        )
        observer = HealthObserver(store: store, pipeline: pipeline, log: log)
        // Standard ist eingeschaltet: wer einen Typ auswaehlt, will Werte sehen.
        isGloballyEnabled = (defaults.object(forKey: Self.enabledKey) as? Bool) ?? true
    }

    static func live() -> AppEnvironment {
        AppEnvironment(store: LiveHealthStore(), directory: Self.supportDirectory())
    }

    /// Daten liegen in Application Support und werden nicht in iCloud
    /// gesichert -- es sind Kopien von Health-Werten, kein Original.
    static func supportDirectory() -> URL {
        let base = (try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? FileManager.default.temporaryDirectory
        let directory = base.appendingPathComponent("HealthWake", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutable = directory
        try? mutable.setResourceValues(resourceValues)
        return directory
    }

    func setGloballyEnabled(_ enabled: Bool) async {
        isGloballyEnabled = enabled
        if enabled {
            // Wieder einschalten heisst "ab jetzt", nicht "alles nachholen":
            // jeder Anker wird auf den aktuellen Stand gesetzt. Ein leerer
            // Anker wuerde die gesamte Historie durch jede Aktion jagen.
            for subscription in await subscriptions.all() {
                guard let anchor = try? await store.currentAnchor(for: subscription.typeIdentifier) else { continue }
                var updated = subscription
                updated.anchorData = anchor
                try? await subscriptions.upsert(updated)
            }
            await append(.deliveryEnabled, "Delivery switched on, watching from now")
            await observer.registerAll(identifiers: await enabledIdentifiers())
        } else {
            await observer.unregisterAll()
            await append(.deliveryDisabled, "Delivery switched off, no actions will run")
        }
    }

    /// Holt nach, was waehrend einer Pause angefallen ist -- beim Start, beim
    /// Wechsel in den Vordergrund und sobald die Daten nach dem Entsperren
    /// wieder lesbar sind.
    func refreshAllNow() async {
        guard isGloballyEnabled else { return }
        for identifier in await enabledIdentifiers() {
            _ = await pipeline.handleUpdate(for: identifier)
        }
        await pipeline.drainQueue(deadline: Date().addingTimeInterval(HealthObserver.wakeWindow))
    }

    func enabledIdentifiers() async -> [String] {
        await subscriptions.all().filter(\.isEnabled).map(\.typeIdentifier)
    }

    private func append(_ kind: LogEntry.Kind, _ message: String) async {
        try? await log.append(LogEntry(
            id: UUID(),
            date: Date(),
            kind: kind,
            message: message,
            typeIdentifier: nil,
            actionTypeID: nil
        ))
    }
}
