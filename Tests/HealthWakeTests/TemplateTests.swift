import Foundation
import Testing
@testable import HealthWake

private let fixedDate = Date(timeIntervalSince1970: 1_767_225_600)   // 2026-01-01T00:00:00Z

private func quantityEvent(source: String = "Health") -> HealthSampleEvent {
    HealthSampleEvent(
        sampleUUID: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
        typeIdentifier: "HKQuantityTypeIdentifierBodyMass",
        typeName: "Weight",
        value: 72.5,
        unit: "kg",
        valueLabel: nil,
        date: fixedDate,
        sourceName: source
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
        date: fixedDate,
        sourceName: "Apple Watch"
    )
}

private func decodeObject(_ text: String) -> [String: Any]? {
    guard let data = text.data(using: .utf8) else { return nil }
    return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
}

@Test func allPlaceholdersAreSubstituted() {
    let template = Template.placeholders.map { "{{\($0)}}" }.joined(separator: "|")
    let rendered = Template.render(template, event: quantityEvent(), context: .plain)
    #expect(!rendered.contains("{{"))
    #expect(rendered.contains("Weight"))
    #expect(rendered.contains("72.5"))
    #expect(rendered.contains("kg"))
    #expect(rendered.contains("Health"))
    #expect(rendered.contains("11111111-2222-3333-4444-555555555555"))
}

@Test func quotesAndNewlinesInSourceNameAreEscapedInJSON() {
    let event = quantityEvent(source: "She said \"hi\"\nthen left")
    let rendered = Template.render(#"{"source": "{{source}}"}"#, event: event, context: .json)
    let object = decodeObject(rendered)
    #expect(object?["source"] as? String == "She said \"hi\"\nthen left")
}

@Test func emojiSurvivesJSONEscaping() {
    let event = quantityEvent(source: "Waage 🩺 Küche")
    let rendered = Template.render(#"{"source": "{{source}}"}"#, event: event, context: .json)
    #expect(decodeObject(rendered)?["source"] as? String == "Waage 🩺 Küche")
}

@Test func valuesArePercentEncodedInURLContext() {
    let event = quantityEvent(source: "Waage & Küche")
    let rendered = Template.render("https://example.com/hook?src={{source}}", event: event, context: .url)
    #expect(rendered.contains("Waage%20%26%20K%C3%BCche"))
    #expect(URL(string: rendered) != nil)
}

@Test func categorySampleRendersNullUnitAndItsLabel() {
    let rendered = Template.render(
        #"{"unit": {{unit}}, "label": {{valueLabel}}}"#,
        event: categoryEvent(),
        context: .json
    )
    let object = decodeObject(rendered)
    #expect(object?["unit"] is NSNull)
    #expect(object?["label"] as? String == "REM Sleep")
}

@Test func unknownPlaceholderIsLeftVerbatim() {
    let rendered = Template.render("a {{nope}} b", event: quantityEvent(), context: .plain)
    #expect(rendered == "a {{nope}} b")
}

@Test func dateIsISO8601AndDateEpochIsSeconds() {
    let rendered = Template.render("{{date}}|{{dateEpoch}}", event: quantityEvent(), context: .plain)
    #expect(rendered == "2026-01-01T00:00:00Z|1767225600")
}

@Test func defaultJSONBodyIsValidJSONForBothKinds() {
    for event in [quantityEvent(source: "She said \"hi\""), categoryEvent()] {
        let rendered = Template.render(Template.defaultJSONBody(), event: event, context: .json)
        let object = decodeObject(rendered)
        #expect(object != nil)
        #expect(object?["type"] as? String == event.typeIdentifier)
        #expect(object?["value"] as? Double == event.value)
        #expect(object?["source"] as? String == event.sourceName)
    }
}

@Test func bareAndQuotedPlaceholdersBothYieldValidJSON() {
    let event = quantityEvent(source: "a\"b")
    let bare = Template.render(#"{"s": {{source}}}"#, event: event, context: .json)
    let quoted = Template.render(#"{"s": "{{source}}"}"#, event: event, context: .json)
    #expect(decodeObject(bare)?["s"] as? String == "a\"b")
    #expect(decodeObject(quoted)?["s"] as? String == "a\"b")
}
