import SwiftUI

/// Platzhalter bis Task 15. Steht hier, damit RootView schon drei Bereiche hat.
struct LogView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Log",
                systemImage: "list.bullet.rectangle",
                description: Text("Entries and action results will appear here.")
            )
            .navigationTitle("Log")
        }
    }
}
