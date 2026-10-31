import Foundation

/// Die Bedingungen, unter denen ein neuer Eintrag die Aktionen ausloest.
/// Alle drei Bedingungen gelten gleichzeitig.
struct SubscriptionFilter: Codable, Sendable, Equatable, Hashable {
    enum Threshold: Codable, Sendable, Equatable, Hashable {
        case none
        case above(Double)
        case below(Double)
        case outside(lower: Double, upper: Double)
    }

    var threshold: Threshold = .none
    /// Kuerzester Abstand zur letzten Ausloesung. nil heisst: kein Abstand.
    var minimumInterval: TimeInterval? = nil
    /// Leere Liste heisst: jede Quelle.
    var allowedSourceNames: [String] = []
}

/// Eine Aktion in ihrer Einstellung, wie sie an einem Abonnement haengt.
/// configData ist die kodierte Config der jeweiligen Aktion -- das Abonnement
/// muss deren Typ nicht kennen.
struct ActionBinding: Codable, Sendable, Identifiable, Equatable, Hashable {
    let id: UUID
    var actionTypeID: String
    var configData: Data
    var isEnabled: Bool
}

/// Ein beobachteter Health-Typ mit Filter, Aktionen und dem Anker, bis zu
/// dem die Werte verarbeitet sind.
struct Subscription: Codable, Sendable, Identifiable, Equatable, Hashable {
    let id: UUID
    var typeIdentifier: String
    var isEnabled: Bool
    var filter: SubscriptionFilter
    var actions: [ActionBinding]
    /// Der HKQueryAnchor, serialisiert. nil heisst: noch nie abgefragt.
    var anchorData: Data?
    var lastSampleAt: Date?
    var lastTriggeredAt: Date?
    /// Ob fuer diesen Typ schon einmal nach Erlaubnis gefragt wurde. HealthKit
    /// verraet nicht, ob der Benutzer Lesen erlaubt hat, nur ob noch gefragt
    /// werden muss -- deshalb hier gemerkt.
    var authorizationRequested: Bool
    /// Wann das Abonnement angelegt wurde. Noetig fuer den Zustand
    /// "wartet auf den ersten Eintrag seit ..." -- vorher gibt es keinen
    /// anderen Zeitpunkt, auf den sich die Oberflaeche beziehen koennte.
    var createdAt: Date = Date()
}
