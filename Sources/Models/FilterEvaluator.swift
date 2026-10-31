import Foundation

enum FilterEvaluator {
    /// Prueft Schwelle, Mindestabstand und Quelle. Die Schwelle gilt nur fuer
    /// Messwerte: der Wert eines Kategorieeintrags ist ein Kennzahlcode
    /// (etwa 5 = REM-Schlaf), und "ueber 5" ist darauf keine sinnvolle
    /// Aussage. Kategorien passieren die Schwelle deshalb immer; Abstand und
    /// Quelle gelten auch fuer sie.
    static func passes(
        _ event: HealthSampleEvent,
        filter: SubscriptionFilter,
        lastTriggeredAt: Date?
    ) -> Bool {
        if let interval = filter.minimumInterval, let last = lastTriggeredAt {
            if event.date.timeIntervalSince(last) < interval { return false }
        }
        if !filter.allowedSourceNames.isEmpty,
           !filter.allowedSourceNames.contains(event.sourceName) {
            return false
        }
        guard isMeasurement(event) else { return true }
        switch filter.threshold {
        case .none:
            return true
        case .above(let bound):
            return event.value > bound
        case .below(let bound):
            return event.value < bound
        case .outside(let lower, let upper):
            return event.value < lower || event.value > upper
        }
    }

    /// Ein Messwert hat eine Einheit. Fehlt sie, ist es ein Kategoriewert --
    /// so ist HealthSampleEvent gebaut, und der Katalog bestaetigt es, wo er
    /// den Typ kennt.
    private static func isMeasurement(_ event: HealthSampleEvent) -> Bool {
        if let descriptor = HealthTypeCatalog.descriptor(for: event.typeIdentifier) {
            return descriptor.kind == .quantity
        }
        return event.unit != nil
    }
}
