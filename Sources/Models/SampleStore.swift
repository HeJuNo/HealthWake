import Foundation

/// Anhaengende Ablage der empfangenen Health-Werte: eine Datei je Typ und
/// Monat, eine Zeile je Ereignis (JSONL). Anhaengen statt ueberschreiben,
/// damit ein Absturz mitten im Schreiben hoechstens die letzte Zeile
/// beschaedigt -- alles davor bleibt lesbar.
///
/// Geschrieben wird vor dem Setzen des Ankers, und zwar mit fsync: der Anker
/// darf nur vorruecken, wenn die Werte wirklich auf der Platte liegen
/// (Spec 7.2, 14.2).
struct SampleStore: Sendable {
    private let directory: URL
    private static let fileExtension = "jsonl"

    init(directory: URL) {
        self.directory = directory
    }

    /// Dateiname nach Typ und Monat. Der Monat wird in UTC bestimmt, damit
    /// derselbe Wert unabhaengig von der Zeitzone des Geraets immer in
    /// derselben Datei landet.
    static func fileName(typeIdentifier: String, date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let parts = calendar.dateComponents([.year, .month], from: date)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        return String(format: "%@-%04d-%02d.%@", typeIdentifier, year, month, fileExtension)
    }

    func append(_ events: [HealthSampleEvent]) throws {
        guard !events.isEmpty else { return }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONCoding.readableEncoder()

        var batches: [String: Data] = [:]
        for event in events {
            let name = Self.fileName(typeIdentifier: event.typeIdentifier, date: event.date)
            var line = try encoder.encode(event)
            line.append(UInt8(ascii: "\n"))
            batches[name, default: Data()].append(line)
        }

        for (name, data) in batches {
            let url = directory.appendingPathComponent(name)
            if !FileManager.default.fileExists(atPath: url.path) {
                guard FileManager.default.createFile(
                    atPath: url.path,
                    contents: nil,
                    attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
                ) else {
                    throw CocoaError(.fileWriteUnknown)
                }
            }
            // forUpdating, nicht forWritingTo: das letzte Byte muss gelesen
            // werden, und aus einem reinen Schreibgriff laesst sich nicht lesen.
            let handle = try FileHandle(forUpdating: url)
            defer { try? handle.close() }
            try handle.seekToEnd()
            // Ein Abschuss kann die letzte Zeile halbiert haben. Ohne diesen
            // Zeilenumbruch verschmilzt der neue Wert mit dem kaputten Rest
            // und waere fuer immer unlesbar.
            let end = try handle.offset()
            if end > 0 {
                try handle.seek(toOffset: end - 1)
                let last = try handle.read(upToCount: 1)
                try handle.seek(toOffset: end)
                if last != Data([UInt8(ascii: "\n")]) {
                    try handle.write(contentsOf: Data([UInt8(ascii: "\n")]))
                }
            }
            try handle.write(contentsOf: data)
            // Pflicht, nicht Vorsicht: ohne fsync kann der Anker vor den
            // Werten auf der Platte stehen.
            try handle.synchronize()
        }
    }

    /// Alle gespeicherten Ereignisse eines Typs, aufsteigend nach Zeitpunkt.
    /// Zeilen, die sich nicht entschluesseln lassen -- etwa eine beim
    /// Absturz abgeschnittene letzte Zeile -- werden uebersprungen.
    func events(forTypeIdentifier identifier: String) throws -> [HealthSampleEvent] {
        let decoder = JSONCoding.readableDecoder()
        var result: [HealthSampleEvent] = []
        for url in try files().filter({ $0.lastPathComponent.hasPrefix(identifier + "-") }).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            guard let data = try? Data(contentsOf: url) else { continue }
            for line in data.split(separator: UInt8(ascii: "\n")) where !line.isEmpty {
                if let event = try? decoder.decode(HealthSampleEvent.self, from: Data(line)) {
                    result.append(event)
                }
            }
        }
        // Derselbe Wert kann zweimal in der Datei stehen: HealthKit stellt
        // gelegentlich doppelt zu, und ein Abschuss zwischen Werteschreiben
        // und Anker laesst denselben Wert beim naechsten Weckruf noch einmal
        // ankommen. Beim Lesen zaehlt er einmal.
        var seen = Set<UUID>()
        return result
            .filter { seen.insert($0.sampleUUID).inserted }
            .sorted { $0.date < $1.date }
    }

    func totalByteCount() throws -> Int64 {
        try files().reduce(into: Int64(0)) { total, url in
            let size = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
            total += size
        }
    }

    func removeAll() throws {
        for url in try files() {
            try FileManager.default.removeItem(at: url)
        }
    }

    private func files() throws -> [URL] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        return try FileManager.default
            .contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == Self.fileExtension }
    }
}
