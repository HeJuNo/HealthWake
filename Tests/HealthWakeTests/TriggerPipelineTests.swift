import Foundation
import HealthKit
import Testing
@testable import HealthWake

// MARK: - Hilfen

private final class Clock: @unchecked Sendable {
    private let lock = NSLock()
    private var value = Date(timeIntervalSince1970: 1_000_000)
    var now: Date {
        get { lock.lock(); defer { lock.unlock() }; return value }
        set { lock.lock(); value = newValue; lock.unlock() }
    }
    var read: @Sendable () -> Date { { self.now } }
    func advance(_ seconds: TimeInterval) { now = now.addingTimeInterval(seconds) }
}

private final class StepRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var steps: [TriggerPipeline.Step] = []
    var recorded: [TriggerPipeline.Step] {
        lock.lock(); defer { lock.unlock() }; return steps
    }
    var record: @Sendable (TriggerPipeline.Step) -> Void {
        { step in self.lock.lock(); self.steps.append(step); self.lock.unlock() }
    }
}

private actor FakeHealthStore: HealthStoring {
    var result: Result<NewSamples, Error> = .success(NewSamples(events: [], deletedUUIDs: [], newAnchor: Data()))
    var calls = 0
    private(set) var enabledTypes: [String] = []

    func set(_ result: Result<NewSamples, Error>) { self.result = result }

    func requestAuthorization(toRead identifiers: Set<String>) async throws {}
    func wouldPrompt(toRead identifiers: Set<String>) async throws -> Bool { false }
    func enableBackgroundDelivery(for identifier: String, frequency: HKUpdateFrequency) async throws {
        enabledTypes.append(identifier)
    }
    func disableAllBackgroundDelivery() async throws { enabledTypes.removeAll() }
    func newSamples(for identifier: String, anchor: Data?) async throws -> NewSamples {
        calls += 1
        return try result.get()
    }
    func preferredUnitString(for identifier: String) async -> String? { nil }
    func currentAnchor(for identifier: String) async throws -> Data { Data("jetzt".utf8) }
}

private actor ActionLedger {
    var performed: [UUID] = []
    func add(_ id: UUID) { performed.append(id) }
}

private struct RecordingAction: HealthAction {
    struct Config: Codable, Sendable, Equatable { var marker: String }
    static let typeID = "recording"
    static let displayName = "Recording"
    static let defaultConfig = Config(marker: "x")

    let ledger: ActionLedger
    let failure: Bool
    let clockStep: TimeInterval
    let clock: Clock?

    func perform(event: HealthSampleEvent, config: Config) async throws {
        await ledger.add(event.sampleUUID)
        clock?.advance(clockStep)
        if failure { throw HTTPActionError.status(500) }
    }
}

private func makeEvent(
    value: Double = 72.5,
    date: Date = Date(timeIntervalSince1970: 1_000_000),
    uuid: UUID = UUID()
) -> HealthSampleEvent {
    HealthSampleEvent(
        sampleUUID: uuid,
        typeIdentifier: "HKQuantityTypeIdentifierBodyMass",
        typeName: "Weight",
        value: value,
        unit: "kg",
        valueLabel: nil,
        date: date,
        sourceName: "Health"
    )
}

private struct Harness {
    let store: FakeHealthStore
    let subscriptions: SubscriptionStore
    let samples: SampleStore
    let queue: ActionQueue
    let log: EventLog
    let pipeline: TriggerPipeline
    let clock: Clock
    let recorder: StepRecorder
    let ledger: ActionLedger
    let subscriptionID: UUID
    let bindingID: UUID
}

