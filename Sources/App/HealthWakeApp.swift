import SwiftUI

@main
struct HealthWakeApp: App {
    var body: some Scene {
        WindowGroup {
            PlaceholderView()
        }
    }
}

/// Platzhalter. Dieser Build existiert nur, um die Signaturkette und die
/// HealthKit-Entitlements bis TestFlight zu pruefen, bevor die eigentliche
/// App entsteht.
struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("HealthWake")
                .font(.title2.weight(.semibold))
            Text("Placeholder for verifying signing and entitlements.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
