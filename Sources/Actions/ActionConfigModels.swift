import Foundation

/// Beispielwert fuer die Vorschau in den Einstellungsflaechen. Mit einem
/// Anfuehrungszeichen im Quellnamen, damit man der Vorschau ansieht, dass
/// maskiert wird.
enum ActionPreview {
    static let exampleEvent = HealthSampleEvent(
        sampleUUID: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!,
        typeIdentifier: "HKQuantityTypeIdentifierBodyMass",
        typeName: "Weight",
        value: 72.5,
        unit: "kg",
        valueLabel: nil,
        date: Date(timeIntervalSince1970: 1_767_225_600),
        sourceName: "Health"
    )
}

/// Vorschau und Pruefung fuer die HTTP-Aktion, getrennt von der Ansicht --
/// damit beides pruefbar ist, ohne eine Ansicht zu bauen.
struct HTTPConfigModel {
    var config: HTTPPostAction.Config

    func bodyPreview(for event: HealthSampleEvent = ActionPreview.exampleEvent) -> String {
        Template.render(config.bodyTemplate, event: event, context: .json)
    }

    func urlPreview(for event: HealthSampleEvent = ActionPreview.exampleEvent) -> String {
        Template.render(config.urlTemplate, event: event, context: .url)
    }

    /// nil heisst: so kann es losgehen. Sonst der Satz, der in der Ansicht steht.
    func validationMessage(for event: HealthSampleEvent = ActionPreview.exampleEvent) -> String? {
        do {
            _ = try HTTPPostAction.buildRequest(event: event, config: config, secret: nil)
            return nil
        } catch HTTPActionError.invalidURL(let text) {
            return "That is not a valid address: \(text)"
        } catch HTTPActionError.unsupportedScheme(let scheme) {
            return "Only http and https work here, not \(scheme)."
        } catch {
            return String(describing: error)
        }
    }

    /// Einmal senden, mit Antwort. Bewusst eine gewoehnliche URLSession:
    /// hier schaut jemand zu und will das Ergebnis sehen -- anders als im
    /// Hintergrund, wo die Warteschlange es spaeter noch einmal versucht.
    func sendTest(secret: String?) async -> String {
        do {
            let (request, body) = try HTTPPostAction.buildRequest(
                event: ActionPreview.exampleEvent,
                config: config,
                secret: secret
            )
            var testRequest = request
            testRequest.httpBody = body
            testRequest.timeoutInterval = 20
            let (data, response) = try await URLSession.shared.data(for: testRequest)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let text = String(decoding: data.prefix(500), as: UTF8.self)
            return text.isEmpty ? "HTTP \(status)" : "HTTP \(status)\n\(text)"
        } catch {
            return "Failed: \(error)"
        }
    }
}

/// Vorschau fuer die Mitteilungsaktion.
struct NotificationConfigModel {
    var config: NotificationAction.Config

    func preview(for event: HealthSampleEvent = ActionPreview.exampleEvent) -> (title: String, body: String) {
        (
            Template.render(config.titleTemplate, event: event, context: .plain),
            Template.render(config.bodyTemplate, event: event, context: .plain)
        )
    }
}
