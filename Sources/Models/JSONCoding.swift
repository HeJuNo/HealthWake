import Foundation

/// Zwei Spielarten der JSON-Kodierung, aus einem Grund: Zeitpunkte.
///
/// `exact` ueberlaesst Date seine eigene Kodierung: Sekunden seit dem
/// Bezugsdatum, genau so, wie Date sie intern haelt. Der Umweg ueber 1970
/// waere nicht verlustfrei -- die knapp eine Milliarde Sekunden Abstand
/// kostet genug Stellen, dass ein Zeitpunkt nach dem Hin und Zurueck nicht
/// mehr derselbe ist. Das braucht alles, was verglichen oder sortiert wird:
/// ein Anker, ein naechster Versuch, ein Anlegedatum.
///
/// `readable` schreibt ISO-8601 mit Millisekunden. Das ist fuer die Dateien
/// gedacht, die jemand aufmacht und liest: die Werteablage und das Protokoll.
/// Die Genauigkeit endet dort bei Millisekunden -- fuer Health-Werte, die
/// ohnehin sekundengenau anfallen, genau richtig.
enum JSONCoding {
    static func exactEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .deferredToDate
        encoder.outputFormatting = []
        return encoder
    }

    static func exactDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .deferredToDate
        return decoder
    }

    static func readableEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(isoFormatter)
        encoder.outputFormatting = []
        return encoder
    }

    static func readableDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(isoFormatter)
        return decoder
    }

    private static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}
