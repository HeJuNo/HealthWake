import SwiftUI

/// Drei Bereiche, wie in Spec 8: beobachtete Typen, Protokoll, Einstellungen.
struct RootView: View {
    @State private var selection = StartScreen.current.tab

    var body: some View {
        TabView(selection: $selection) {
            SubscriptionListView()
                .tabItem { Label("Types", systemImage: "heart.text.square") }
                .tag(0)
            EventLogView()
                .tabItem { Label("Log", systemImage: "list.bullet.rectangle") }
                .tag(1)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(2)
        }
    }
}

/// Beim Start kann ein Bildschirm vorgegeben werden -- gesetzt durch das
/// Startargument "-startScreen <name>". Das benutzt nur scripts/screenshots.sh,
/// um ohne Fingertipp bis zu den tieferen Bildschirmen zu kommen.
enum StartScreen: String {
    case types, log, settings, detail, action

    static var current: StartScreen {
        guard let raw = UserDefaults.standard.string(forKey: "startScreen"),
              let screen = StartScreen(rawValue: raw)
        else { return .types }
        return screen
    }

    var tab: Int {
        switch self {
        case .log: 1
        case .settings: 2
        case .types, .detail, .action: 0
        }
    }
}
