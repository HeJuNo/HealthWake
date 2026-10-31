import SwiftUI

@main
struct HealthWakeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            PlaceholderView()
                .environmentObject(appDelegate.environment)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            let environment = appDelegate.environment
            Task { @MainActor in await environment.refreshAllNow() }
        }
    }
}

/// Platzhalter bis zur Oberflaeche aus Task 13.
struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("HealthWake")
                .font(.title2.weight(.semibold))
        }
        .padding()
    }
}

/// Ankerklasse fuer Bundle(for:) in den Tests. Eine Klasse ist noetig,
/// weil Bundle(for:) eine AnyClass erwartet.
final class HealthWakeMarker {}
