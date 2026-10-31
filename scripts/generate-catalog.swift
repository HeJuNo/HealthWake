#!/usr/bin/env swift
//
// Erzeugt Sources/Models/HealthTypeCatalog+Table.swift aus den Kopfdateien
// des installierten iOS-SDK. Ausfuehren mit:
//
//     swift scripts/generate-catalog.swift
//
// Die Ausgabe ist ein Ausgangspunkt, kein Endergebnis: Anzeigenamen und
// Gruppen werden hier kuratiert (siehe displayNameOverrides) und danach
// in der erzeugten Datei von Hand nachgebessert, wo das Englisch schief
// klingt.
//

import Foundation

// MARK: - Grenzen

/// Hoechste iOS-Fassung, deren Typen aufgenommen werden. Das Bereitstellungs-
/// ziel der App ist 18.0; neuere Typen gaebe es auf dem Geraet gar nicht.
let maximumIOS = (major: 18, minor: 0)

// MARK: - SDK finden

func run(_ launchPath: String, _ arguments: [String]) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: launchPath)
    process.arguments = arguments
    let pipe = Pipe()
    process.standardOutput = pipe
    try? process.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}

let sdkPath = run("/usr/bin/xcrun", ["--sdk", "iphoneos", "--show-sdk-path"])
guard !sdkPath.isEmpty else {
    FileHandle.standardError.write(Data("Kein iPhoneOS-SDK gefunden.\n".utf8))
    exit(1)
}
let headerDirectory = sdkPath + "/System/Library/Frameworks/HealthKit.framework/Headers"

func readHeader(_ name: String) -> [String] {
    guard let text = try? String(contentsOfFile: headerDirectory + "/" + name, encoding: .utf8) else {
        FileHandle.standardError.write(Data("Kopfdatei fehlt: \(name)\n".utf8))
        exit(1)
    }
    return text.components(separatedBy: .newlines)
}

// MARK: - Kleine Regex-Hilfe

func firstMatch(_ pattern: String, in line: String) -> [String]? {
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line))
    else { return nil }
    return (0..<match.numberOfRanges).map { index in
        guard let range = Range(match.range(at: index), in: line) else { return "" }
        return String(line[range])
    }
}

// MARK: - Namen in lesbares Englisch

let smallWords: Set<String> = ["of", "in", "on", "per", "to", "and", "the", "or"]

/// Trennt CamelCase, haelt dabei Abkuerzungsfolgen (SDNN, REM, UV) zusammen.
func splitCamelCase(_ input: String) -> [String] {
    var words: [String] = []
    var current = ""
    let characters = Array(input)
    for (index, character) in characters.enumerated() {
        if current.isEmpty {
            current.append(character)
            continue
        }
        let previous = characters[index - 1]
        let next: Character? = index + 1 < characters.count ? characters[index + 1] : nil
        let startsWord: Bool
        if character.isUppercase, previous.isLowercase || previous.isNumber {
            startsWord = true
        } else if character.isUppercase, previous.isUppercase, let next, next.isLowercase {
            startsWord = true
        } else if character.isNumber, previous.isLetter, previous.isLowercase {
            startsWord = false
        } else {
            startsWord = false
        }
        if startsWord {
            words.append(current)
            current = String(character)
        } else {
            current.append(character)
        }
    }
    if !current.isEmpty { words.append(current) }
    return words
}

func humanize(_ input: String) -> String {
    let words = splitCamelCase(input)
    return words.enumerated().map { index, word in
        if index > 0, smallWords.contains(word.lowercased()) { return word.lowercased() }
        return word
    }.joined(separator: " ")
}

