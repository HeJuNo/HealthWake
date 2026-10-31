import Foundation
import HealthKit
import Testing
@testable import HealthWake

private let now = Date(timeIntervalSince1970: 1_800_000_000)
private let week: TimeInterval = 7 * 24 * 60 * 60

private func subscription(
    authorizationRequested: Bool = true,
    createdAt: Date = now,
    lastSampleAt: Date? = nil
) -> Subscription {
    Subscription(
        id: UUID(),
        typeIdentifier: "HKQuantityTypeIdentifierBodyMass",
        isEnabled: true,
        filter: SubscriptionFilter(),
        actions: [],
        anchorData: Data("anker".utf8),
        lastSampleAt: lastSampleAt,
        lastTriggeredAt: nil,
        authorizationRequested: authorizationRequested,
        createdAt: createdAt
    )
}

@Test func statusIsNotAskedYetBeforeTheDialog() {
    let status = SubscriptionStatus.of(subscription(authorizationRequested: false), now: now)
    #expect(status == .notAskedYet)
}

@Test func statusWaitsForTheFirstSample() {
    let created = now.addingTimeInterval(-3600)
    let status = SubscriptionStatus.of(subscription(createdAt: created), now: now)
    #expect(status == .waitingForFirstSample(since: created))
}

@Test func statusIsReceivingUpToSevenDays() {
    let last = now.addingTimeInterval(-week)
    #expect(SubscriptionStatus.of(subscription(lastSampleAt: last), now: now) == .receiving(lastAt: last))
    let older = now.addingTimeInterval(-week - 1)
    #expect(SubscriptionStatus.of(subscription(lastSampleAt: older), now: now) == .stale(lastAt: older))
}

@Test func statusIsStaleAfterSevenSilentDaysWithoutAnySample() {
    let created = now.addingTimeInterval(-week - 1)
    #expect(SubscriptionStatus.of(subscription(createdAt: created), now: now) == .stale(lastAt: nil))
    let justInside = now.addingTimeInterval(-week)
    #expect(SubscriptionStatus.of(subscription(createdAt: justInside), now: now)
        == .waitingForFirstSample(since: justInside))
}

@Test func noStatusClaimsThatAccessWasGranted() {
    // HealthKit verraet nie, ob Lesen erlaubt wurde. Die Oberflaeche darf es
    // deshalb auch nicht behaupten (Spec 5.7, 8).
    let states: [SubscriptionStatus] = [
        .notAskedYet,
        .waitingForFirstSample(since: now),
        .receiving(lastAt: now),
        .stale(lastAt: now),
        .stale(lastAt: nil),
    ]
    for state in states {
        let label = state.label.lowercased()
        #expect(!label.isEmpty)
        for forbidden in ["granted", "allowed", "authorized", "permission"] {
            #expect(!label.contains(forbidden))
        }
    }
}

// MARK: - Erstaktivierung

private actor HistoryStore: HealthStoring {
    private(set) var anchorsSeen: [Data?] = []
    let historical: HealthSampleEvent
    let fresh: HealthSampleEvent

    init(historical: HealthSampleEvent, fresh: HealthSampleEvent) {
        self.historical = historical
        self.fresh = fresh
    }

    func requestAuthorization(toRead identifiers: Set<String>) async throws {}
    func wouldPrompt(toRead identifiers: Set<String>) async throws -> Bool { true }
    func enableBackgroundDelivery(for identifier: String, frequency: HKUpdateFrequency) async throws {}
    func disableAllBackgroundDelivery() async throws {}
    func preferredUnitString(for identifier: String) async -> String? { nil }
    func currentAnchor(for identifier: String) async throws -> Data { Data("jetzt".utf8) }

    /// Mit leerem Anker liefert HealthKit die GESAMTE Historie -- genau das
    /// bildet dieser Fake nach.
    func newSamples(for identifier: String, anchor: Data?) async throws -> NewSamples {
        anchorsSeen.append(anchor)
        if anchor == nil {
            return NewSamples(events: [historical, fresh], deletedUUIDs: [], newAnchor: Data("spaeter".utf8))
        }
        return NewSamples(events: [fresh], deletedUUIDs: [], newAnchor: Data("spaeter".utf8))
    }
}

@Test @MainActor func activatingATypeStartsFromNowAndReplaysNoHistory() async throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("ActivationTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

    let activation = Date(timeIntervalSince1970: 1_800_000_000)
    let historical = HealthSampleEvent(
        sampleUUID: UUID(), typeIdentifier: "HKQuantityTypeIdentifierStepCount", typeName: "Step Count",
        value: 1234, unit: "count", valueLabel: nil,
        date: activation.addingTimeInterval(-365 * 24 * 3600), sourceName: "iPhone"
    )
    let fresh = HealthSampleEvent(
        sampleUUID: UUID(), typeIdentifier: "HKQuantityTypeIdentifierStepCount", typeName: "Step Count",
        value: 42, unit: "count", valueLabel: nil,
        date: activation.addingTimeInterval(60), sourceName: "iPhone"
    )
    let store = HistoryStore(historical: historical, fresh: fresh)
    let environment = AppEnvironment(
        store: store,
        directory: root,
        registry: [],
        defaults: UserDefaults(suiteName: "HealthWakeTests-\(UUID().uuidString)")!
    )

    let created = try await environment.addSubscription(typeIdentifier: "HKQuantityTypeIdentifierStepCount")
    // Der Anker steht sofort auf "jetzt" -- nicht auf nil.
    #expect(created.anchorData == Data("jetzt".utf8))
    #expect(created.authorizationRequested)

    _ = await environment.pipeline.handleUpdate(for: "HKQuantityTypeIdentifierStepCount")
    #expect(await store.anchorsSeen == [Data("jetzt".utf8)])

    let stored = try environment.samples.events(forTypeIdentifier: "HKQuantityTypeIdentifierStepCount")
    #expect(stored == [fresh])
    #expect(!stored.contains { $0.date < activation })
}
