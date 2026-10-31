import SwiftUI

/// Eine Aktion, die auf einen neuen Health-Eintrag hin laeuft.
///
/// Der Erweiterungspunkt der App: eine neue Aktion braucht einen Typ, der
/// dieses Protokoll erfuellt, und eine Zeile in der ActionRegistry. Alles
/// andere -- Speichern der Einstellung, Warteschlange, Wiederholung,
/// Protokoll -- gilt dann schon fuer sie.
protocol HealthAction: Sendable {
    associatedtype Config: Codable & Sendable & Equatable

    /// Dauerhafter Schluessel. Steht in gespeicherten Bindungen und in
    /// Auftraegen, darf sich also nie aendern.
    static var typeID: String { get }
    /// Sichtbarer Text, deshalb Englisch.
    static var displayName: String { get }
    static var defaultConfig: Config { get }

    func perform(event: HealthSampleEvent, config: Config) async throws

    /// Die Einstellungsflaeche dieser Aktion. Standard ist leer, damit eine
    /// neue Aktion zuerst laufen kann und erst danach eine Oberflaeche braucht.
    @MainActor
    static func makeConfigView(config: Config, onChange: @escaping (Config) -> Void) -> AnyView
}

extension HealthAction {
    @MainActor
    static func makeConfigView(config: Config, onChange: @escaping (Config) -> Void) -> AnyView {
        AnyView(EmptyView())
    }
}

/// Entkleidete Aktion: dieselbe Aktion, aber mit Data statt mit ihrem
/// eigenen Config-Typ. Noetig, weil Warteschlange und Oberflaeche mit
/// gemischten Aktionen umgehen muessen und ein Protokoll mit assoziiertem
/// Typ sich nicht in eine Liste legen laesst.
struct AnyHealthAction: Sendable, Identifiable {
    var id: String { typeID }
    let typeID: String
    let displayName: String
    let defaultConfigData: @Sendable () throws -> Data
    let perform: @Sendable (HealthSampleEvent, Data) async throws -> Void
    let makeConfigView: @MainActor @Sendable (Data, @escaping (Data) -> Void) -> AnyView

    init<Action: HealthAction>(_ action: Action) {
        typeID = Action.typeID
        displayName = Action.displayName
        defaultConfigData = {
            try JSONEncoder().encode(Action.defaultConfig)
        }
        perform = { event, configData in
            let config = try JSONDecoder().decode(Action.Config.self, from: configData)
            try await action.perform(event: event, config: config)
        }
        makeConfigView = { configData, onChange in
            // Eine nicht lesbare Einstellung faellt auf die Standardwerte
            // zurueck, statt den Bildschirm leer zu lassen.
            let config = (try? JSONDecoder().decode(Action.Config.self, from: configData))
                ?? Action.defaultConfig
            return Action.makeConfigView(config: config) { updated in
                guard let encoded = try? JSONEncoder().encode(updated) else { return }
                onChange(encoded)
            }
        }
    }
}

/// Alle verfuegbaren Aktionen. Eine neue Aktion wird hier eingetragen und
/// taucht damit ueberall in der Oberflaeche auf.
enum ActionRegistry {
    static let all: [AnyHealthAction] = [
        AnyHealthAction(NotificationAction()),
    ]

    static func action(for typeID: String) -> AnyHealthAction? {
        all.first { $0.typeID == typeID }
    }
}
