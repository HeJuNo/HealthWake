import Foundation

/// Die Reihenfolge, in der ein Weckruf abgearbeitet wird -- und damit das
/// Herz des Entwurfs (Spec 7.2, 14.2):
///
///   1. Neue Werte holen (verankerte Abfrage)
///   2. Werte dauerhaft schreiben, mit fsync
///   3. Auftraege dauerhaft schreiben, mit fsync
///   4. Erst jetzt den Anker vorrruecken
///   5. Den Completion-Handler von HealthKit rufen (macht der Observer)
///   6. Warteschlange abarbeiten, solange das Weckfenster reicht
///
/// Wird die App zwischen 3 und 4 abgeschossen, kommen dieselben Werte beim
/// naechsten Weckruf noch einmal -- und die Entdoppelung der Warteschlange
/// sorgt dafuer, dass jede Aktion trotzdem genau einmal laeuft. Umgekehrt
/// (Anker vor den Daten) waeren die Werte fuer immer verloren.
actor TriggerPipeline {
    enum Outcome: Sendable, Equatable {
        case processed(sampleCount: Int, jobCount: Int)
        case storeUnavailable
        case noSubscription
    }

    /// Nur zum Pruefen der Reihenfolge. In der App bleibt der Haken leer.
    enum Step: Sendable, Equatable {
        case samplesWritten
        case jobsEnqueued
        case anchorPersisted
    }

    private let store: any HealthStoring
    private let subscriptions: SubscriptionStore
    private let samples: SampleStore
    private let queue: ActionQueue
    private let log: EventLog
    private let registry: [AnyHealthAction]
    private let now: @Sendable () -> Date
    private let progress: @Sendable (Step) -> Void
    private var inFlight: [String: Task<Outcome, Never>] = [:]
    private var isDraining = false

    init(
        store: any HealthStoring,
        subscriptions: SubscriptionStore,
        samples: SampleStore,
        queue: ActionQueue,
        log: EventLog,
        registry: [AnyHealthAction],
        now: @Sendable @escaping () -> Date = { Date() },
        progress: @Sendable @escaping (Step) -> Void = { _ in }
    ) {
        self.store = store
        self.subscriptions = subscriptions
        self.samples = samples
        self.queue = queue
        self.log = log
        self.registry = registry
        self.now = now
        self.progress = progress
    }

    /// Zwei Weckrufe fuer denselben Typ duerfen nicht nebeneinander laufen
    /// -- ein Aktor haelt zwar jeden einzelnen Schritt zusammen, gibt aber
    /// an jedem await ab. Der zweite Aufrufer wartet deshalb auf das
    /// Ergebnis des ersten, statt dieselben Werte noch einmal zu verarbeiten.
    func handleUpdate(for typeIdentifier: String) async -> Outcome {
        if let running = inFlight[typeIdentifier] {
            return await running.value
        }
        let task = Task { await self.performUpdate(for: typeIdentifier) }
        inFlight[typeIdentifier] = task
        let outcome = await task.value
        inFlight[typeIdentifier] = nil
        return outcome
    }

    private func performUpdate(for typeIdentifier: String) async -> Outcome {
        guard let subscription = await subscriptions.subscription(forTypeIdentifier: typeIdentifier),
              subscription.isEnabled
        else { return .noSubscription }

        do {
            let result = try await store.newSamples(for: typeIdentifier, anchor: subscription.anchorData)

            // Werte zuerst, und unabhaengig vom Filter: die Trendansicht soll
            // auch das zeigen, was keine Aktion ausgeloest hat (Spec 14.1).
            try samples.append(result.events)
            progress(.samplesWritten)

            var lastTriggeredAt = subscription.lastTriggeredAt
            var jobs: [ActionJob] = []
            for event in result.events {
                guard FilterEvaluator.passes(
                    event,
                    filter: subscription.filter,
                    lastTriggeredAt: lastTriggeredAt
                ) else { continue }
                lastTriggeredAt = event.date
                for binding in subscription.actions where binding.isEnabled {
                    jobs.append(ActionJob(
                        id: UUID(),
                        sampleUUID: event.sampleUUID,
                        actionBindingID: binding.id,
                        actionTypeID: binding.actionTypeID,
                        event: event,
                        configData: binding.configData,
                        state: .pending,
                        attempts: 0,
                        nextAttemptAt: now(),
                        lastError: nil
                    ))
                }
            }
            let accepted = try await queue.enqueue(jobs)
            progress(.jobsEnqueued)

            var updated = subscription
            updated.anchorData = result.newAnchor
            updated.lastSampleAt = result.events.map(\.date).max() ?? subscription.lastSampleAt
            updated.lastTriggeredAt = lastTriggeredAt
            try await subscriptions.upsert(updated)
            progress(.anchorPersisted)

            await logSamples(result, typeIdentifier: typeIdentifier)
            return .processed(sampleCount: result.events.count, jobCount: accepted)
        } catch HealthStoreError.databaseInaccessible {
            await append(.storeUnavailable, "Health database locked, trying again later", typeIdentifier)
            return .storeUnavailable
        } catch {
            // Jeder andere Fehler hat dieselbe Folge: der Anker bleibt stehen,
            // beim naechsten Weckruf wird es noch einmal versucht.
            await append(.storeUnavailable, "Could not read new samples: \(error)", typeIdentifier)
            return .storeUnavailable
        }
    }

    /// Arbeitet die Warteschlange ab, bis sie leer ist oder die Zeit ablaeuft.
    /// Die Frist ist das Weckfenster: was nicht mehr hineinpasst, bleibt
    /// liegen und kommt beim naechsten Weckruf dran.
    func drainQueue(deadline: Date) async {
        // Zweimal gleichzeitig abarbeiten hiesse zweimal senden. Das Wecken
        // kommt aus sechs Richtungen -- Start, Vordergrund, Entsperren,
        // Weckruf, Ziehen zum Aktualisieren, Wiederholung von Hand --,
        // deshalb der Riegel.
        guard !isDraining else { return }
        isDraining = true
        defer { isDraining = false }

        while now() < deadline {
            // Holen und auf "laeuft" setzen in einem Zug; "zurueckholen"
            // gehoert an den Programmstart, nicht hierher -- sonst risse es
            // einen gerade laufenden Upload aus der Bahn und schickte ihn
            // ein zweites Mal.
            guard let job = (try? await queue.claimNextDue()) ?? nil else { break }
            guard let action = registry.first(where: { $0.typeID == job.actionTypeID }) else {
                try? await queue.markFailed(job.id, error: "Unknown action \(job.actionTypeID)")
                await append(.actionFailed, "Unknown action \(job.actionTypeID)", job.event.typeIdentifier, job.actionTypeID)
                continue
            }
            do {
                try await action.perform(job.event, job.configData)
                try? await queue.markDone(job.id)
                await append(
                    .actionSucceeded,
                    "\(action.displayName) ran for \(job.event.typeName)",
                    job.event.typeIdentifier,
                    job.actionTypeID
                )
            } catch {
                try? await queue.markFailed(job.id, error: String(describing: error))
                await append(
                    .actionFailed,
                    "\(action.displayName) failed: \(error)",
                    job.event.typeIdentifier,
                    job.actionTypeID
                )
            }
        }
    }

    // MARK: - Protokoll

    private func logSamples(_ result: NewSamples, typeIdentifier: String) async {
        for event in result.events {
            let unit = event.unit.map { " \($0)" } ?? ""
            let text = event.valueLabel ?? "\(event.value)\(unit)"
            await append(.sampleReceived, "\(event.typeName): \(text) from \(event.sourceName)", typeIdentifier)
        }
        for uuid in result.deletedUUIDs {
            await append(.sampleDeleted, "Sample deleted in Health: \(uuid.uuidString)", typeIdentifier)
        }
    }

    private func append(
        _ kind: LogEntry.Kind,
        _ message: String,
        _ typeIdentifier: String?,
        _ actionTypeID: String? = nil
    ) async {
        // Ein Protokoll, das sich nicht schreiben laesst, darf keine Aktion
        // zu Fall bringen.
        try? await log.append(LogEntry(
            id: UUID(),
            date: now(),
            kind: kind,
            message: message,
            typeIdentifier: typeIdentifier,
            actionTypeID: actionTypeID
        ))
    }
}
