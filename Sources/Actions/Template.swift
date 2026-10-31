import Foundation

/// Wohin der ersetzte Text geht -- davon haengt die Maskierung ab. Dieselbe
/// Quelle ("She said \"hi\"") muss in JSON anders aussehen als in einer URL.
enum TemplateContext: Sendable {
    case json
    case url
    case plain
}

/// Platzhalterersetzung fuer die Vorlagen der Aktionen.
///
/// Im JSON-Zusammenhang gibt es zwei Schreibweisen, und beide ergeben
/// gueltiges JSON:
///
///   "source": "{{source}}"   -- der Platzhalter steht in Anfuehrungszeichen,
///                               ersetzt wird nur der maskierte Inhalt.
///   "source": {{source}}     -- der Platzhalter steht fuer sich, ersetzt
///                               wird ein vollstaendiger JSON-Wert, also mit
///                               Anfuehrungszeichen, als Zahl, oder null.
///
/// Die zweite Form ist die einzige, mit der eine fehlende Einheit zu einem
/// echten null wird statt zur Zeichenkette "null".
enum Template {
    static let placeholders = [
        "type", "typeName", "value", "valueLabel", "unit", "date", "dateEpoch", "source", "uuid",
    ]

    static func render(_ template: String, event: HealthSampleEvent, context: TemplateContext) -> String {
        var result = ""
        // Im JSON-Zusammenhang zaehlt, ob der Platzhalter innerhalb einer
        // Zeichenkette steht -- und zwar an beliebiger Stelle, nicht nur
        // direkt zwischen zwei Anfuehrungszeichen. "{{a}}: {{b}}" ist eine
        // Zeichenkette mit zwei Platzhaltern darin.
        var insideString = false
        var escaped = false
        var index = template.startIndex

        while index < template.endIndex {
            if template[index...].hasPrefix("{{"),
               let close = template.range(of: "}}", range: index..<template.endIndex) {
                let nameStart = template.index(index, offsetBy: 2)
                let raw = String(template[nameStart..<close.lowerBound])
                let name = raw.trimmingCharacters(in: .whitespaces)
                if let value = value(named: name, of: event) {
                    result += render(value, context: context, insideQuotes: context == .json && insideString)
                } else {
                    // Unbekannter Platzhalter bleibt unangetastet stehen --
                    // eine stille Leerstelle waere schlimmer als ein
                    // sichtbarer Fehler.
                    result += "{{" + raw + "}}"
                }
                index = close.upperBound
                continue
            }

            let character = template[index]
            if context == .json {
                if escaped {
                    escaped = false
                } else if character == "\\", insideString {
                    escaped = true
                } else if character == "\"" {
                    insideString.toggle()
                }
            }
            result.append(character)
            index = template.index(after: index)
        }
        return result
    }

    static func defaultJSONBody() -> String {
        """
        {
          "type": {{type}},
          "typeName": {{typeName}},
          "value": {{value}},
          "unit": {{unit}},
          "valueLabel": {{valueLabel}},
          "date": {{date}},
          "dateEpoch": {{dateEpoch}},
          "source": {{source}},
          "uuid": {{uuid}}
        }
        """
    }

    // MARK: - Innenleben

    /// Ein Platzhalterwert, noch unmaskiert.
    private enum Value {
        case text(String)
        case number(String)
        case missing
    }

    private static func value(named name: String, of event: HealthSampleEvent) -> Value? {
        switch name {
        case "type": .text(event.typeIdentifier)
        case "typeName": .text(event.typeName)
        case "value": .number(numberText(event.value))
        case "valueLabel": event.valueLabel.map(Value.text) ?? .missing
        case "unit": event.unit.map(Value.text) ?? .missing
        case "date": .text(isoFormatter.string(from: event.date))
        case "dateEpoch": .number(String(Int64(event.date.timeIntervalSince1970.rounded())))
        case "source": .text(event.sourceName)
        case "uuid": .text(event.sampleUUID.uuidString)
        default: nil
        }
    }

    private static func render(_ value: Value, context: TemplateContext, insideQuotes: Bool) -> String {
        switch context {
        case .plain:
            switch value {
            case .text(let text): return text
            case .number(let text): return text
            case .missing: return ""
            }
        case .url:
            switch value {
            case .text(let text): return percentEncoded(text)
            case .number(let text): return text
            case .missing: return ""
            }
        case .json:
            switch value {
            case .text(let text):
                let escaped = jsonEscaped(text)
                return insideQuotes ? escaped : "\"\(escaped)\""
            case .number(let text):
                return text
            case .missing:
                return insideQuotes ? "" : "null"
            }
        }
    }

    /// Maskiert genau so, wie JSON es verlangt, inklusive Steuerzeichen --
    /// deshalb ueber JSONEncoder und nicht von Hand.
    private static func jsonEscaped(_ text: String) -> String {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(text),
              let quoted = String(data: data, encoding: .utf8),
              quoted.count >= 2
        else { return "" }
        return String(quoted.dropFirst().dropLast())
    }

    private static func percentEncoded(_ text: String) -> String {
        // urlQueryAllowed laesst & und = durch, die einen Abfrageteil zerlegen
        // wuerden -- also beide ausnehmen.
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+?#")
        return text.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
    }

    private static func numberText(_ value: Double) -> String {
        guard value.isFinite else { return "0" }
        if value == value.rounded(), abs(value) < 1e15 {
            return String(Int64(value))
        }
        var text = String(format: "%.6f", value)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