private func makeHarness(
    filter: SubscriptionFilter = SubscriptionFilter(),
    actionFails: Bool = false,
    clockStep: TimeInterval = 0,
    bindings: Int = 1
) async throws -> Harness {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("PipelineTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

    let clock = Clock()
    let recorder = StepRecorder()
    let ledger = ActionLedger()
    let store = FakeHealthStore()
    let subscriptions = SubscriptionStore(fileURL: root.appendingPathComponent("subscriptions.json"))
    let samples = SampleStore(directory: root.appendingPathComponent("samples", isDirectory: true))
    let queue = ActionQueue(fileURL: root.appendingPathComponent("queue.jsonl"), now: clock.read)
    let log = EventLog(fileURL: root.appendingPathComponent("log.json"))

    let configData = try JSONEncoder().encode(RecordingAction.Config(marker: "x"))
    let bindingID = UUID()
    let actions = (0..<bindings).map { index in
        ActionBinding(
            id: index == 0 ? bindingID : UUID(),
            actionTypeID: RecordingAction.typeID,
            configData: configData,
            isEnabled: true
        )
    }
    let subscriptionID = UUID()
    try await subscriptions.upsert(Subscription(
        id: subscriptionID,
        typeIdentifier: "HKQuantityTypeIdentifierBodyMass",
        isEnabled: true,
        filter: filter,
        actions: actions,
        anchorData: Data("alt".utf8),
        lastSampleAt: nil,
        lastTriggeredAt: nil,
        authorizationRequested: true
    ))

    let action = AnyHealthAction(RecordingAction(
        ledger: ledger,
        failure: actionFails,
        clockStep: clockStep,
        clock: clock
    ))
    let pipeline = TriggerPipeline(
        store: store,
        subscriptions: subscriptions,
        samples: samples,
        queue: queue,
        log: log,
        registry: [action],
        now: clock.read,
        progress: recorder.record
    )
    return Harness(
        store: store, subscriptions: subscriptions, samples: samples, queue: queue, log: log,
        pipeline: pipeline, clock: clock, recorder: recorder, ledger: ledger,
        subscriptionID: subscriptionID, bindingID: bindingID
    )
}

// MARK: - Tests

@Test func anchorIsPersistedOnlyAfterSamplesAndJobsAreWritten() async throws {
    let harness = try await makeHarness()
    let event = makeEvent()
    await harness.store.set(.success(NewSamples(
        events: [event], deletedUUIDs: [], newAnchor: Data("neu".utf8)
    )))

    let outcome = await harness.pipeline.handleUpdate(for: event.typeIdentifier)
    #expect(outcome == .processed(sampleCount: 1, jobCount: 1))
    #expect(harness.recorder.recorded == [.samplesWritten, .jobsEnqueued, .anchorPersisted])
    #expect(await harness.subscriptions.all().first?.anchorData == Data("neu".utf8))
}

@Test func anchorIsNotAdvancedWhenTheStoreIsInaccessible() async throws {
    let harness = try await makeHarness()
    await harness.store.set(.failure(HealthStoreError.databaseInaccessible))

    let outcome = await harness.pipeline.handleUpdate(for: "HKQuantityTypeIdentifierBodyMass")
    #expect(outcome == .storeUnavailable)
    #expect(await harness.subscriptions.all().first?.anchorData == Data("alt".utf8))
    #expect(harness.recorder.recorded.isEmpty)
    #expect(await harness.log.entries().contains { $0.kind == .storeUnavailable })
}

@Test func unknownTypeWithoutSubscriptionDoesNothing() async throws {
    let harness = try await makeHarness()
    let outcome = await harness.pipeline.handleUpdate(for: "HKQuantityTypeIdentifierHeight")
    #expect(outcome == .noSubscription)
    #expect(await harness.store.calls == 0)
}

@Test func sameSampleDeliveredTwiceRunsEachActionOnce() async throws {
    let harness = try await makeHarness()
    let event = makeEvent()
    await harness.store.set(.success(NewSamples(
        events: [event], deletedUUIDs: [], newAnchor: Data("neu".utf8)
    )))

    _ = await harness.pipeline.handleUpdate(for: event.typeIdentifier)
    let second = await harness.pipeline.handleUpdate(for: event.typeIdentifier)
    #expect(second == .processed(sampleCount: 1, jobCount: 0))

    await harness.pipeline.drainQueue(deadline: harness.clock.now.addingTimeInterval(60))
    #expect(await harness.ledger.performed == [event.sampleUUID])
    #expect(await harness.queue.all().count == 1)
}

@Test func samplesAreStoredEvenWhenTheFilterRejectsThem() async throws {
    var filter = SubscriptionFilter()
    filter.threshold = .above(1000)
    let harness = try await makeHarness(filter: filter)
    let event = makeEvent(value: 72.5)
    await harness.store.set(.success(NewSamples(
        events: [event], deletedUUIDs: [], newAnchor: Data("neu".utf8)
    )))

    let outcome = await harness.pipeline.handleUpdate(for: event.typeIdentifier)
    #expect(outcome == .processed(sampleCount: 1, jobCount: 0))
    #expect(try harness.samples.events(forTypeIdentifier: event.typeIdentifier) == [event])
    #expect(await harness.queue.all().isEmpty)
}

@Test func deletionsAreLoggedButTriggerNoAction() async throws {
    let harness = try await makeHarness()
    let deleted = UUID()
    await harness.store.set(.success(NewSamples(
        events: [], deletedUUIDs: [deleted], newAnchor: Data("neu".utf8)
    )))

    let outcome = await harness.pipeline.handleUpdate(for: "HKQuantityTypeIdentifierBodyMass")
    #expect(outcome == .processed(sampleCount: 0, jobCount: 0))
    let entries = await harness.log.entries()
    #expect(entries.contains { $0.kind == .sampleDeleted && $0.message.contains(deleted.uuidString) })
    #expect(await harness.queue.all().isEmpty)
}

@Test func drainQueueStopsAtTheDeadlineAndLeavesTheRestPending() async throws {
    let harness = try await makeHarness(clockStep: 6)
    let events = (0..<3).map { makeEvent(value: Double($0), date: Date(timeIntervalSince1970: 1_000_000 + Double($0))) }
    await harness.store.set(.success(NewSamples(
        events: events, deletedUUIDs: [], newAnchor: Data("neu".utf8)
    )))
    _ = await harness.pipeline.handleUpdate(for: events[0].typeIdentifier)
    #expect(await harness.queue.all().count == 3)

    await harness.pipeline.drainQueue(deadline: harness.clock.now.addingTimeInterval(10))
    #expect(await harness.ledger.performed.count == 2)
    let states = await harness.queue.all().map(\.state)
    #expect(states.filter { $0 == .done }.count == 2)
    #expect(states.filter { $0 == .pending }.count == 1)
}

@Test func aFailedActionIsRetriedWithBackoffAndLogged() async throws {
    let harness = try await makeHarness(actionFails: true)
    let event = makeEvent()
    await harness.store.set(.success(NewSamples(
        events: [event], deletedUUIDs: [], newAnchor: Data("neu".utf8)
    )))
    _ = await harness.pipeline.handleUpdate(for: event.typeIdentifier)

    await harness.pipeline.drainQueue(deadline: harness.clock.now.addingTimeInterval(60))
    let job = await harness.queue.all().first
    #expect(job?.state == .pending)
    #expect(job?.attempts == 1)
    #expect(job?.nextAttemptAt == harness.clock.now.addingTimeInterval(ActionQueue.backoff[0]))
    let entries = await harness.log.entries()
    #expect(entries.contains { $0.kind == .actionFailed })
}

@Test func successfulActionIsLogged() async throws {
    let harness = try await makeHarness()
    let event = makeEvent()
    await harness.store.set(.success(NewSamples(
        events: [event], deletedUUIDs: [], newAnchor: Data("neu".utf8)
    )))
    _ = await harness.pipeline.handleUpdate(for: event.typeIdentifier)
    await harness.pipeline.drainQueue(deadline: harness.clock.now.addingTimeInterval(60))

    let entries = await harness.log.entries()
    #expect(entries.contains { $0.kind == .actionSucceeded })
    #expect(entries.contains { $0.kind == .sampleReceived })
    #expect(await harness.queue.all().first?.state == .done)
}
