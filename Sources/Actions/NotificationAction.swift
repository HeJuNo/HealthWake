import Foundation
import UserNotifications

/// Schickt eine lokale Mitteilung mit den Werten des Eintrags.
///
/// Um die Erlaubnis fuer Mitteilungen wird hier nicht gebeten -- das
/// passiert, wenn der Benutzer die erste Mitteilungsaktion anlegt. Eine
/// Aktion, die im Hintergrund laeuft, darf keinen Dialog aufziehen.
struct NotificationAction: HealthAction {
    struct Config: Codable, Sendable, Equatable {
        var titleTemplate: String
        var bodyTemplate: String
    }

    static let typeID = "notification"
    static let displayName = "Notification"
    static let defaultConfig = Config(
        titleTemplate: "{{typeName}}",
        bodyTemplate: "{{value}} {{unit}} from {{source}}"
    )

    func perform(event: HealthSampleEvent, config: Config) async throws {
        let content = UNMutableNotificationContent()
        content.title = Template.render(config.titleTemplate, event: event, context: .plain)
        content.body = Template.render(config.bodyTemplate, event: event, context: .plain)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "healthwake.\(event.sampleUUID.uuidString)",
            content: content,
            // Kein Trigger: sofort zustellen. Die App laeuft hier schon im
            // Weckfenster, es gibt nichts zu planen.
            trigger: nil
        )
        try await UNUserNotificationCenter.current().add(request)
    }
}
