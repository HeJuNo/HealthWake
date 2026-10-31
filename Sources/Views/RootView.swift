import SwiftUI

/// Drei Bereiche, wie in Spec 8: beobachtete Typen, Protokoll, Einstellungen.
struct RootView: View {
    var body: some View {
        TabView {
            SubscriptionListView()
                .tabItem { Label("Types", systemImage: "heart.text.square") }
            LogView()
                .tabItem { Label("Log", systemImage: "list.bullet.rectangle") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
