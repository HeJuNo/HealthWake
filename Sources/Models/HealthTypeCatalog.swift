import Foundation

enum HealthTypeKind: String, Codable, Sendable {
    case quantity
    case category
}

/// Die Gliederung der Typauswahl. Die Reihenfolge der Faelle ist die
/// Reihenfolge auf dem Bildschirm.
enum HealthTypeGroup: String, CaseIterable, Sendable, Comparable {
    case body
    case vitals
    case activity
    case sleep
    case nutrition
    case respiratory
    case mobility
    case hearing
    case reproductive
    case other

    /// Sichtbarer Text, deshalb Englisch.
    var displayName: String {
        switch self {
        case .body: "Body Measurements"
        case .vitals: "Vitals"
        case .activity: "Activity"
        case .sleep: "Sleep"
        case .nutrition: "Nutrition"
        case .respiratory: "Respiratory"
        case .mobility: "Mobility"
        case .hearing: "Hearing"
        case .reproductive: "Reproductive Health"
        case .other: "Other Data"
        }
    }

    private var order: Int {
        Self.allCases.firstIndex(of: self) ?? Self.allCases.count
    }

    static func < (lhs: HealthTypeGroup, rhs: HealthTypeGroup) -> Bool {
        lhs.order < rhs.order
    }
}

/// Was HealthWake ueber einen Health-Typ weiss, ohne HealthKit zu fragen.
/// Noetig, weil die Typauswahl auch ohne Berechtigung vollstaendig sein muss:
/// gefragt wird erst, wenn der Benutzer einen Typ auswaehlt.
struct HealthTypeDescriptor: Sendable, Equatable, Identifiable {
    var id: String { identifier }
    let identifier: String
    let kind: HealthTypeKind
    /// Sichtbarer Text, deshalb Englisch.
    let displayName: String
    let group: HealthTypeGroup
    /// nil bei Kategorietypen.
    let defaultUnitString: String?
    /// nil bei Mengentypen.
    let categoryLabels: [Int: String]?
}

enum HealthTypeCatalog {
    static let all: [HealthTypeDescriptor] = table

    private static let index: [String: HealthTypeDescriptor] = Dictionary(
        all.map { ($0.identifier, $0) },
        uniquingKeysWith: { first, _ in first }
    )

    static func descriptor(for identifier: String) -> HealthTypeDescriptor? {
        index[identifier]
    }

    /// Sucht in Anzeigename und Bezeichner, ohne Ruecksicht auf Gross-
    /// schreibung und Diakritika. Leere Eingabe liefert den ganzen Katalog.
    static func search(_ query: String) -> [HealthTypeDescriptor] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        return all.filter { descriptor in
            descriptor.displayName.range(of: trimmed, options: options) != nil
                || descriptor.identifier.range(of: trimmed, options: options) != nil
        }
    }

    /// Gruppen in der Reihenfolge von HealthTypeGroup.allCases, Mitglieder
    /// nach Anzeigename. Leere Gruppen fallen weg.
    static func grouped() -> [(HealthTypeGroup, [HealthTypeDescriptor])] {
        HealthTypeGroup.allCases.compactMap { group in
            let members = all
                .filter { $0.group == group }
                .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            return members.isEmpty ? nil : (group, members)
        }
    }
}
