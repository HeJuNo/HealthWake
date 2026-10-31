import SwiftUI

@main
struct HealthWakeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appDelegate.environment)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            let environment = appDelegate.environment
            Task { @MainActor in await environment.refreshAllNow() }
        }
    }
}

/// Ankerklasse fuer Bundle(for:) in den Tests. Eine Klasse ist noetig,
/// weil Bundle(for:) eine AnyClass erwartet.
final class HealthWakeMarker {}
