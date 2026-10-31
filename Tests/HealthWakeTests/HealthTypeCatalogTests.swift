import HealthKit
import Testing
@testable import HealthWake

@Test func catalogCoversKnownTypes() {
    #expect(HealthTypeCatalog.all.count >= 180)
    #expect(HealthTypeCatalog.descriptor(for: "HKQuantityTypeIdentifierBloodGlucose")?.displayName == "Blood Glucose")
    #expect(HealthTypeCatalog.descriptor(for: "HKQuantityTypeIdentifierHeight")?.group == .body)
}

@Test func identifiersAreUniqueAndNonEmpty() {
    let ids = HealthTypeCatalog.all.map(\.identifier)
    #expect(Set(ids).count == ids.count)
    #expect(HealthTypeCatalog.all.allSatisfy { !$0.displayName.isEmpty })
}

@Test func quantityAndCategoryShapesAreConsistent() {
    for d in HealthTypeCatalog.all {
        switch d.kind {
        case .quantity:
            #expect(d.defaultUnitString != nil)
            #expect(d.categoryLabels == nil)
        case .category:
            #expect(d.defaultUnitString == nil)
            #expect(d.categoryLabels != nil)
        }
    }
}

@Test func searchIsCaseInsensitiveAndMatchesDisplayName() {
    #expect(HealthTypeCatalog.search("glucose").contains { $0.identifier.hasSuffix("BloodGlucose") })
}

@Test func catalogContainsNoCorrelationTypes() {
    // Korrelationen unterstuetzen keine Hintergrundzustellung (Spec 5.5).
    #expect(HealthTypeCatalog.all.allSatisfy { !$0.identifier.contains("CorrelationType") })
    #expect(HealthTypeCatalog.descriptor(for: "HKQuantityTypeIdentifierBloodPressureSystolic") != nil)
}

@Test func sleepAnalysisLabelsAreHumanReadable() {
    let labels = HealthTypeCatalog.descriptor(for: "HKCategoryTypeIdentifierSleepAnalysis")?.categoryLabels
    #expect(labels?[HKCategoryValueSleepAnalysis.asleepREM.rawValue] == "REM Sleep")
}
