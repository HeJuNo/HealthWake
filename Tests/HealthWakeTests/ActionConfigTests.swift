import Foundation
import Testing
@testable import HealthWake

private func quantityEvent() -> HealthSampleEvent {
    HealthSampleEvent(
        sampleUUID: UUID(),
        typeIdentifier: "HKQuantityTypeIdentifierBodyMass",
        typeName: "Weight",
        value: 72.5,
        unit: "kg",
        valueLabel: nil,
        date: Date(timeIntervalSince1970: 1_767_225_600),
        sourceName: "She said \"hi\""
    )
}

private func categoryEvent() -> HealthSampleEvent {
    HealthSampleEvent(
        sampleUUID: UUID(),
        typeIdentifier: "HKCategoryTypeIdentifierSleepAnalysis",
        typeName: "Sleep",
        value: 5,
        unit: nil,
        valueLabel: "REM Sleep",
        date: Date(timeIntervalSince1970: 1_767_225_600),
        sourceName: "Apple Watch 🩺"
    )
}

@Test func httpBodyPreviewIsValidJSONForBothKinds() throws {
    let model = HTTPConfigModel(config: HTTPPostAction.defaultConfig)
    for event in [quantityEvent(), categoryEvent()] {
        let preview = model.bodyPreview(for: event)
        let object = try JSONSerialization.jsonObject(with: Data(preview.utf8)) as? [String: Any]
        #expect(object?["typeName"] as? String == event.typeName)
        #expect(object?["source"] as? String == event.sourceName)
    }
}

@Test func previewUsesTheExampleEventWhenNoneIsGiven() {
    let model = HTTPConfigModel(config: HTTPPostAction.defaultConfig)
    let preview = model.bodyPreview()
    #expect(!preview.contains("{{"))
    #expect(preview.contains("\"value\""))
}

@Test func urlPreviewShowsTheRenderedAddress() {
    var config = HTTPPostAction.defaultConfig
    config.urlTemplate = "https://example.com/{{type}}"
    let model = HTTPConfigModel(config: config)
    #expect(model.urlPreview().hasPrefix("https://example.com/HKQuantityTypeIdentifier"))
}

@Test func anInvalidURLIsReportedBeforeSending() {
    var config = HTTPPostAction.defaultConfig
    config.urlTemplate = "nonsense"
    let model = HTTPConfigModel(config: config)
    #expect(model.validationMessage() != nil)
    config.urlTemplate = "https://example.com/hook"
    #expect(HTTPConfigModel(config: config).validationMessage() == nil)
}

@Test func notificationPreviewRendersTitleAndBody() {
    let model = NotificationConfigModel(config: NotificationAction.defaultConfig)
    let preview = model.preview(for: quantityEvent())
    #expect(preview.title == "Weight")
    #expect(preview.body.contains("72.5"))
    #expect(!preview.body.contains("{{"))
}
