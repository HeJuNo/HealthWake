import Foundation
import Testing
@testable import HealthWake

private func makeDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("SampleStoreTests-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func makeEvent(
    type: String = "HKQuantityTypeIdentifierBodyMass",
    value: Double = 72.5,
    date: Date = Date(timeIntervalSince1970: 1_767_225_600)   // 2026-01-01T00:00:00Z
) -> HealthSampleEvent {
    HealthSampleEvent(
        sampleUUID: UUID(),
        typeIdentifier: type,
        typeName: "Weight",
        value: value,
        unit: "kg",
        valueLabel: nil,
        date: date,
        sourceName: "Health"
    )
}

@Test func appendThenReadRoundTrips() throws {
    let store = SampleStore(directory: makeDirectory())
    let event = makeEvent()
    try store.append([event])
    let loaded = try store.events(forTypeIdentifier: event.typeIdentifier)
    #expect(loaded == [event])
}

@Test func eventsAreSplitByTypeAndMonth() throws {
    let directory = makeDirectory()
    let store = SampleStore(directory: directory)
    let january = makeEvent(date: Date(timeIntervalSince1970: 1_767_225_600))   // 2026-01-01
    let february = makeEvent(date: Date(timeIntervalSince1970: 1_769_904_000))  // 2026-02-01
    let other = makeEvent(type: "HKQuantityTypeIdentifierHeight")
    try store.append([january, february, other])

    let files = try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
    #expect(files.count == 3)
    #expect(files.contains("HKQuantityTypeIdentifierBodyMass-2026-01.jsonl"))
    #expect(files.contains("HKQuantityTypeIdentifierBodyMass-2026-02.jsonl"))
    #expect(try store.events(forTypeIdentifier: "HKQuantityTypeIdentifierBodyMass").count == 2)
    #expect(try store.events(forTypeIdentifier: "HKQuantityTypeIdentifierHeight").count == 1)
}

@Test func truncatedFinalLineIsSkippedAndRestLoads() throws {
    let directory = makeDirectory()
    let store = SampleStore(directory: directory)
    let events = (0..<3).map { makeEvent(value: Double($0)) }
    try store.append(events)

    let file = directory.appendingPathComponent(
        SampleStore.fileName(typeIdentifier: events[0].typeIdentifier, date: events[0].date)
    )
    let contents = try Data(contentsOf: file)
    let lines = contents.split(separator: UInt8(ascii: "\n"))
    var truncated = Data()
    truncated.append(contentsOf: lines[0]); truncated.append(UInt8(ascii: "\n"))
    truncated.append(contentsOf: lines[1]); truncated.append(UInt8(ascii: "\n"))
    truncated.append(contentsOf: lines[2].prefix(lines[2].count / 2))
    try truncated.write(to: file)

    let loaded = try store.events(forTypeIdentifier: events[0].typeIdentifier)
    #expect(loaded.count == 2)
    #expect(loaded.map(\.value) == [0, 1])
}

@Test func removeAllEmptiesTheDirectory() throws {
    let directory = makeDirectory()
    let store = SampleStore(directory: directory)
    try store.append([makeEvent()])
    try store.removeAll()
    #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).isEmpty)
    #expect(try store.events(forTypeIdentifier: "HKQuantityTypeIdentifierBodyMass").isEmpty)
}

@Test func totalByteCountGrowsWithAppends() throws {
    let store = SampleStore(directory: makeDirectory())
    #expect(try store.totalByteCount() == 0)
    try store.append([makeEvent()])
    let afterOne = try store.totalByteCount()
    #expect(afterOne > 0)
    try store.append([makeEvent(value: 80)])
    #expect(try store.totalByteCount() > afterOne)
}

@Test func appendIsAtomicPerCallAndFileIsProtected() throws {
    let directory = makeDirectory()
    let store = SampleStore(directory: directory)
    let events = (0..<3).map { makeEvent(value: Double($0)) }
    try store.append(events)

    let file = directory.appendingPathComponent(
        SampleStore.fileName(typeIdentifier: events[0].typeIdentifier, date: events[0].date)
    )
    // Jeder Aufruf schreibt ganze Zeilen: drei Ereignisse, drei lesbare Zeilen,
    // kein abgeschnittener Rest.
    let text = try String(contentsOf: file, encoding: .utf8)
    #expect(text.hasSuffix("\n"))
    #expect(text.split(separator: "\n").count == 3)
    #expect(try store.events(forTypeIdentifier: events[0].typeIdentifier).count == 3)

    // Schutzklasse: der Simulator meldet das Attribut nicht immer zurueck.
    // Wo er es meldet, muss es die geforderte Klasse sein (Spec 11.4).
    let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
    if let protection = attributes[.protectionKey] as? FileProtectionType {
        #expect(protection == .completeUntilFirstUserAuthentication)
    }
}