/// Kuratierte Namen: ueberall dort, wo der aus dem Bezeichner abgeleitete
/// Name kein Englisch ist, das jemand in der Health-App wiedererkennt.
let displayNameOverrides: [String: String] = [
    "HKQuantityTypeIdentifierBodyMass": "Weight",
    "HKQuantityTypeIdentifierBodyMassIndex": "Body Mass Index",
    "HKQuantityTypeIdentifierActiveEnergyBurned": "Active Energy",
    "HKQuantityTypeIdentifierBasalEnergyBurned": "Resting Energy",
    "HKQuantityTypeIdentifierDistanceWalkingRunning": "Walking + Running Distance",
    "HKQuantityTypeIdentifierAppleExerciseTime": "Exercise Time",
    "HKQuantityTypeIdentifierAppleMoveTime": "Move Time",
    "HKQuantityTypeIdentifierAppleStandTime": "Stand Time",
    "HKQuantityTypeIdentifierAppleWalkingSteadiness": "Walking Steadiness",
    "HKQuantityTypeIdentifierAppleSleepingWristTemperature": "Sleeping Wrist Temperature",
    "HKQuantityTypeIdentifierAppleSleepingBreathingDisturbances": "Sleeping Breathing Disturbances",
    "HKQuantityTypeIdentifierHeartRateVariabilitySDNN": "Heart Rate Variability",
    "HKQuantityTypeIdentifierOxygenSaturation": "Blood Oxygen",
    "HKQuantityTypeIdentifierSixMinuteWalkTestDistance": "Six-Minute Walk Distance",
    "HKQuantityTypeIdentifierVO2Max": "VO2 Max",
    "HKQuantityTypeIdentifierUVExposure": "UV Index",
    "HKQuantityTypeIdentifierDietaryEnergyConsumed": "Dietary Energy",
    "HKQuantityTypeIdentifierDietaryWater": "Water",
    "HKQuantityTypeIdentifierForcedExpiratoryVolume1": "Forced Expiratory Volume (FEV1)",
    "HKQuantityTypeIdentifierNikeFuel": "NikeFuel",
    "HKCategoryTypeIdentifierAppleStandHour": "Stand Hour",
    "HKCategoryTypeIdentifierAppleWalkingSteadinessEvent": "Walking Steadiness Event",
    "HKCategoryTypeIdentifierSleepAnalysis": "Sleep",
    "HKCategoryTypeIdentifierMindfulSession": "Mindful Minutes",
]

// MARK: - Gruppen

/// Die Abschnittsueberschriften der Kopfdatei sind bereits eine Gliederung.
/// Diese Zuordnung uebersetzt sie in die Gruppen der Oberflaeche.
let groupForSection: [String: String] = [
    "Body Measurements": "body",
    "Fitness": "activity",
    "Hearing Health": "hearing",
    "Heart": "vitals",
    "Mobility": "mobility",
    "Nutrition": "nutrition",
    "Other": "other",
    "Reproductive Health": "reproductive",
    "Respiratory": "respiratory",
    "Vital Signs": "vitals",
    "Mental Wellbeing": "other",
    "Sleep": "sleep",
    "Symptoms": "other",
    "Medication Tracking": "other",
]

/// Einzelkorrekturen, wo der Abschnitt der Kopfdatei nicht zur Gruppe passt.
let groupOverrides: [String: String] = [
    "HKQuantityTypeIdentifierBloodPressureSystolic": "vitals",
    "HKQuantityTypeIdentifierBloodPressureDiastolic": "vitals",
    "HKQuantityTypeIdentifierElectrodermalActivity": "other",
    "HKQuantityTypeIdentifierAppleSleepingWristTemperature": "sleep",
    "HKQuantityTypeIdentifierAppleSleepingBreathingDisturbances": "sleep",
    "HKCategoryTypeIdentifierSleepApneaEvent": "sleep",
    "HKQuantityTypeIdentifierTimeInDaylight": "other",
]

/// Die kanonische Einheit aus der Kopfdatei ist nicht immer die, die ein
/// Mensch erwartet. Diese Fassung dient nur als Rueckfall, wenn iOS keine
/// bevorzugte Einheit liefert -- sie soll trotzdem lesbar sein.
let unitOverrides: [String: String] = [
    "HKQuantityTypeIdentifierHeartRate": "count/min",
    "HKQuantityTypeIdentifierRespiratoryRate": "count/min",
    "HKQuantityTypeIdentifierUVExposure": "count",
]

// MARK: - Kategoriewerte

