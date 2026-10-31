import UserNotifications

/// Sagt iOS, dass eine Mitteilung auch dann zu sehen ist, wenn die App
/// gerade offen ist.
///
/// Ohne Delegaten verwirft iOS jede Mitteilung, die im Vordergrund
/// eintrifft -- lautlos, und `add` meldet trotzdem Erfolg. Das Protokoll
/// schrieb dann "Notification ran", und zu sehen war nichts. Die App holt
/// beim Wechsel in den Vordergrund nach (scenePhase .active), also ist
/// genau das der haeufigste Weg, auf dem eine Mitteilung entsteht.
///
/// Eigene Klasse und nicht der AppDelegate: das Zentrum haelt den
/// Delegaten nur schwach, der Verweis muss also jemandem gehoeren, der so
/// lange lebt wie der Prozess.
final class ForegroundNotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ForegroundNotificationPresenter()

    /// `.list` gehoert dazu: ohne sie fehlt die Mitteilung spaeter in der
    /// Mitteilungszentrale, wenn der Benutzer gerade nicht hinsieht.
    static let presentationOptions: UNNotificationPresentationOptions = [.banner, .sound, .list]

    /// Muss noch in didFinishLaunching laufen, bevor der Start fertig ist
    /// -- spaeter gesetzt, verpasst der Delegat die ersten Mitteilungen.
    static func install() {
        UNUserNotificationCenter.current().delegate = shared
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        Self.presentationOptions
    }
}
