import Foundation

/// Ein einzelner neuer Health-Eintrag, so wie Filter und Aktionen ihn sehen.
/// Bewusst flach und Codable: genau diese Form landet in der Warteschlange,
/// im Protokoll und in der JSONL-Ablage, und genau diese Felder fuellen die
/// Platzhalter einer Vorlage.
struct HealthSampleEvent: Codable, Sendable, Equatable {
    let sampleUUID: UUID
    let typeIdentifier: String
    let typeName: String
    let value: Double
    /// nil bei Kategorietypen -- die haben keine Einheit, sondern eine Beschriftung.
    let unit: String?
    /// nil bei Mengentypen -- die haben eine Einheit, aber keine Beschriftung.
    let valueLabel: String?
    let date: Date
    let sourceName: String
}
