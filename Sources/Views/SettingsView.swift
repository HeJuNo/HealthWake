import SwiftUI

/// Platzhalter bis Task 15.
struct SettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Watch health data", isOn: Binding(
                        get: { environment.isGloballyEnabled },
                        set: { newValue in Task { await environment.setGloballyEnabled(newValue) } }
                    ))
                } footer: {
                    Text("Off means no background delivery and no actions. Switching it back on starts watching from that moment.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
