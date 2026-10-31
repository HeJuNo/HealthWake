import Foundation

enum HTTPActionError: Error, Equatable {
    case invalidURL(String)
    case unsupportedScheme(String)
    case status(Int)
}

/// Schickt den Eintrag an eine HTTP-Adresse. URL, Kopfzeilen und Rumpf sind
/// Vorlagen; das Geheimnis einer Kopfzeile liegt im Schluesselbund und nie
/// in der gespeicherten Einstellung.
struct HTTPPostAction: HealthAction {
    struct Config: Codable, Sendable, Equatable {
        var urlTemplate: String
        var method: String
        /// Werte sind ebenfalls Vorlagen.
        var headers: [String: String]
        var bodyTemplate: String
        /// Name der Kopfzeile, deren Wert im Schluesselbund steht, etwa
        /// "Authorization". Der Wert selbst steht hier nicht.
        var keychainHeaderName: String?
    }

    static let typeID = "httpPost"
    static let displayName = "HTTP Request"
    static let defaultConfig = Config(
        urlTemplate: "https://",
        method: "POST",
        headers: [:],
        bodyTemplate: Template.defaultJSONBody(),
        keychainHeaderName: nil
    )

    /// Pruefbare Naht: alles, was an der Anfrage schiefgehen kann, entsteht
    /// hier und nicht im Netz.
    static func buildRequest(
        event: HealthSampleEvent,
        config: Config,
        secret: String?
    ) throws -> (URLRequest, Data) {
        let renderedURL = Template.render(config.urlTemplate, event: event, context: .url)
        guard let url = URL(string: renderedURL), let scheme = url.scheme?.lowercased() else {
            throw HTTPActionError.invalidURL(renderedURL)
        }
        guard scheme == "https" || scheme == "http" else {
            throw HTTPActionError.unsupportedScheme(scheme)
        }

        var request = URLRequest(url: url)
        let method = config.method.trimmingCharacters(in: .whitespaces).uppercased()
        request.httpMethod = method.isEmpty ? "POST" : method

        for (name, valueTemplate) in config.headers {
            let value = Template.render(valueTemplate, event: event, context: .plain)
            request.setValue(sanitizedHeaderValue(value), forHTTPHeaderField: name)
        }
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        // Bleibt ueber alle Wiederholungen gleich, damit der Empfaenger eine
        // doppelte Zustellung selbst erkennen kann (Spec 7.4).
        request.setValue(event.sampleUUID.uuidString, forHTTPHeaderField: "Idempotency-Key")

        if let headerName = config.keychainHeaderName, let secret, !secret.isEmpty {
            request.setValue(sanitizedHeaderValue(secret), forHTTPHeaderField: headerName)
        }

        let body = Data(Template.render(config.bodyTemplate, event: event, context: .json).utf8)
        return (request, body)
    }

    /// Schluesselbundkonto fuer das Geheimnis einer Kopfzeile.
    static func keychainAccount(for config: Config) -> String? {
        config.keychainHeaderName.map { "httpPost.\($0)" }
    }

    func perform(event: HealthSampleEvent, config: Config) async throws {
        let secret = HTTPPostAction.keychainAccount(for: config).flatMap(KeychainStore.get)
        let (request, body) = try HTTPPostAction.buildRequest(event: event, config: config, secret: secret)
        try await BackgroundUploader.shared.send(request, body: body, jobID: event.sampleUUID)
    }

    /// Ein Zeilenumbruch in einem Kopfzeilenwert koennte eine zweite
    /// Kopfzeile einschmuggeln. Steuerzeichen fallen deshalb weg.
    private static func sanitizedHeaderValue(_ value: String) -> String {
        value.unicodeScalars
            .filter { !CharacterSet.controlCharacters.contains($0) }
            .map(String.init)
            .joined()
            .trimmingCharacters(in: .whitespaces)
    }
}
