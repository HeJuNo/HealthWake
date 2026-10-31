import HealthKit
import UIKit

/// Observer-Abfragen werden ausschliesslich hier angemeldet, in
/// didFinishLaunching -- wird die App vom System geweckt, laeuft nur dieser
/// Weg, keine Oberflaeche (Spec 5.2).
final class AppDelegate: NSObject, UIApplicationDelegate {
    let environment = AppEnvironment.live()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let environment = environment
        Task { @MainActor in
            // Auftraege, die beim letzten Abschuss noch liefen, zuerst
            // zurueckholen -- sonst bleiben sie fuer immer "running".
            _ = try? await environment.queue.reclaimRunning()
            guard environment.isGloballyEnabled else { return }
            await environment.observer.registerAll(identifiers: await environment.enabledIdentifiers())
            await environment.refreshAllNow()
        }

        // Nach dem Entsperren ist die Health-Datenbank wieder lesbar: was
        // waehrend der Sperre aufgelaufen ist, wird jetzt nachgeholt.
        NotificationCenter.default.addObserver(
            forName: UIApplication.protectedDataDidBecomeAvailableNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in await environment.refreshAllNow() }
        }
        return true
    }

    /// Das System hat die App nur geweckt, weil Hintergrund-Uploads fertig
    /// sind. Der Handler muss gerufen werden, sonst gilt die App als haengend.
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        guard identifier == BackgroundUploader.sessionIdentifier else {
            completionHandler()
            return
        }
        BackgroundUploader.shared.handleEvents(completionHandler: completionHandler)
    }
}
