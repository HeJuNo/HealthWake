import Foundation
import Testing
@testable import HealthWake

private func makeFileURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("SubscriptionStoreTests-\(UUID().uuidString).json")
}

private func makeSubscription(type: String = "HKQuantityTypeIdentifierBodyMass") -> Subscription {
    Subscription(
        id: UUID(),
        typeIdentifier: type,
        isEnabled: true,
        filter: SubscriptionFilter(),
        actions: [
            ActionBinding(id: UUID(), actionTypeID: "notification", configData: Data("{}".utf8), isEnabled: true)
        ],
        anchorData: nil,
        lastSampleAt: nil,
        lastTriggeredAt: nil,
        authorizationRequested: false
    )
}

@Test func missingFileLoadsAsEmpty() async throws {
    let store = SubscriptionStore(fileURL: makeFileURL())
    try await store.load()
    #expect(await store.all().isEmpty)
}

@Test func subscriptionsRoundTrip() async throws {
    let url = makeFileURL()
    let store = SubscriptionStore(fileURL: url)
    let subscription = makeSubscription()
    try await store.upsert(subscription)

    let reopened = SubscriptionStore(fileURL: url)
    try await reopened.load()
    #expect(await reopened.all() == [subscription])
    #expect(await reopened.subscription(forTypeIdentifier: subscription.typeIdentifier) == subscription)
}

@Test func upsertReplacesTheSameIdentity() async throws {
    let store = SubscriptionStore(fileURL: makeFileURL())
    var subscription = makeSubscription()
    try await store.upsert(subscription)
    subscription.isEnabled = false
    subscription.filter.threshold = .above(80)
    try await store.upsert(subscription)
    #expect(await store.all().count == 1)
    #expect(await store.all().first?.isEnabled == false)
    #expect(await store.all().first?.filter.threshold == .above(80))
}

@Test func removeDropsTheSubscription() async throws {
    let url = makeFileURL()
    let store = SubscriptionStore(fileURL: url)
    let subscription = makeSubscription()
    try await store.upsert(subscription)
    try await store.remove(id: subscription.id)
    #expect(await store.all().isEmpty)

    let reopened = SubscriptionStore(fileURL: url)
    try await reopened.load()
    #expect(await reopened.all().isEmpty)
    #expect(await reopened.subscription(forTypeIdentifier: subscription.typeIdentifier) == nil)
}

@Test func thresholdSurvivesEncoding() throws {
    var filter = SubscriptionFilter()
    filter.threshold = .outside(lower: 3.9, upper: 10.1)
    filter.minimumInterval = 600
    filter.allowedSourceNames = ["Dexcom"]
    let data = try JSONEncoder().encode(filter)
    #expect(try JSONDecoder().decode(SubscriptionFilter.self, from: data) == filter)
}