/// Welcher HKCategoryValue-Aufzaehlungstyp zu welchem Kategorietyp gehoert.
/// Steht in keiner Kopfdatei, nur in Apples Dokumentation -- deshalb hier
/// von Hand. Symptome ohne Eintrag benutzen Severity, alle anderen den
/// schlichten HKCategoryValue (notApplicable).
let valueEnumForCategory: [String: String] = [
    "HKCategoryTypeIdentifierAppleStandHour": "HKCategoryValueAppleStandHour",
    "HKCategoryTypeIdentifierAppleWalkingSteadinessEvent": "HKCategoryValueAppleWalkingSteadinessEvent",
    "HKCategoryTypeIdentifierEnvironmentalAudioExposureEvent": "HKCategoryValueEnvironmentalAudioExposureEvent",
    "HKCategoryTypeIdentifierHeadphoneAudioExposureEvent": "HKCategoryValueHeadphoneAudioExposureEvent",
    "HKCategoryTypeIdentifierLowCardioFitnessEvent": "HKCategoryValueLowCardioFitnessEvent",
    "HKCategoryTypeIdentifierCervicalMucusQuality": "HKCategoryValueCervicalMucusQuality",
    "HKCategoryTypeIdentifierContraceptive": "HKCategoryValueContraceptive",
    "HKCategoryTypeIdentifierMenstrualFlow": "HKCategoryValueMenstrualFlow",
    "HKCategoryTypeIdentifierOvulationTestResult": "HKCategoryValueOvulationTestResult",
    "HKCategoryTypeIdentifierPregnancyTestResult": "HKCategoryValuePregnancyTestResult",
    "HKCategoryTypeIdentifierProgesteroneTestResult": "HKCategoryValueProgesteroneTestResult",
    "HKCategoryTypeIdentifierSleepAnalysis": "HKCategoryValueSleepAnalysis",
    "HKCategoryTypeIdentifierBleedingAfterPregnancy": "HKCategoryValueVaginalBleeding",
    "HKCategoryTypeIdentifierBleedingDuringPregnancy": "HKCategoryValueVaginalBleeding",
    "HKCategoryTypeIdentifierAppetiteChanges": "HKCategoryValueAppetiteChanges",
]

/// Kuratierte Beschriftungen fuer Werte, deren Fallname sich nicht in gutes
/// Englisch uebersetzen laesst.
let labelOverrides: [String: [Int: String]] = [
    "HKCategoryValueSleepAnalysis": [
        0: "In Bed", 1: "Asleep", 2: "Awake", 3: "Core Sleep", 4: "Deep Sleep", 5: "REM Sleep",
    ],
    "HKCategoryValue": [0: "Recorded"],
    "HKCategoryValueAppleStandHour": [0: "Stood", 1: "Idle"],
    "HKCategoryValueOvulationTestResult": [
        1: "Negative", 2: "LH Surge", 3: "Indeterminate", 4: "Estrogen Surge",
    ],
    "HKCategoryValueAppleWalkingSteadinessEvent": [
        1: "First Low Reading", 2: "First Very Low Reading",
        3: "Repeat Low Reading", 4: "Repeat Very Low Reading",
    ],
]

// MARK: - Kopfdateien lesen

struct TypeEntry {
    let identifier: String
    let kind: String          // "quantity" oder "category"
    let section: String
    let unit: String?
}

