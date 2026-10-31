import Foundation

/// Eine Zeile der Protokollliste, schon fertig auseinandergenommen. Die
/// Ansicht soll keine Zeichenketten mehr zerlegen muessen.
struct LogRow: Identifiable, Equatable, Sendable {
    enum Content: Equatable, Sendable {
        /// Ein Wert aus Health: Name, App, Wert -- drei Angaben, drei
        /// Plaetze in der Zeile.
        case measurement(typeName: String, sourceName: String, value: String)
        /// Alles andere: Aktionen, Fehler, der globale Schalter.
        case message(String)
    }

    let id: UUID
    let date: Date
    let kind: LogEntry.Kind
    let content: Content

    var isError: Bool { kind == .actionFailed || kind == .storeUnavailable }
}

/// Ein Tag im Protokoll mit seinen Zeilen.
struct LogDay: Identifiable, Equatable, Sendable {
    /// Der Tagesanfang -- zugleich die Sortierung.
    let id: Date
    let title: String
    let rows: [LogRow]
}

/// Macht aus den Protokolleintraegen Tagesabschnitte. Eigenes Modell, weil
/// die Gruppierung ueber Zeitzonengrenzen hinweg pruefbar sein muss.
enum LogListModel {
    static func days(for entries: [LogEntry], calendar: Calendar = .current) -> [LogDay] {
        // Die Eingabe ist schon neueste-zuerst sortiert, und innerhalb eines
        // Tages bleibt sie es auch: nur gruppieren, nicht umsortieren.
        var order: [Date] = []
        var rowsByDay: [Date: [LogRow]] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.date)
            if rowsByDay[day] == nil {
                order.append(day)
                rowsByDay[day] = []
            }
            rowsByDay[day]?.append(row(for: entry))
        }
        return order
            .sorted(by: >)
            .map { LogDay(id: $0, title: title(for: $0, calendar: calendar), rows: rowsByDay[$0] ?? []) }
    }

    private static func row(for entry: LogEntry) -> LogRow {
        let content: LogRow.Content
        if let typeName = entry.typeName, let value = entry.valueText {
            content = .measurement(
                typeName: typeName,
                // Die Quelle fehlt bei Werten, die keine App geschrieben hat.
                sourceName: entry.sourceName ?? "Unknown app",
                value: value
            )
        } else {
            content = .message(entry.message)
        }
        return LogRow(id: entry.id, date: entry.date, kind: entry.kind, content: content)
    }

    /// "Today", "Yesterday" oder das Datum -- was iOS in der Sprache des
    /// Geraets dafuer vorsieht.
    private static func title(for day: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = .current
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = true
        return formatter.string(from: day)
    }
}
