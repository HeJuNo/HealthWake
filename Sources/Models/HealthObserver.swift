import Foundation
import HealthKit

/// Meldet die beobachteten Typen bei HealthKit an und beantwortet jeden
/// Weckruf.
///
/// Der Completion-Handler von HealthKit ist die wichtigste Zeile der ganzen
/// App: wird er nicht gerufen, stellt iOS die Hintergrundzustellung fuer
/// diesen Typ ein -- stillschweigend und dauerhaft (Spec 5.2). Deshalb wird
/// er auf jedem Weg genau einmal gerufen, auch wenn alles andere schiefgeht.
@MainActor
final class HealthObserver {
    /// So lange nach einem Weckruf wird die Warteschlange abgearbeitet. iOS
    /// gibt keine Zusage, aber unter 30 Sekunden ist man auf der sicheren Seite.
    static let wakeWindow: TimeInterval = 25

    private let store: any HealthStoring
    private let pipeline: TriggerPipeline
    private let log: EventLog
    private let healthStore = HKHealthStore()
    private var queries: [HKObserverQuery] = []

    init(store: any HealthStoring, pipeline: TriggerPipeline, log: EventLog) {
        self.store = store
        self.pipeline = pipeline
        self.log = log
    }

    /// Meldet alle uebergebenen Typen an und schaltet fuer sie die
    /// Hintergrundzustellung ein. Muss nach jedem Start wieder laufen:
    /// Observer-Abfragen leben nur, solange der Prozess lebt.
    func registerAll(identifiers: [String]) async {
        await unregisterAll()
        for identifier in identifiers {
            guard let type = try? LiveHealthStore.sampleType(for: identifier) else { continue }
            let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completionHandler, error in
                guard let self else {
                    // Ohne Beobachter gibt es nichts zu tun -- aber der
                    // Handler muss trotzdem bestaetigt werden.
                    completionHandler()
                    return
                }
                if let error {
                    Task { @MainActor in
                        self.handleObserverFailure(
                            error,
                            typeIdentifier: identifier,
                            completionHandler: completionHandler
                        )
                    }
                    return
                }
                Task { @MainActor in
                    await self.handle(update: identifier, completionHandler: completionHandler)
                }
            }
            healthStore.execute(query)
            queries.append(query)
            // Immer .immediate: iOS deckelt die Haeufigkeit je Typ selbst,
            // und die App soll das nicht erraten (Spec 9).
            try? await store.enableBackgroundDelivery(for: identifier, frequency: .immediate)
        }
    }

    func unregisterAll() async {
        for query in queries { healthStore.stop(query) }
        queries.removeAll()
        try? await store.disableAllBackgroundDelivery()
    }

    /// Ein Weckruf. Reihenfolge nach Spec 7.2: erst verarbeiten, dann
    /// HealthKit bestaetigen, dann die Warteschlange abarbeiten.
    func handle(update typeIdentifier: String, completionHandler: @escaping () -> Void) async {
        let acknowledge = Acknowledgement(completionHandler)
        // Sicherungsnetz: was auch passiert, bestaetigt wird genau einmal.
        defer { acknowledge.callIfNeeded() }

        _ = await pipeline.handleUpdate(for: typeIdentifier)
        acknowledge.callIfNeeded()

        await pipeline.drainQueue(deadline: Date().addingTimeInterval(Self.wakeWindow))
    }

    /// Fehler der Observer-Abfrage selbst. Auch hier gilt: bestaetigen,
    /// sonst endet die Hintergrundzustellung.
    func handleObserverFailure(
        _ error: Error,
        typeIdentifier: String,
        completionHandler: @escaping () -> Void
    ) {
        let acknowledge = Acknowledgement(completionHandler)
        defer { acknowledge.callIfNeeded() }
        let entry = LogEntry(
            id: UUID(),
            date: Date(),
            kind: .storeUnavailable,
            message: "Observer failed: \(error)",
            typeIdentifier: typeIdentifier,
            actionTypeID: nil
        )
        Task { try? await log.append(entry) }
    }
}

/// Ruft einen Handler hoechstens einmal. Zweimal rufen waere ein Absturz,
/// keinmal rufen das Ende der Hintergrundzustellung.
private final class Acknowledgement {
    private let handler: () -> Void
    private var called = false

    init(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    func callIfNeeded() {
        guard !called else { return }
        called = true
        handler()
    }
}
