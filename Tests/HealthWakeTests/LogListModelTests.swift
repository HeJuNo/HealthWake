import Foundation
import Testing
@testable import HealthWake

private var berlin: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
    return calendar
}

/// 2026-10-30 14:00 und 2026-10-31 09:00 Berliner Zeit -- zwei Tage.
private let gestern = Date(timeIntervalSince1970: 1_793_880_000)
private let heute = Date(timeIntervalSince1970: 1_793_952_000)

private func entry(
    kind: LogEntry.Kind = .sampleReceived,
    message: String = "Blood Glucose: 5.4 mmol/L from Dexcom",
    date: Date,
    typeName: String? = "Blood Glucose",
    sourceName: String? = "Dexcom",
    valueText: String? = "5.4 mmol/L"
) -> LogEntry {
    LogEntry(
        id: UUID(),
        date: date,
        kind: kind,
        message: message,
        typeIdentifier: "HKQuantityTypeIdentifierBloodGlucose",
        actionTypeID: nil,
        typeName: typeName,
        sourceName: sourceName,
        valueText: valueText
    )
}

@Test func eintraegeWerdenNachTagGruppiert() {
    let days = LogListModel.days(for: [entry(date: heute), entry(date: gestern)], calendar: berlin)
    #expect(days.count == 2)
    #expect(days.allSatisfy { $0.rows.count == 1 })
}

@Test func dieNeuestenTageStehenOben() {
    let days = LogListModel.days(for: [entry(date: gestern), entry(date: heute)], calendar: berlin)
    #expect(days.map(\.id) == [berlin.startOfDay(for: heute), berlin.startOfDay(for: gestern)])
}

@Test func jederTagHatEinenEigenenTitel() {
    let days = LogListModel.days(for: [entry(date: heute), entry(date: gestern)], calendar: berlin)
    #expect(days[0].title != days[1].title)
    #expect(days.allSatisfy { !$0.title.isEmpty })
}

@Test func innerhalbEinesTagesBleibtDieUebergebeneReihenfolge() {
    let spaeter = entry(message: "spaeter", date: heute.addingTimeInterval(60))
    let frueher = entry(message: "frueher", date: heute)
    let days = LogListModel.days(for: [spaeter, frueher], calendar: berlin)
    #expect(days.count == 1)
    #expect(days[0].rows.map(\.id) == [spaeter.id, frueher.id])
}

@Test func einWertZeigtNamenAppUndWertGetrennt() {
    let days = LogListModel.days(for: [entry(date: heute)], calendar: berlin)
    #expect(days[0].rows[0].content == .measurement(
        typeName: "Blood Glucose",
        sourceName: "Dexcom",
        value: "5.4 mmol/L"
    ))
}

@Test func allesAndereZeigtWeiterhinDieNachricht() {
    let gelaufen = entry(
        kind: .actionSucceeded,
        message: "Notification ran for Blood Glucose",
        date: heute,
        typeName: nil,
        sourceName: nil,
        valueText: nil
    )
    let days = LogListModel.days(for: [gelaufen], calendar: berlin)
    #expect(days[0].rows[0].content == .message("Notification ran for Blood Glucose"))
}

/// Protokolle, die vor dieser Aenderung geschrieben wurden, haben die neuen
/// Felder nicht. Sie muessen trotzdem lesbar bleiben, sonst sieht der
/// Benutzer nach dem Aktualisieren ein leeres Protokoll.
@Test func einAltesProtokollOhneDieNeuenFelderBleibtLesbar() throws {
    let alt = """
    [{"id":"\(UUID().uuidString)","date":"2026-10-31T09:00:00.000Z",\
    "kind":"sampleReceived","message":"Blood Glucose: 5.4 mmol/L from Dexcom"}]
    """
    let entries = try JSONCoding.readableDecoder().decode([LogEntry].self, from: Data(alt.utf8))
    #expect(entries.count == 1)
    let days = LogListModel.days(for: entries, calendar: berlin)
    #expect(days[0].rows[0].content == .message("Blood Glucose: 5.4 mmol/L from Dexcom"))
}
