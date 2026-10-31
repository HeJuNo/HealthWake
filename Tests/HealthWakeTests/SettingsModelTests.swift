import Foundation
import Testing
@testable import HealthWake

private func makeDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("SettingsModelTests-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func makeEvent() -> HealthSampleEvent {
    HealthSampleEvent(
        sampleUUID: UUID(),
        typeIdentifier: "HKQuantityTypeIdentifierBodyMass",
        typeName: "Weight",
        value: 72.5,
        unit: "kg",
        valueLabel: nil,
        date: Date(timeIntervalSince1970: 1_767_225_600),
        sourceName: "Health"
    )
}

private func makeJob(state: ActionJob.State) -> ActionJob {
    ActionJob(
        id: UUID(),
        sampleUUID: UUID(),
        actionBindingID: UUID(),
        actionTypeID: "notification",
        event: makeEvent(),
        configData: Data(),
        state: state,
        attempts: 5,
        nextAttemptAt: Date(timeIntervalSince1970: 0),
        lastError: "HTTP 500"
    )
}

@Test func storedSizeIsHumanReadableAndZeroAfterClearing() async throws {
    let directory = makeDirectory()
    let samples = SampleStore(directory: directory.appendingPathComponent("samples", isDirectory: true))
    let model = StorageModel(samples: samples)

    #expect(await model.storedSizeText() == "Zero KB")
    try samples.append([makeEvent(), makeEvent()])
    let filled = await model.storedSizeText()
    #expect(filled != "Zero KB")
    // Lesbar heisst: eine Zahl und eine Einheit, egal ob "bytes" oder "KB".
    #expect(filled.contains { $0.isNumber })
    #expect(filled.lowercased().contains("byte") || filled.lowercased().contains("kb"))

    try await model.clearStoredSamples()
    #expect(await model.storedSizeText() == "Zero KB")
    #expect(try samples.events(forTypeIdentifier: "HKQuantityTypeIdentifierBodyMass").isEmpty)
}

@Test func failedJobsAreSurfacedAndCanBeRequeued() async throws {
    let directory = makeDirectory()
    let queue = ActionQueue(fileURL: directory.appendingPathComponent("queue.jsonl"))
    let failed = makeJob(state: .pending)
    _ = try await queue.enqueue([failed, makeJob(state: .pending)])
    for _ in 1...5 { try await queue.markFailed(failed.id, error: "HTTP 500") }

    let model = FailedJobsModel(queue: queue)
    let listed = await model.failedJobs()
    #expect(listed.count == 1)
    #expect(listed.first?.id == failed.id)
    #expect(listed.first?.lastError == "HTTP 500")

    await model.requeue(listed.first!.id)
    #expect(await model.failedJobs().isEmpty)
    let revived = await queue.all().first { $0.id == failed.id }
    #expect(revived?.state == .pending)
    #expect(revived?.attempts == 0)
}
