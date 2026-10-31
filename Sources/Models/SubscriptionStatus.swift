import Foundation

/// Was die Liste ueber ein Abonnement sagen kann -- und was nicht.
///
/// HealthKit verraet grundsaetzlich nicht, ob der Benutzer Lesen erlaubt hat
/// (Spec 5.7). Kein Zustand darf das also behaupten. "Wartet auf den ersten
/// Eintrag" ist die ehrliche Auskunft, wenn nichts kommt: es kann an der
/// Erlaubnis liegen, oder einfach daran, dass es keinen neuen Wert gibt.
enum SubscriptionStatus: Sendable, Equatable {
    case notAskedYet
    case waitingForFirstSample(since: Date)
    case receiving(lastAt: Date)
    /// Seit mehr als sieben Tagen nichts -- Zeit, auf die Health-App zu
    /// verweisen, damit der Benutzer die Erlaubnis selbst nachsehen kann.
    case stale(lastAt: Date?)

    /// Sieben Tage Schweigen. Danach ist die wahrscheinlichste Erklaerung
    /// nicht mehr "kein neuer Wert", sondern "keine Erlaubnis".
    static let staleAfter: TimeInterval = 7 * 24 * 60 * 60

    static func of(_ subscription: Subscription, now: Date) -> SubscriptionStatus {
        guard subscription.authorizationRequested else { return .notAskedYet }
        if let last = subscription.lastSampleAt {
            return now.timeIntervalSince(last) > staleAfter ? .stale(lastAt: last) : .receiving(lastAt: last)
        }
        if now.timeIntervalSince(subscription.createdAt) > staleAfter { return .stale(lastAt: nil) }
        return .waitingForFirstSample(since: subscription.createdAt)
    }

    /// Sichtbarer Text, deshalb Englisch.
    var label: String {
        switch self {
        case .notAskedYet:
            "Not set up yet"
        case .waitingForFirstSample(let since):
            "Waiting for the first entry since \(Self.relative(since))"
        case .receiving(let lastAt):
            "Last entry \(Self.relative(lastAt))"
        case .stale(let lastAt):
            if let lastAt {
                "Nothing since \(Self.relative(lastAt)) -- check Health"
            } else {
                "Nothing yet -- check Health"
            }
        }
    }

    var isAttention: Bool {
        switch self {
        case .stale, .notAskedYet: true
        case .receiving, .waitingForFirstSample: false
        }
    }

    private static func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
