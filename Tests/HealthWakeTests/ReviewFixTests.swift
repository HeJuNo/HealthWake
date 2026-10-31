import Foundation
import HealthKit
import Testing
@testable import HealthWake

private func makeDirectory() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("ReviewFixTests-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func event(source: String = "Health") -> HealthSampleEvent {
    HealthSampleEvent(
        sampleUUID: UUID(),
        typeIdentifier: "HKQuantityTypeIdentifierBodyMass",
        typeName: "Weight",
        value: 72.5,
        unit: "kg",
        valueLabel: nil,
        date: Date(timeIntervalSince1970: 1_767_225_600),
        sourceName: source
    )
}

// MARK: - I1: Platzhalter mitten in einer JSON-Zeichenkette

@Test func placeholdersInsideAJSONStringStayInsideIt() throws {
    let template = #"{"message": "{{typeName}}: {{value}} {{unit}}"}"#
    let rendered = Template.render(template, event: event(), context: .json)
    let object = try JSONSerialization.jsonObject(with: Data(rendered.utf8)) as? [String: Any]
    #expect(object?["message"] as? String == "Weight: 72.5 kg")
}

@Test func escapedQuotesInATemplateDoNotConfuseTheStringTracking() throws {
    let template = #"{"note": "a \" b {{source}}"}"#
    let rendered = Template.render(template, event: event(source: "x\"y"), context: .json)
    let object = try JSONSerialization.jsonObject(with: Data(rendered.utf8)) as? [String: Any]
    #expect(object?["note"] as? String == "a \" b x\"y")
}

@Test func aPlainTextBodyIsNotJSONEscaped() throws {
    var config = HTTPPostAction.defaultConfig
    config.headers = ["Content-Type": "text/plain"]
    config.bodyTemplate = "{{source}}"
    let (_, body) = try HTTPPostAction.buildRequest(
        event: event(source: "a\"b"),
        config: config,
        secret: nil
    )
    #expect(String(decoding: body, as: UTF8.self) == "a\"b")
}

// MARK: - I4: Jede Bindung ihr eigenes Geheimnis

@Test func twoBindingsWithTheSameHeaderDoNotShareASecret() {
    var first = HTTPPostAction.defaultConfig
    first.keychainHeaderName = "Authorization"
    first.secretID = "aaaa"
    var second = HTTPPostAction.defaultConfig
    second.keychainHeaderName = "Authorization"
    second.secretID = "bbbb"

    let firstAccount = HTTPPostAction.keychainAccount(for: first)
    let secondAccount = HTTPPostAction.keychainAccount(for: second)
    #expect(firstAccount != nil)
    #expect(firstAccount != secondAccount)
}

// MARK: - I5: Eine kaputte Datei darf keine Abonnements loeschen

@Test func aCorruptSubscriptionFileIsSetAsideInsteadOfOverwritten() async throws {
    let directory = makeDirectory()
    let url = directory.appendingPathComponent("subscriptions.json")
    try Data("kein JSON".utf8).write(to: url)

    let store = SubscriptionStore(fileURL: url)
    _ = await store.all()
    #expect(await store.corruptFileURL != nil)

    // Die kaputte Datei ist beiseitegelegt, nicht ueberschrieben.
    let aside = await store.corruptFileURL!
    #expect(FileManager.default.fileExists(atPath: aside.path))
    #expect(try String(contentsOf: aside, encoding: .utf8) == "kein JSON")
}

// MARK: - I2: Getrennte Schreibwege fuer Einstellung und Fortschritt

@Test func writingTheConfigurationKeepsTheAnchor() async throws {
    let store = SubscriptionStore(fileURL: makeDirectory().appendingPathComponent("s.json"))
    var subscription = Subscription(
        id: UUID(), typeIdentifier: "HKQuantityTypeIdentifierBodyMass", isEnabled: true,
        filter: SubscriptionFilter(), actions: [], anchorData: Data("neu".utf8),
        lastSampleAt: Date(timeIntervalSince1970: 100), lastTriggeredAt: nil,
        authorizationRequested: true
    )
    try await store.upsert(subscription)

    // Die Detailansicht haelt eine alte Kopie und schreibt sie zurueck.
    var stale = subscription
    stale.anchorData = Data("uralt".utf8)
    stale.lastSampleAt = nil
    stale.filter.threshold = .above(5)
    try await store.updateConfiguration(stale)

    let stored = await store.all().first
    #expect(stored?.filter.threshold == .above(5))
    #expect(stored?.anchorData == Data("neu".utf8))
    #expect(stored?.lastSampleAt == Date(timeIntervalSince1970: 100))

    // Und umgekehrt: der Fortschritt ueberschreibt keine Einstellung.
    subscription.filter.threshold = .below(1)
    try await store.updateProgress(
        id: subscription.id,
        anchorData: Data("neuer".utf8),
        lastSampleAt: Date(timeIntervalSince1970: 200),
        lastTriggeredAt: Date(timeIntervalSince1970: 200)
    )
    let after = await store.all().first
    #expect(after?.filter.threshold == .above(5))
    #expect(after?.anchorData == Data("neuer".utf8))
}

