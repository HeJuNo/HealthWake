import Foundation
import HealthKit
import Testing
@testable import HealthWake

private actor SwitchableStore: HealthStoring {
    private(set) var disableAllCalls = 0
    private(set) var enabledTypes: [String] = []
    private(set) var anchorRequests: [String] = []
    var anchor = Data("jetzt".utf8)

    func requestAuthorization(toRead identifiers: Set<String>) async throws {}
    func wouldPrompt(toRead identifiers: Set<String>) async throws -> Bool { false }
    func enableBackgroundDelivery(for identifier: String, frequency: HKUpdateFrequency) async throws {
        enabledTypes.append(identifier)
    }
    func disableAllBackgroundDelivery() async throws {
        disableAllCalls += 1
        enabledTypes.removeAll()
    }
    func newSamples(for identifier: String, anchor: Data?) async throws -> NewSamples {
        NewSamples(events: [], deletedUUIDs: [], newAnchor: anchor ?? Data())
    }
    func preferredUnitString(for identifier: String) async -> String? { nil }
    func currentAnchor(for identifier: String) async throws -> Data {
        anchorRequests.append(identifier)
        return anchor
    }
}

@MainActor
private func makeEnvironment() async throws -> (AppEnvironment, SwitchableStore) {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("AppEnvironmentTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let store = SwitchableStore()
    let defaults = UserDefaults(suiteName: "HealthWakeTests-\(UUID().uuidString)")!
    let environment = AppEnvironment(store: store, directory: root, registry: [], defaults: defaults)
    try await environment.subscriptions.upsert(Subscription(
        id: UUID(),
        typeIdentifier: "HKQuantityTypeIdentifierBodyMass",
        isEnabled: true,
        filter: SubscriptionFilter(),
        actions: [],
        anchorData: Data("uralt".utf8),
        lastSampleAt: nil,
        lastTriggeredAt: nil,
        authorizationRequested: true
    ))
    return (environment, store)
}

@Test @MainActor func switchingOffDisablesDeliveryAndLogsIt() async throws {
    let (environment, store) = try await makeEnvironment()
    await environment.setGloballyEnabled(false)

    #expect(environment.isGloballyEnabled == false)
    #expect(await store.disableAllCalls >= 1)
    #expect(await environment.log.entries().contains { $0.kind == .deliveryDisabled })
}

@Test @MainActor func switchingOnResetsAnchorsToNowInsteadOfNil() async throws {
    let (environment, store) = try await makeEnvironment()
    await environment.setGloballyEnabled(false)
    await environment.setGloballyEnabled(true)

    #expect(environment.isGloballyEnabled)
    let subscription = await environment.subscriptions.all().first
    // Nicht nil: ein leerer Anker wuerde die gesamte Historie nachliefern.
    #expect(subscription?.anchorData != nil)
    #expect(subscription?.anchorData == Data("jetzt".utf8))
    #expect(await store.anchorRequests == ["HKQuantityTypeIdentifierBodyMass"])
    #expect(await environment.log.entries().contains { $0.kind == .deliveryEnabled })
}

@Test @MainActor func switchingOffThenOnLeavesNoStaleAnchor() async throws {
    let (environment, store) = try await makeEnvironment()
    await store.setAnchor(Data("neuer-anker".utf8))
    await environment.setGloballyEnabled(false)
    await environment.setGloballyEnabled(true)

    let anchors = await environment.subscriptions.all().compactMap(\.anchorData)
    #expect(anchors == [Data("neuer-anker".utf8)])
    #expect(!anchors.contains(Data("uralt".utf8)))
}

@Test @MainActor func theGapIsVisibleInTheLog() async throws {
    let (environment, _) = try await makeEnvironment()
    await environment.setGloballyEnabled(false)
    await environment.setGloballyEnabled(true)

    let kinds = await environment.log.entries().map(\.kind)
    // Neueste zuerst: zuerst eingeschaltet, davor ausgeschaltet -- das
    // Schweigen dazwischen ist damit erklaert.
    #expect(kinds.first == .deliveryEnabled)
    #expect(kinds.contains(.deliveryDisabled))
}

extension SwitchableStore {
    func setAnchor(_ data: Data) { anchor = data }
}
