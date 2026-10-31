import Foundation
import HealthKit
import Testing
@testable import HealthWake

// Regressionstests aus der Durchsicht des ganzen Zweigs. Jeder dieser
// Tests ist einmal fehlgeschlagen; sie bleiben stehen, damit das nicht
// unbemerkt wiederkommt.

private func makeDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("FixTests-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func makeEvent(value: Double = 1, uuid: UUID = UUID()) -> HealthSampleEvent {
    HealthSampleEvent(
        sampleUUID: uuid,
        typeIdentifier: "HKQuantityTypeIdentifierBodyMass",
        typeName: "Weight",
        value: value,
        unit: "kg",
        valueLabel: nil,
        date: Date(timeIntervalSince1970: 1_767_225_600),
        sourceName: "Health"
    )
}

private func makeJob(sample: UUID = UUID(), binding: UUID = UUID()) -> ActionJob {
    ActionJob(
        id: UUID(),
        sampleUUID: sample,
        actionBindingID: binding,
        actionTypeID: "notification",
        event: makeEvent(uuid: sample),
        configData: Data(),
        state: .pending,
        attempts: 0,
        nextAttemptAt: Date(timeIntervalSince1970: 0),
        lastError: nil
    )
}

// MARK: - C2: Anhaengen an eine abgeschnittene Datei

@Test func queueAppendAfterATruncatedLineKeepsBothRecords() async throws {
    let url = makeDirectory().appendingPathComponent("queue.jsonl")
    let queue = ActionQueue(fileURL: url)
    let first = makeJob(), second = makeJob()
    _ = try await queue.enqueue([first, second])

    // Abschuss mitten im Schreiben: die letzte Zeile ist halb da.
    var data = try Data(contentsOf: url)
    data = data.prefix(data.count - 20)
    try data.write(to: url)

    let reopened = ActionQueue(fileURL: url)
    let third = makeJob()
    #expect(try await reopened.enqueue([third]) == 1)

    // Nach einem Neustart muss der neue Auftrag noch da sein -- er darf
    // nicht an den kaputten Rest geklebt und damit unlesbar geworden sein.
    let afterRestart = ActionQueue(fileURL: url)
    let ids = await afterRestart.all().map(\.id)
    #expect(ids.contains(third.id))
    #expect(ids.contains(first.id))
}

@Test func sampleAppendAfterATruncatedLineKeepsBothValues() throws {
    let directory = makeDirectory()
    let store = SampleStore(directory: directory)
    let events = (0..<3).map { makeEvent(value: Double($0)) }
    try store.append(events)

    let file = directory.appendingPathComponent(
        SampleStore.fileName(typeIdentifier: events[0].typeIdentifier, date: events[0].date)
    )
    var data = try Data(contentsOf: file)
    data = data.prefix(data.count - 20)
    try data.write(to: file)

    try store.append([makeEvent(value: 99)])
    let values = try store.events(forTypeIdentifier: events[0].typeIdentifier).map(\.value)
    #expect(values.contains(99))
    #expect(values.contains(0))
}

// MARK: - C1: Ein Auftrag darf nur einmal laufen

@Test func claimNextDueHandsOutEachJobOnlyOnce() async throws {
    let queue = ActionQueue(fileURL: makeDirectory().appendingPathComponent("queue.jsonl"))
    let job = makeJob()
    _ = try await queue.enqueue([job])

    let first = try await queue.claimNextDue()
    let second = try await queue.claimNextDue()
    #expect(first?.id == job.id)
    // Zweiter Zugriff bekommt nichts: der Auftrag laeuft bereits.
    #expect(second == nil)
    #expect(await queue.all().first?.state == .running)
}

@Test func reclaimRunningIsNotPartOfDraining() async throws {
    // Ein Auftrag, der gerade laeuft, darf nicht mitten im Lauf
    // zurueckgeholt und ein zweites Mal gestartet werden. Das Zurueckholen
    // gehoert an den Programmstart, nicht in jeden Durchlauf.
    let queue = ActionQueue(fileURL: makeDirectory().appendingPathComponent("queue.jsonl"))
    let job = makeJob()
    _ = try await queue.enqueue([job])
    _ = try await queue.claimNextDue()

    let pipeline = TriggerPipeline(
        store: NullHealthStore(),
        subscriptions: SubscriptionStore(fileURL: makeDirectory().appendingPathComponent("s.json")),
        samples: SampleStore(directory: makeDirectory()),
        queue: queue,
        log: EventLog(fileURL: makeDirectory().appendingPathComponent("log.json")),
        registry: []
    )
    await pipeline.drainQueue(deadline: Date().addingTimeInterval(5))
    #expect(await queue.all().first?.state == .running)
}

// MARK: - I3: Die Warteschlangendatei darf nicht endlos wachsen

@Test func theQueueFileIsCompactedWhenLinesPileUp() async throws {
    let url = makeDirectory().appendingPathComponent("queue.jsonl")
    let queue = ActionQueue(fileURL: url)
    let job = makeJob()
    _ = try await queue.enqueue([job])
    for _ in 0..<40 {
        try await queue.markRunning(job.id)
        try await queue.markDone(job.id)
    }
    let linesBefore = try Data(contentsOf: url).split(separator: UInt8(ascii: "\n")).count
    #expect(linesBefore > 40)

    // Beim naechsten Start bleibt je Auftrag eine Zeile uebrig -- das
    // Entdoppelungsgedaechtnis bleibt, die Datei waechst nicht weiter.
    let reopened = ActionQueue(fileURL: url)
    #expect(await reopened.all().count == 1)
    let linesAfter = try Data(contentsOf: url).split(separator: UInt8(ascii: "\n")).count
    #expect(linesAfter == 1)
    #expect(await reopened.all().first?.state == .done)
}

@Test func clearingFinishedJobsEmptiesTheQueueFile() async throws {
    let url = makeDirectory().appendingPathComponent("queue.jsonl")
    let queue = ActionQueue(fileURL: url)
    let done = makeJob(), pending = makeJob()
    _ = try await queue.enqueue([done, pending])
    try await queue.markDone(done.id)

    try await queue.clearFinished()
    let remaining = await queue.all()
    #expect(remaining.count == 1)
    #expect(remaining.first?.id == pending.id)
}

// MARK: - I2: Derselbe Wert darf nur einmal in der Ablage stehen

@Test func theSameSampleIsStoredOnlyOnce() throws {
    let store = SampleStore(directory: makeDirectory())
    let event = makeEvent()
    try store.append([event])
    try store.append([event])
    #expect(try store.events(forTypeIdentifier: event.typeIdentifier) == [event])
}

private struct NullHealthStore: HealthStoring {
    func requestAuthorization(toRead identifiers: Set<String>) async throws {}
    func wouldPrompt(toRead identifiers: Set<String>) async throws -> Bool { false }
    func enableBackgroundDelivery(for identifier: String, frequency: HKUpdateFrequency) async throws {}
    func disableAllBackgroundDelivery() async throws {}
    func newSamples(for identifier: String, anchor: Data?) async throws -> NewSamples {
        NewSamples(events: [], deletedUUIDs: [], newAnchor: Data())
    }
    func preferredUnitString(for identifier: String) async -> String? { nil }
    func currentAnchor(for identifier: String) async throws -> Data { Data() }
}