// MARK: - I6/I7/I9: Umgebung

private actor PickyStore: HealthStoring {
    private(set) var disableAllCalls = 0
    private(set) var enabledTypes: [String] = []
    var anchorFails = false
    var enableFailsFor: String?

    func setAnchorFails(_ value: Bool) { anchorFails = value }
    func setEnableFails(for identifier: String?) { enableFailsFor = identifier }

    func requestAuthorization(toRead identifiers: Set<String>) async throws {}
    func wouldPrompt(toRead identifiers: Set<String>) async throws -> Bool { true }
    func enableBackgroundDelivery(for identifier: String, frequency: HKUpdateFrequency) async throws {
        if identifier == enableFailsFor { throw HealthStoreError.notAvailable }
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
        if anchorFails { throw HealthStoreError.databaseInaccessible }
        return Data("jetzt".utf8)
    }
}

@MainActor
private func makeEnvironment() -> (AppEnvironment, PickyStore) {
    let store = PickyStore()
    let environment = AppEnvironment(
        store: store,
        directory: makeDirectory(),
        registry: [],
        defaults: UserDefaults(suiteName: "ReviewFix-\(UUID().uuidString)")!
    )
    return (environment, store)
}

@Test @MainActor func addingTheSameTypeTwiceIsRejected() async throws {
    let (environment, _) = makeEnvironment()
    _ = try await environment.addSubscription(typeIdentifier: "HKQuantityTypeIdentifierBodyMass")
    await #expect(throws: AppEnvironmentError.alreadyWatched) {
        _ = try await environment.addSubscription(typeIdentifier: "HKQuantityTypeIdentifierBodyMass")
    }
    #expect(await environment.subscriptions.all().count == 1)
}

@Test @MainActor func registeringTheSameTypesAgainDoesNotTurnDeliveryOff() async throws {
    let (environment, store) = makeEnvironment()
    _ = try await environment.addSubscription(typeIdentifier: "HKQuantityTypeIdentifierBodyMass")
    let callsAfterFirst = await store.disableAllCalls
    await environment.observer.registerAll(identifiers: ["HKQuantityTypeIdentifierBodyMass"])
    // Zweites Anmelden derselben Typen darf nicht alles abschalten.
    #expect(await store.disableAllCalls == callsAfterFirst)
    #expect(await store.enabledTypes.contains("HKQuantityTypeIdentifierBodyMass"))
}

@Test @MainActor func aTypeThatCannotBeEnabledIsLogged() async throws {
    let (environment, store) = makeEnvironment()
    await store.setEnableFails(for: "HKQuantityTypeIdentifierBodyMass")
    await environment.observer.registerAll(identifiers: ["HKQuantityTypeIdentifierBodyMass"])
    let entries = await environment.log.entries()
    #expect(entries.contains { $0.kind == .storeUnavailable && $0.typeIdentifier == "HKQuantityTypeIdentifierBodyMass" })
}

@Test @MainActor func switchingOnWithAnUnreadableAnchorDoesNotReplayThePause() async throws {
    let (environment, store) = makeEnvironment()
    _ = try await environment.addSubscription(typeIdentifier: "HKQuantityTypeIdentifierBodyMass")
    await environment.setGloballyEnabled(false)
    await store.setAnchorFails(true)
    await environment.setGloballyEnabled(true)

    // Der alte Anker bleibt stehen -- also darf der Typ nicht beobachtet
    // werden, sonst kaeme die ganze Pause auf einmal.
    let subscription = await environment.subscriptions.all().first
    #expect(subscription?.isEnabled == false)
    let entries = await environment.log.entries()
    #expect(entries.contains { $0.kind == .storeUnavailable })
}

// MARK: - I8: Diagnose

@Test @MainActor func diagnosisReportsWhetherHealthWouldStillAsk() async throws {
    let (environment, _) = makeEnvironment()
    _ = try await environment.addSubscription(typeIdentifier: "HKQuantityTypeIdentifierBodyMass")
    let rows = await DiagnosisModel(store: environment.healthStore, subscriptions: environment.subscriptions).rows()
    #expect(rows.count == 1)
    #expect(rows.first?.name == "Weight")
    #expect(rows.first?.wouldPrompt == true)
}
