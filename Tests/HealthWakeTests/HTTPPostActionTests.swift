import Foundation
import Testing
@testable import HealthWake

private let fixedUUID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!

private func event(source: String = "Health") -> HealthSampleEvent {
    HealthSampleEvent(
        sampleUUID: fixedUUID,
        typeIdentifier: "HKQuantityTypeIdentifierBodyMass",
        typeName: "Weight",
        value: 72.5,
        unit: "kg",
        valueLabel: nil,
        date: Date(timeIntervalSince1970: 1_767_225_600),
        sourceName: source
    )
}

private func config(
    url: String = "https://example.com/hook",
    method: String = "POST",
    headers: [String: String] = [:],
    body: String = Template.defaultJSONBody(),
    keychainHeaderName: String? = nil
) -> HTTPPostAction.Config {
    HTTPPostAction.Config(
        urlTemplate: url,
        method: method,
        headers: headers,
        bodyTemplate: body,
        keychainHeaderName: keychainHeaderName
    )
}

@Test func urlTemplateIsRenderedAndPercentEncoded() throws {
    let (request, _) = try HTTPPostAction.buildRequest(
        event: event(source: "Waage & Küche"),
        config: config(url: "https://example.com/hook?src={{source}}&type={{type}}"),
        secret: nil
    )
    #expect(request.url?.absoluteString == "https://example.com/hook?src=Waage%20%26%20K%C3%BCche&type=HKQuantityTypeIdentifierBodyMass")
    #expect(request.httpMethod == "POST")
}

@Test func headerValuesAreRendered() throws {
    let (request, _) = try HTTPPostAction.buildRequest(
        event: event(),
        config: config(headers: ["X-Health-Type": "{{typeName}}"]),
        secret: nil
    )
    #expect(request.value(forHTTPHeaderField: "X-Health-Type") == "Weight")
}

@Test func idempotencyKeyIsTheSampleUUID() throws {
    let (request, _) = try HTTPPostAction.buildRequest(event: event(), config: config(), secret: nil)
    #expect(request.value(forHTTPHeaderField: "Idempotency-Key") == fixedUUID.uuidString)
}

@Test func defaultBodyIsJSONAndContentTypeSaysSo() throws {
    let (request, body) = try HTTPPostAction.buildRequest(event: event(), config: config(), secret: nil)
    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    let object = try JSONSerialization.jsonObject(with: body) as? [String: Any]
    #expect(object?["typeName"] as? String == "Weight")
    #expect(object?["value"] as? Double == 72.5)
}

@Test func ownContentTypeIsNotOverwritten() throws {
    let (request, _) = try HTTPPostAction.buildRequest(
        event: event(),
        config: config(headers: ["Content-Type": "text/plain"], body: "{{value}}"),
        secret: nil
    )
    #expect(request.value(forHTTPHeaderField: "Content-Type") == "text/plain")
}

@Test func keychainHeaderIsInjectedOnlyWithASecret() throws {
    let withSecret = try HTTPPostAction.buildRequest(
        event: event(),
        config: config(keychainHeaderName: "Authorization"),
        secret: "Bearer s3cret"
    ).0
    #expect(withSecret.value(forHTTPHeaderField: "Authorization") == "Bearer s3cret")

    let withoutSecret = try HTTPPostAction.buildRequest(
        event: event(),
        config: config(keychainHeaderName: "Authorization"),
        secret: nil
    ).0
    #expect(withoutSecret.value(forHTTPHeaderField: "Authorization") == nil)
}

@Test func secretNeverAppearsInTheEncodedConfig() throws {
    let encoded = try JSONEncoder().encode(config(keychainHeaderName: "Authorization"))
    let text = String(decoding: encoded, as: UTF8.self)
    #expect(text.contains("Authorization"))
    #expect(!text.contains("s3cret"))
    // Und der entschluesselte Wert ist wieder derselbe Platzhalterverweis.
    let decoded = try JSONDecoder().decode(HTTPPostAction.Config.self, from: encoded)
    #expect(decoded.keychainHeaderName == "Authorization")
}

@Test func invalidRenderedURLThrows() {
    #expect(throws: HTTPActionError.invalidURL("not a url")) {
        _ = try HTTPPostAction.buildRequest(event: event(), config: config(url: "not a url"), secret: nil)
    }
    #expect(throws: (any Error).self) {
        _ = try HTTPPostAction.buildRequest(event: event(), config: config(url: "ftp://example.com"), secret: nil)
    }
}

@Test func controlCharactersInHeaderValuesAreStripped() throws {
    // Ein Quellname mit Zeilenumbruch darf keinen zweiten Kopfzeileneintrag
    // einschmuggeln koennen.
    let (request, _) = try HTTPPostAction.buildRequest(
        event: event(source: "a\r\nX-Injected: yes"),
        config: config(headers: ["X-Source": "{{source}}"]),
        secret: nil
    )
    #expect(request.value(forHTTPHeaderField: "X-Injected") == nil)
    #expect(request.value(forHTTPHeaderField: "X-Source")?.contains("\n") == false)
}
