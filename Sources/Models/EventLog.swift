import Foundation

/// Eine Zeile im Protokoll. Das Protokoll ist die einzige Stelle, an der
/// der Benutzer nachsehen kann, warum etwas passiert ist -- oder warum
/// nichts passiert ist.
struct LogEntry: Codable, Sendable, Identifiable, Equatable {
    enum Kind: String, Codable, Sendable {
        case sampleReceived
        case actionSucceeded
        case actionFailed
        case sampleDeleted
        case deliveryDisabled
        case deliveryEnabled
        case storeUnavailable
    }

    let id: UUID
    let date: Date
    let kind: Kind
    let message: String
    let typeIdentifier: String?
    let actionTypeID: String?

    // Dieselbe Angabe wie in `message`, nur auseinandergenommen, damit die
    // Liste Name, App und Wert getrennt setzen kann. Nur Werteintraege
    // fuellen sie; alles andere zeigt weiterhin `message`. Optional auch
    // deshalb, weil Protokolle von vorher sie nicht haben.
    let typeName: String?
    let sourceName: String?
    let valueText: String?

    init(
        id: UUID,
        date: Date,
        kind: Kind,
        message: String,
        typeIdentifier: String?,
        actionTypeID: String?,
        typeName: String? = nil,
        sourceName: String? = nil,
        valueText: String? = nil
    ) {
        self.id = id
        self.date = date
        self.kind = kind
        self.message = message
        self.typeIdentifier = typeIdentifier
        self.actionTypeID = actionTypeID
        self.typeName = typeName
        self.sourceName = sourceName
        self.valueText = valueText
    }

    var isError: Bool { kind == .actionFailed || kind == .storeUnavailable }
}

/// Gedeckeltes Protokoll, neueste Zeile zuerst. Die ganze Liste wird bei
/// jedem Eintrag neu geschrieben: der Deckel erzwingt ohnehin ein Umschreiben,
/// und bei 500 Zeilen ist das billiger als eine Verwaltung von Luecken.
/// Eine unlesbare Datei zaehlt als leeres Protokoll -- ein Protokoll darf
/// nie der Grund sein, dass eine Aktion ausfaellt.
actor EventLog {
    private let fileURL: URL
    private let limit: Int
    private var loaded: [LogEntry]?

    init(fileURL: URL, limit: Int = 500) {
        self.fileURL = fileURL
        self.limit = limit
    }

    func append(_ entry: LogEntry) async throws {
        var all = load()
        all.insert(entry, at: 0)
        if all.count > limit {
            all.removeSubrange(limit...)
        }
        loaded = all
        try write(all)
    }

    func entries() async -> [LogEntry] {
        load()
    }

    func exportText() async -> String {
        let formatter = ISO8601DateFormatter()
        return load().map { entry in
            let type = entry.typeIdentifier.map { " [\($0)]" } ?? ""
            let action = entry.actionTypeID.map { " [\($0)]" } ?? ""
            return "\(formatter.string(from: entry.date))  \(entry.kind.rawValue)\(type)\(action)  \(entry.message)"
        }.joined(separator: "\n")
    }

    func removeAll() async throws {
        loaded = []
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }

    private func load() -> [LogEntry] {
        if let loaded { return loaded }
        let decoder = JSONCoding.readableDecoder()
        guard let data = try? Data(contentsOf: fileURL),
              let entries = try? decoder.decode([LogEntry].self, from: data)
        else {
            loaded = []
            return []
        }
        loaded = entries
        return entries
    }

    private func write(_ entries: [LogEntry]) throws {
        let encoder = JSONCoding.readableEncoder()
        let data = try encoder.encode(entries)
        try data.write(to: fileURL, options: .atomic)
        // Nach dem atomaren Schreiben, weil dabei eine neue Datei entsteht.
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: fileURL.path
        )
    }
}
