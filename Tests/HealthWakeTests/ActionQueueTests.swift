import Foundation
import Testing
@testable import HealthWake

private func makeFileURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("ActionQueueTests-\(UUID().uuidString).jsonl")
}

private func makeJob(
    sampleUUID: UUID = UUID(),
    bindingID: UUID = UUID(),
    actionTypeID: String = "notification",
    nextAttemptAt: Date = Date(timeIntervalSince1970: 0)
) -> ActionJob {
    let event = HealthSampleEvent(
        sampleUUID: sampleUUID,
        typeIdentifier: "HKQuantityTypeIdentifierBodyMass",
        typeName: "Weight",
        value: 72.5,
        unit: "kg",
        valueLabel: nil,
        date: Date(timeIntervalSince1970: 1_767_225_600),
        sourceName: "Health"
    )
    return ActionJob(
        id: UUID(),
        sampleUUID: sampleUUID,
        actionBindingID: bindingID,
        actionTypeID: actionTypeID,
        event: event,
        configData: Data(),
        state: .pending,
        attempts: 0,
        nextAttemptAt: nextAttemptAt,
        lastError: nil
    )
}

/// Steuerbare Uhr, damit Wartezeiten ohne echtes Warten pruefbar sind.
private final class Clock: @unchecked Sendable {
    var now = Date(timeIntervalSince1970: 1_000_000)
    var read: @Sendable () -> Date { { self.now } }
}

@Test func enqueueSkipsDuplicateDedupeKeys() async throws {
    let queue = ActionQueue(fileURL: makeFileURL())
    let sample = UUID(), binding = UUID()
    let first = makeJob(sampleUUID: sample, bindingID: binding)
    let again = makeJob(sampleUUID: sample, bindingID: binding)
    #expect(try await queue.enqueue([first]) == 1)
    #expect(try await queue.enqueue([again]) == 0)
    #expect(await queue.all().count == 1)
}

@Test func doneJobIsNotReEnqueued() async throws {
    let queue = ActionQueue(fileURL: makeFileURL())
    let sample = UUID(), binding = UUID()
    let job = makeJob(sampleUUID: sample, bindingID: binding)
    _ = try await queue.enqueue([job])
    try await queue.markDone(job.id)
    #expect(try await queue.enqueue([makeJob(sampleUUID: sample, bindingID: binding)]) == 0)
}

@Test func reclaimRunningMovesJobsBackToPending() async throws {
    let url = makeFileURL()
    let queue = ActionQueue(fileURL: url)
    let job = makeJob()
    _ = try await queue.enqueue([job])
    try await queue.markRunning(job.id)
    try await queue.markFailed(job.id, error: "weggestorben")

    // Neustart: ein Auftrag, der beim Abschuss noch lief, muss wieder dran.
    let afterRelaunch = ActionQueue(fileURL: url)
    let running = makeJob()
    _ = try await afterRelaunch.enqueue([running])
    try await afterRelaunch.markRunning(running.id)
    #expect(try await afterRelaunch.reclaimRunning() == 1)
    let reclaimed = await afterRelaunch.all().first { $0.id == running.id }
    #expect(reclaimed?.state == .pending)
    #expect(reclaimed?.attempts == 0)
}

@Test func idempotencyKeyIsStableAcrossRetries() async throws {
    let clock = Clock()
    let queue = ActionQueue(fileURL: makeFileURL(), now: clock.read)
    let job = makeJob()
    _ = try await queue.enqueue([job])
    let before = await queue.all().first?.idempotencyKey
    try await queue.markRunning(job.id)
    try await queue.markFailed(job.id, error: "503")
    let after = await queue.all().first?.idempotencyKey
    #expect(before == after)
    #expect(after == job.sampleUUID.uuidString)
}

@Test func markFailedAppliesBackoffThenGivesUp() async throws {
    let clock = Clock()
    let queue = ActionQueue(fileURL: makeFileURL(), now: clock.read)
    let job = makeJob()
    _ = try await queue.enqueue([job])

    try await queue.markFailed(job.id, error: "1")
    var current = await queue.all().first { $0.id == job.id }
    #expect(current?.state == .pending)
    #expect(current?.attempts == 1)
    #expect(current?.nextAttemptAt == clock.now.addingTimeInterval(ActionQueue.backoff[0]))
    #expect(current?.lastError == "1")

    for attempt in 2...4 {
        try await queue.markFailed(job.id, error: "\(attempt)")
        current = await queue.all().first { $0.id == job.id }
        #expect(current?.state == .pending)
        #expect(current?.nextAttemptAt == clock.now.addingTimeInterval(ActionQueue.backoff[attempt - 1]))
    }

    try await queue.markFailed(job.id, error: "5")
    current = await queue.all().first { $0.id == job.id }
    #expect(current?.attempts == 5)
    #expect(current?.state == .failed)
    #expect(await queue.nextDue() == nil)
}

@Test func nextDueRespectsNextAttemptAt() async throws {
    let clock = Clock()
    let queue = ActionQueue(fileURL: makeFileURL(), now: clock.read)
    let later = makeJob(nextAttemptAt: clock.now.addingTimeInterval(60))
    let ready = makeJob(nextAttemptAt: clock.now.addingTimeInterval(-60))
    _ = try await queue.enqueue([later, ready])
    #expect(await queue.nextDue()?.id == ready.id)
    try await queue.markDone(ready.id)
    #expect(await queue.nextDue() == nil)
    clock.now = clock.now.addingTimeInterval(120)
    #expect(await queue.nextDue()?.id == later.id)
}

@Test func requeueResetsStateAndAttempts() async throws {
    let clock = Clock()
    let queue = ActionQueue(fileURL: makeFileURL(), now: clock.read)
    let job = makeJob()
    _ = try await queue.enqueue([job])
    for attempt in 1...5 { try await queue.markFailed(job.id, error: "\(attempt)") }
    #expect(await queue.all().first?.state == .failed)

    try await queue.requeue(job.id)
    let current = await queue.all().first { $0.id == job.id }
    #expect(current?.state == .pending)
    #expect(current?.attempts == 0)
    #expect(current?.nextAttemptAt == clock.now)
    #expect(await queue.nextDue()?.id == job.id)
}

@Test func truncatedFinalLineIsSkippedAndRestLoads() async throws {
    let url = makeFileURL()
    let queue = ActionQueue(fileURL: url)
    let first = makeJob(), second = makeJob()
    _ = try await queue.enqueue([first, second])

    var data = try Data(contentsOf: url)
    data = data.prefix(data.count - 20)   // letzte Zeile mitten durchgeschnitten
    try data.write(to: url)

    let reopened = ActionQueue(fileURL: url)
    let loaded = await reopened.all()
    #expect(loaded.count == 1)
    #expect(loaded.first?.id == first.id)
}
