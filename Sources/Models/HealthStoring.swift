import Foundation
import HealthKit

enum HealthStoreError: Error, Equatable {
    /// Das Geraet ist gesperrt und noch nie entsperrt worden -- HealthKit
    /// ist dann nicht lesbar. Kein Fehler, sondern "spaeter nochmal".
    case databaseInaccessible
    case notAvailable
    case unknownType(String)
}

struct NewSamples: Sendable, Equatable {
    let events: [HealthSampleEvent]
    let deletedUUIDs: [UUID]
    /// Der Anker nach dieser Abfrage, serialisiert.
    let newAnchor: Data
}

/// Die Naht zwischen HealthWake und HealthKit. Alles, was HealthKit kann und
/// die App braucht, steht hier -- damit die Verarbeitungskette ohne Geraet
/// und ohne Erlaubnis pruefbar bleibt.
protocol HealthStoring: Sendable {
    func requestAuthorization(toRead identifiers: Set<String>) async throws
    /// Ob iOS noch einen Dialog zeigen wuerde. Sagt nichts darueber, ob der
    /// Benutzer Lesen erlaubt hat -- das verraet HealthKit grundsaetzlich nicht.
    func wouldPrompt(toRead identifiers: Set<String>) async throws -> Bool
    func enableBackgroundDelivery(for identifier: String, frequency: HKUpdateFrequency) async throws
    func disableAllBackgroundDelivery() async throws
    func newSamples(for identifier: String, anchor: Data?) async throws -> NewSamples
    func preferredUnitString(for identifier: String) async -> String?
    /// Liefert den Anker fuer "ab jetzt", ohne Samples zu verarbeiten.
    /// Noetig, weil HKAnchoredObjectQuery mit nil-Anker die GESAMTE
    /// Historie liefert -- bei Erstaktivierung also Jahre an Werten
    /// durch jede konfigurierte Aktion jagen wuerde.
    func currentAnchor(for identifier: String) async throws -> Data
}
