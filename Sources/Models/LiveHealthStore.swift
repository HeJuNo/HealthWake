import Foundation
import HealthKit

/// Die echte Umsetzung der Naht auf HKHealthStore.
final class LiveHealthStore: HealthStoring {
    private let store = HKHealthStore()

    // MARK: - Erlaubnis

    func requestAuthorization(toRead identifiers: Set<String>) async throws {
        guard HKHealthStore.isHealthDataAvailable() else { throw HealthStoreError.notAvailable }
        let types = try sampleTypes(for: identifiers)
        // Nur lesen. Die App schreibt nie nach Health.
        try await store.requestAuthorization(toShare: [], read: types)
    }

    func wouldPrompt(toRead identifiers: Set<String>) async throws -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { throw HealthStoreError.notAvailable }
        let types = try sampleTypes(for: identifiers)
        let status = try await store.statusForAuthorizationRequest(toShare: [], read: types)
        return status == .shouldRequest
    }

    // MARK: - Hintergrundzustellung

    func enableBackgroundDelivery(for identifier: String, frequency: HKUpdateFrequency) async throws {
        let type = try Self.sampleType(for: identifier)
        try await store.enableBackgroundDelivery(for: type, frequency: frequency)
    }

    func disableAllBackgroundDelivery() async throws {
        try await store.disableAllBackgroundDelivery()
    }

    // MARK: - Abfragen

    func newSamples(for identifier: String, anchor anchorData: Data?) async throws -> NewSamples {
        let type = try Self.sampleType(for: identifier)
        let anchor = try anchorData.map(Self.decodeAnchor)
        let unit = await preferredUnitString(for: identifier)
        return try await runAnchoredQuery(
            type: type,
            identifier: identifier,
            predicate: nil,
            anchor: anchor,
            unit: unit
        )
    }

    /// Ein Anker, der auf "jetzt" zeigt. Die Abfrage laeuft mit einem
    /// Praedikat, das nur Werte ab diesem Augenblick zulaesst -- es kommen
    /// also keine Samples zurueck, der Anker steht aber auf dem aktuellen
    /// Stand des Health-Speichers.
    func currentAnchor(for identifier: String) async throws -> Data {
        let type = try Self.sampleType(for: identifier)
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)
        let result = try await runAnchoredQuery(
            type: type,
            identifier: identifier,
            predicate: predicate,
            anchor: nil,
            unit: nil
        )
        return result.newAnchor
    }

    func preferredUnitString(for identifier: String) async -> String? {
        // Laut SDK-Kopfdatei setzt preferredUnits eine Leseerlaubnis fuer den
        // Typ voraus. Fehlt sie, bleibt der Standard aus dem Katalog.
        guard let type = try? Self.sampleType(for: identifier) as? HKQuantityType else { return nil }
        guard let units = try? await store.preferredUnits(for: [type]) else { return nil }
        return units[type]?.unitString
    }

    // MARK: - Innenleben

    private func runAnchoredQuery(
        type: HKSampleType,
        identifier: String,
        predicate: NSPredicate?,
        anchor: HKQueryAnchor?,
        unit: String?
    ) async throws -> NewSamples {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKAnchoredObjectQuery(
                type: type,
                predicate: predicate,
                anchor: anchor,
                limit: HKObjectQueryNoLimit
            ) { _, samples, deleted, newAnchor, error in
                if let error {
                    continuation.resume(throwing: Self.mapped(error))
                    return
                }
                guard let newAnchor, let anchorData = try? Self.encodeAnchor(newAnchor) else {
                    continuation.resume(throwing: HealthStoreError.databaseInaccessible)
                    return
                }
                let events = (samples ?? []).compactMap {
                    Self.event(from: $0, identifier: identifier, preferredUnit: unit)
                }
                continuation.resume(returning: NewSamples(
                    events: events,
                    deletedUUIDs: (deleted ?? []).map(\.uuid),
                    newAnchor: anchorData
                ))
            }
            store.execute(query)
        }
    }

    private static func event(
        from sample: HKSample,
        identifier: String,
        preferredUnit: String?
    ) -> HealthSampleEvent? {
        let descriptor = HealthTypeCatalog.descriptor(for: identifier)
        let typeName = descriptor?.displayName ?? identifier
        let source = sample.sourceRevision.source.name

        if let quantitySample = sample as? HKQuantitySample {
            let unitString = preferredUnit ?? descriptor?.defaultUnitString ?? "count"
            let unit = HKUnit(from: unitString)
            guard quantitySample.quantity.is(compatibleWith: unit) else { return nil }
            return HealthSampleEvent(
                sampleUUID: sample.uuid,
                typeIdentifier: identifier,
                typeName: typeName,
                value: quantitySample.quantity.doubleValue(for: unit),
                unit: unitString,
                valueLabel: nil,
                date: sample.startDate,
                sourceName: source
            )
        }
        if let categorySample = sample as? HKCategorySample {
            return HealthSampleEvent(
                sampleUUID: sample.uuid,
                typeIdentifier: identifier,
                typeName: typeName,
                value: Double(categorySample.value),
                unit: nil,
                valueLabel: descriptor?.categoryLabels?[categorySample.value] ?? "\(categorySample.value)",
                date: sample.startDate,
                sourceName: source
            )
        }
        return nil
    }

    private func sampleTypes(for identifiers: Set<String>) throws -> Set<HKSampleType> {
        Set(try identifiers.map { try Self.sampleType(for: $0) })
    }

    static func sampleType(for identifier: String) throws -> HKSampleType {
        if identifier.hasPrefix("HKQuantityTypeIdentifier") {
            guard let type = HKObjectType.quantityType(
                forIdentifier: HKQuantityTypeIdentifier(rawValue: identifier)
            ) else { throw HealthStoreError.unknownType(identifier) }
            return type
        }
        if identifier.hasPrefix("HKCategoryTypeIdentifier") {
            guard let type = HKObjectType.categoryType(
                forIdentifier: HKCategoryTypeIdentifier(rawValue: identifier)
            ) else { throw HealthStoreError.unknownType(identifier) }
            return type
        }
        throw HealthStoreError.unknownType(identifier)
    }

    private static func encodeAnchor(_ anchor: HKQueryAnchor) throws -> Data {
        try NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
    }

    private static func decodeAnchor(_ data: Data) throws -> HKQueryAnchor {
        guard let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data) else {
            throw HealthStoreError.unknownType("anchor")
        }
        return anchor
    }

    /// Ein gesperrtes Geraet ist kein Fehler, sondern ein Grund, es spaeter
    /// noch einmal zu versuchen -- deshalb ein eigener Fall.
    private static func mapped(_ error: Error) -> Error {
        if (error as NSError).domain == HKError.errorDomain,
           (error as NSError).code == HKError.Code.errorDatabaseInaccessible.rawValue {
            return HealthStoreError.databaseInaccessible
        }
        return error
    }
}
