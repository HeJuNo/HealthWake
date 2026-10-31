import Foundation
import HealthKit
import Testing
@testable import HealthWake

private actor StubHealthStore: HealthStoring {
    var result: Result<NewSamples, Error> = .success(NewSamples(events: [], deletedUUIDs: [], newAnchor: Data("neu".utf8)))

    func set(_ result: Result<NewSamples, Error>) { self.result = result }

    func requestAuthorization(toRead identifiers: Set<String>) async throws {}
    func wouldPrompt(toRead identifiers: Set<String>) async throws -> Bool { false }
    func enableBackgroundDelivery(for identifier: String, frequency: HKUpdateFrequency) async throws {}
    func disableAllBackgroundDelivery() async throws {}
    func newSamples(for identifier: String, anchor: Data?) async throws -> NewSamples { try result.get() }
    func preferredUnitString(for identifier: String) async -> String? { nil }
    func currentAnchor(for identifier: String) async throws -> Data { Data("jetzt".utf8) }
}

private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    var count: Int { lock.lock(); defer { lock.unlock() }; return value }
    func increment() { lock.lock(); value += 1; lock.unlock() }
}

private struct ObserverHarness {
    let store: StubHealthStore
    let observer: HealthObserver
    let log: EventLog
    let subscriptions: SubscriptionStore
}

@MainActor
private func makeObserverHarness(withSubscription: Bool = true) async throws -> ObserverHarness {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("ObserverTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

    let store = StubHealthStore()
    let subscriptions = SubscriptionStore(fileURL: root.appendingPathComponent("subscriptions.json"))
    let log = EventLog(fileURL: root.appendingPathComponent("log.json"))
    if withSubscription {
        try await subscriptions.upsert(Subscription(
            id: UUID(),
            typeIdentifier: "HKQuantityTypeIdentifierBodyMass",
            isEnabled: true,
            filter: SubscriptionFilter(),
            actions: [],
            anchorData: Data("alt".utf8),
            lastSampleAt: nil,
            lastTriggeredAt: nil,
            authorizationRequested: true
        ))
    }
    let pipeline = TriggerPipeline(
        store: store,
        subscriptions: subscriptions,
        samples: SampleStore(directory: root.appendingPathComponent("samples", isDirectory: true)),
        queue: ActionQueue(fileURL: root.appendingPathComponent("queue.jsonl")),
        log: log,
        registry: []
    )
    return ObserverHarness(
        store: store,
        observer: HealthObserver(store: store, pipeline: pipeline, log: log),
        log: log,
        subscriptions: subscriptions
    )
}

@Test @MainActor func completionHandlerIsCalledExactlyOnceOnSuccess() async throws {
    let harness = try await makeObserverHarness()
    let counter = Counter()
    await harness.observer.handle(update: "HKQuantityTypeIdentifierBodyMass") { counter.increment() }
    #expect(counter.count == 1)
}

@Test @MainActor func completionHandlerIsCalledExactlyOnceWhenTheDatabaseIsLocked() async throws {
    let harness = try await makeObserverHarness()
    await harness.store.set(.failure(HealthStoreError.databaseInaccessible))
    let counter = Counter()
    await harness.observer.handle(update: "HKQuantityTypeIdentifierBodyMass") { counter.increment() }
    #expect(counter.count == 1)
    #expect(await harness.log.entries().contains { $0.kind == .storeUnavailable })
}

@Test @MainActor func completionHandlerIsCalledExactlyOnceOnAnUnexpectedError() async throws {
    struct Boom: Error {}
    let harness = try await makeObserverHarness()
    await harness.store.set(.failure(Boom()))
    let counter = Counter()
    await harness.observer.handle(update: "HKQuantityTypeIdentifierBodyMass") { counter.increment() }
    #expect(counter.count == 1)
}

@Test @MainActor func completionHandlerIsCalledExactlyOnceWithoutASubscription() async throws {
    let harness = try await makeObserverHarness(withSubscription: false)
    let counter = Counter()
    await harness.observer.handle(update: "HKQuantityTypeIdentifierBodyMass") { counter.increment() }
    #expect(counter.count == 1)
}

@Test @MainActor func observerErrorStillCallsTheCompletionHandlerOnce() async throws {
    struct Boom: Error {}
    let harness = try await makeObserverHarness()
    let counter = Counter()
    harness.observer.handleObserverFailure(
        Boom(),
        typeIdentifier: "HKQuantityTypeIdentifierBodyMass",
        completionHandler: { counter.increment() }
    )
    #expect(counter.count == 1)
}
