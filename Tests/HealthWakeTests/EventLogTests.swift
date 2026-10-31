import Foundation
import Testing
@testable import HealthWake

private func makeFileURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("EventLogTests-\(UUID().uuidString).json")
}

private func makeEntry(
    kind: LogEntry.Kind = .sampleReceived,
    message: String = "Weight 72.5 kg",
    date: Date = Date(timeIntervalSince1970: 1_767_225_600)
) -> LogEntry {
    LogEntry(
        id: UUID(),
        date: date,
        kind: kind,
        message: message,
        typeIdentifier: "HKQuantityTypeIdentifierBodyMass",
        actionTypeID: nil
    )
}

@Test func logEntriesRoundTrip() async throws {
    let url = makeFileURL()
    let log = EventLog(fileURL: url)
    let entry = makeEntry()
    try await log.append(entry)

    let reopened = EventLog(fileURL: url)
    #expect(await reopened.entries() == [entry])
}

@Test func entriesAreNewestFirst() async throws {
    let log = EventLog(fileURL: makeFileURL())
    let older = makeEntry(message: "older", date: Date(timeIntervalSince1970: 1_000))
    let newer = makeEntry(message: "newer", date: Date(timeIntervalSince1970: 2_000))
    try await log.append(older)
    try await log.append(newer)
    #expect(await log.entries().map(\.message) == ["newer", "older"])
}

@Test func exceedingTheLimitDropsTheOldest() async throws {
    let log = EventLog(fileURL: makeFileURL(), limit: 3)
    for index in 0..<5 {
        try await log.append(makeEntry(message: "\(index)", date: Date(timeIntervalSince1970: Double(index))))
    }
    let messages = await log.entries().map(\.message)
    #expect(messages.count == 3)
    #expect(messages == ["4", "3", "2"])
}

@Test func exportTextContainsTheErrorMessage() async throws {
    let log = EventLog(fileURL: makeFileURL())
    let failure = makeEntry(kind: .actionFailed, message: "HTTP 500 from example.com")
    try await log.append(makeEntry())
    try await log.append(failure)
    let text = await log.exportText()
    #expect(text.contains("HTTP 500 from example.com"))
    #expect(failure.isError)
}

@Test func corruptFileLoadsAsEmpty() async throws {
    let url = makeFileURL()
    try Data("kein JSON".utf8).write(to: url)
    let log = EventLog(fileURL: url)
    #expect(await log.entries().isEmpty)
    // Und bleibt benutzbar: der naechste Eintrag ersetzt die kaputte Datei.
    try await log.append(makeEntry())
    #expect(await log.entries().count == 1)
}

@Test func removeAllClearsTheLog() async throws {
    let url = makeFileURL()
    let log = EventLog(fileURL: url)
    try await log.append(makeEntry())
    try await log.removeAll()
    #expect(await log.entries().isEmpty)
    #expect(await EventLog(fileURL: url).entries().isEmpty)
}