func parseVersion(_ line: String) -> (Int, Int) {
    guard let match = firstMatch(#"API_AVAILABLE\(ios\((\d+)\.(\d+)\)"#, in: line),
          let major = Int(match[1]), let minor = Int(match[2])
    else { return (8, 0) }
    return (major, minor)
}

var entries: [TypeEntry] = []
var section = "Other"
for line in readHeader("HKTypeIdentifiers.h") {
    if let heading = firstMatch(#"^// ([A-Z][A-Za-z ]+)$"#, in: line) {
        section = heading[1]
        continue
    }
    guard let match = firstMatch(#"HK_EXTERN (HKQuantityTypeIdentifier|HKCategoryTypeIdentifier) const (HK\w+)"#, in: line)
    else { continue }
    if line.contains("API_DEPRECATED") { continue }
    let version = parseVersion(line)
    if version > maximumIOS { continue }

    let kind = match[1] == "HKQuantityTypeIdentifier" ? "quantity" : "category"
    var unit: String?
    if kind == "quantity" {
        if let override = unitOverrides[match[2]] {
            unit = override
        } else if let comment = firstMatch(#";\s*//\s*([^,]+)"#, in: line),
                  !comment[1].trimmingCharacters(in: .whitespaces).isEmpty {
            unit = comment[1].trimmingCharacters(in: .whitespaces)
        } else {
            unit = "count"
        }
    }
    entries.append(TypeEntry(identifier: match[2], kind: kind, section: section, unit: unit))
}

/// Aufzaehlungstyp -> [Rohwert: Fallname ohne Praefix]
var valueEnums: [String: [Int: String]] = [:]
var currentEnum: String?
for line in readHeader("HKCategoryValues.h") {
    if let match = firstMatch(#"typedef NS_ENUM\(NSInteger, (HKCategoryValue\w*)\)"#, in: line) {
        currentEnum = match[1]
        valueEnums[match[1]] = [:]
        continue
    }
    guard let name = currentEnum else { continue }
    if line.contains("} API_") { currentEnum = nil; continue }
    if line.contains("API_DEPRECATED") { continue }
    guard let match = firstMatch(#"\#(name)(\w+)\s*(?:API_AVAILABLE\([^)]*\)\s*)?=\s*(\d+)"#, in: line),
          let value = Int(match[2])
    else { continue }
    valueEnums[name]?[value] = match[1]
}

// MARK: - Datei schreiben

func swiftLiteral(_ text: String) -> String {
    "\"" + text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
}

func displayName(for identifier: String) -> String {
    if let override = displayNameOverrides[identifier] { return override }
    let stripped = identifier
        .replacingOccurrences(of: "HKQuantityTypeIdentifier", with: "")
        .replacingOccurrences(of: "HKCategoryTypeIdentifier", with: "")
    return humanize(stripped)
}

func group(for entry: TypeEntry) -> String {
    if let override = groupOverrides[entry.identifier] { return override }
    return groupForSection[entry.section] ?? "other"
}

func labels(for entry: TypeEntry) -> [Int: String] {
    let enumName = valueEnumForCategory[entry.identifier]
        ?? (entry.section == "Symptoms" ? "HKCategoryValueSeverity" : "HKCategoryValue")
    if let override = labelOverrides[enumName] { return override }
    guard let cases = valueEnums[enumName], !cases.isEmpty else { return [0: "Recorded"] }
    return cases.mapValues { humanize($0) }
}

var output = """
// ERZEUGT von scripts/generate-catalog.swift aus den Kopfdateien des iOS-SDK,
// danach von Hand kuratiert. Wer neue Typen aufnimmt, laesst das Skript neu
// laufen und uebernimmt die Kuratierung.

import Foundation

extension HealthTypeCatalog {
    static let table: [HealthTypeDescriptor] = [

"""

for entry in entries.sorted(by: { $0.identifier < $1.identifier }) {
    let name = swiftLiteral(displayName(for: entry.identifier))
    let groupName = group(for: entry)
    if entry.kind == "quantity" {
        output += """
            HealthTypeDescriptor(
                identifier: \(swiftLiteral(entry.identifier)),
                kind: .quantity,
                displayName: \(name),
                group: .\(groupName),
                defaultUnitString: \(swiftLiteral(entry.unit ?? "count")),
                categoryLabels: nil
            ),

        """
    } else {
        let pairs = labels(for: entry).sorted { $0.key < $1.key }
            .map { "\($0.key): \(swiftLiteral($0.value))" }
            .joined(separator: ", ")
        output += """
            HealthTypeDescriptor(
                identifier: \(swiftLiteral(entry.identifier)),
                kind: .category,
                displayName: \(name),
                group: .\(groupName),
                defaultUnitString: nil,
                categoryLabels: [\(pairs)]
            ),

        """
    }
}

output += """
    ]
}

"""

let destination = "Sources/Models/HealthTypeCatalog+Table.swift"
try? FileManager.default.createDirectory(atPath: "Sources/Models", withIntermediateDirectories: true)
try! output.write(toFile: destination, atomically: true, encoding: .utf8)
print("\(entries.count) Typen nach \(destination) geschrieben")
