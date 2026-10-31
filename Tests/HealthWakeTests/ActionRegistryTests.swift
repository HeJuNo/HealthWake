import Foundation
import Testing
@testable import HealthWake

private actor Recorder {
    var greetings: [String] = []
    func record(_ greeting: String) { greetings.append(greeting) }
}

private struct FakeAction: HealthAction {
    struct Config: Codable, Sendable, Equatable {
        var greeting: String
    }

    static let typeID = "fake"
    static let displayName = "Fake"
    static let defaultConfig = Config(greeting: "hello")

    let recorder: Recorder

    func perform(event: HealthSampleEvent, config: Config) async throws {
        await recorder.record(config.greeting)
    }
}

private func sampleEvent() -> HealthSampleEvent {
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

@Test func erasedActionRoundTripsItsConfig() async throws {
    let recorder = Recorder()
    let erased = AnyHealthAction(FakeAction(recorder: recorder))
    #expect(erased.id == "fake")

    let data = try JSONEncoder().encode(FakeAction.Config(greeting: "moin"))
    try await erased.perform(sampleEvent(), data)
    #expect(await recorder.greetings == ["moin"])
}

@Test func defaultConfigDataDecodesToTheDefaultConfig() throws {
    let erased = AnyHealthAction(FakeAction(recorder: Recorder()))
    let data = try erased.defaultConfigData()
    #expect(try JSONDecoder().decode(FakeAction.Config.self, from: data) == FakeAction.defaultConfig)
}

@Test func unknownTypeIDHasNoAction() {
    #expect(ActionRegistry.action(for: "nope") == nil)
    #expect(ActionRegistry.action(for: NotificationAction.typeID) != nil)
    #expect(ActionRegistry.action(for: HTTPPostAction.typeID) != nil)
}

@Test func registryIdentifiersAreUnique() {
    let ids = ActionRegistry.all.map(\.typeID)
    #expect(Set(ids).count == ids.count)
    #expect(ActionRegistry.all.allSatisfy { !$0.displayName.isEmpty })
}

@Test func notificationDefaultConfigRendersNonEmptyTitleAndBody() {
    let config = NotificationAction.defaultConfig
    let event = sampleEvent()
    let title = Template.render(config.titleTemplate, event: event, context: .plain)
    let body = Template.render(config.bodyTemplate, event: event, context: .plain)
    #expect(!title.trimmingCharacters(in: .whitespaces).isEmpty)
    #expect(!body.trimmingCharacters(in: .whitespaces).isEmpty)
    #expect(!title.contains("{{"))
    #expect(!body.contains("{{"))
    #expect(body.contains("72.5"))
}
