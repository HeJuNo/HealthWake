import Foundation
import Testing
@testable import HealthWake

private func quantity(
    value: Double,
    source: String = "Health",
    date: Date = Date(timeIntervalSince1970: 1_000_000)
) -> HealthSampleEvent {
    HealthSampleEvent(
        sampleUUID: UUID(),
        typeIdentifier: "HKQuantityTypeIdentifierBodyMass",
        typeName: "Weight",
        value: value,
        unit: "kg",
        valueLabel: nil,
        date: date,
        sourceName: source
    )
}

private func category(value: Double) -> HealthSampleEvent {
    HealthSampleEvent(
        sampleUUID: UUID(),
        typeIdentifier: "HKCategoryTypeIdentifierSleepAnalysis",
        typeName: "Sleep",
        value: value,
        unit: nil,
        valueLabel: "REM Sleep",
        date: Date(timeIntervalSince1970: 1_000_000),
        sourceName: "Apple Watch"
    )
}

private func filter(
    threshold: SubscriptionFilter.Threshold = .none,
    minimumInterval: TimeInterval? = nil,
    sources: [String] = []
) -> SubscriptionFilter {
    SubscriptionFilter(threshold: threshold, minimumInterval: minimumInterval, allowedSourceNames: sources)
}

@Test func noThresholdLetsEverythingThrough() {
    #expect(FilterEvaluator.passes(quantity(value: -17), filter: filter(), lastTriggeredAt: nil))
}

@Test func aboveRejectsTheBoundaryItself() {
    let above5 = filter(threshold: .above(5))
    #expect(!FilterEvaluator.passes(quantity(value: 4.9), filter: above5, lastTriggeredAt: nil))
    #expect(!FilterEvaluator.passes(quantity(value: 5), filter: above5, lastTriggeredAt: nil))
    #expect(FilterEvaluator.passes(quantity(value: 5.1), filter: above5, lastTriggeredAt: nil))
}

@Test func belowRejectsTheBoundaryItself() {
    let below5 = filter(threshold: .below(5))
    #expect(FilterEvaluator.passes(quantity(value: 4.9), filter: below5, lastTriggeredAt: nil))
    #expect(!FilterEvaluator.passes(quantity(value: 5), filter: below5, lastTriggeredAt: nil))
    #expect(!FilterEvaluator.passes(quantity(value: 5.1), filter: below5, lastTriggeredAt: nil))
}

@Test func outsideAcceptsOnlyBeyondBothBounds() {
    let outside = filter(threshold: .outside(lower: 4, upper: 10))
    #expect(FilterEvaluator.passes(quantity(value: 3.9), filter: outside, lastTriggeredAt: nil))
    #expect(!FilterEvaluator.passes(quantity(value: 4), filter: outside, lastTriggeredAt: nil))
    #expect(!FilterEvaluator.passes(quantity(value: 7), filter: outside, lastTriggeredAt: nil))
    #expect(!FilterEvaluator.passes(quantity(value: 10), filter: outside, lastTriggeredAt: nil))
    #expect(FilterEvaluator.passes(quantity(value: 10.1), filter: outside, lastTriggeredAt: nil))
}

@Test func minimumIntervalRejectsInsideTheWindowAndAcceptsTheBoundary() {
    let last = Date(timeIntervalSince1970: 1_000_000)
    let window = filter(minimumInterval: 600)
    #expect(!FilterEvaluator.passes(
        quantity(value: 1, date: last.addingTimeInterval(599)), filter: window, lastTriggeredAt: last))
    #expect(FilterEvaluator.passes(
        quantity(value: 1, date: last.addingTimeInterval(600)), filter: window, lastTriggeredAt: last))
    // Ohne vorherige Ausloesung gibt es kein Fenster.
    #expect(FilterEvaluator.passes(quantity(value: 1), filter: window, lastTriggeredAt: nil))
}

@Test func emptySourceListAcceptsEverySource() {
    #expect(FilterEvaluator.passes(quantity(value: 1, source: "Irgendwas"), filter: filter(), lastTriggeredAt: nil))
}

@Test func sourceListIsAnExactMatchAllowlist() {
    let only = filter(sources: ["Dexcom", "Health"])
    #expect(FilterEvaluator.passes(quantity(value: 1, source: "Dexcom"), filter: only, lastTriggeredAt: nil))
    #expect(!FilterEvaluator.passes(quantity(value: 1, source: "dexcom"), filter: only, lastTriggeredAt: nil))
    #expect(!FilterEvaluator.passes(quantity(value: 1, source: "Dexcom G7"), filter: only, lastTriggeredAt: nil))
}

@Test func categoryEventIsNotFilteredByANumericThreshold() {
    // Der Wert eines Kategorieeintrags ist ein Kennzahlcode, keine Messgroesse.
    // "ueber 5" darf einen Schlafwert mit Code 5 nicht aussortieren.
    let above5 = filter(threshold: .above(5))
    #expect(FilterEvaluator.passes(category(value: 5), filter: above5, lastTriggeredAt: nil))
    #expect(FilterEvaluator.passes(category(value: 0), filter: above5, lastTriggeredAt: nil))
    // Zeitfenster und Quelle gelten aber auch fuer Kategorien.
    let last = Date(timeIntervalSince1970: 1_000_000)
    #expect(!FilterEvaluator.passes(category(value: 5), filter: filter(minimumInterval: 600), lastTriggeredAt: last))
}
