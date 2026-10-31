import SwiftUI
import UserNotifications

extension NotificationAction {
    @MainActor
    static func makeConfigView(config: Config, onChange: @escaping (Config) -> Void) -> AnyView {
        AnyView(NotificationConfigView(config: config, onChange: onChange))
    }
}

/// Erlaubnis fuer Mitteilungen wird genau dann geholt, wenn die erste
/// Mitteilungsaktion entsteht -- nicht beim Start. Ein Dialog ohne Anlass
/// ist der schnellste Weg zu einem Nein.
enum NotificationAuthorization {
    @discardableResult
    static func requestIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .denied:
            return false
        default:
            return true
        }
    }
}

struct NotificationConfigView: View {
    @State private var config: NotificationAction.Config
    private let onChange: (NotificationAction.Config) -> Void

    init(config: NotificationAction.Config, onChange: @escaping (NotificationAction.Config) -> Void) {
        _config = State(initialValue: config)
        self.onChange = onChange
    }

    private var preview: (title: String, body: String) {
        NotificationConfigModel(config: config).preview()
    }

    var body: some View {
        Form {
            Section("Title") {
                TextField("Title", text: $config.titleTemplate, axis: .vertical)
                    .accessibilityLabel("Notification title template")
            }
            Section("Message") {
                TextField("Message", text: $config.bodyTemplate, axis: .vertical)
                    .accessibilityLabel("Notification message template")
            }
            Section("Preview") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(preview.title).font(.headline)
                    Text(preview.body).font(.subheadline).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
            PlaceholderHelp()
        }
        .navigationTitle("Notification")
        .onChange(of: config) { _, newValue in onChange(newValue) }
    }
}

/// Die Liste der Platzhalter gehoert neben jedes Vorlagenfeld -- sonst muss
/// man sie raten.
struct PlaceholderHelp: View {
    var body: some View {
        Section {
            ForEach(Template.placeholders, id: \.self) { name in
                Text("{{\(name)}}")
                    .font(.system(.footnote, design: .monospaced))
            }
        } header: {
            Text("Placeholders")
        } footer: {
            Text("Each one is replaced with the value from the health entry.")
        }
    }
}
