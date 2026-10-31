import SwiftUI
import UIKit

/// Einstellungen: der globale Schalter, die Ablagegroesse, und eine ehrliche
/// Auskunft darueber, was die App ueber ihre Erlaubnis weiss -- naemlich
/// wenig (Spec 5.7).
struct SettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var storedSize = ""
    @State private var diagnosis: [DiagnosisModel.Row] = []
    @State private var notificationStatus = ""
    @State private var isHealthAvailable = true
    @State private var isClearing = false
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                deliverySection
                storageSection
                diagnosisSection
                aboutSection
            }
            .navigationTitle("Settings")
            .task {
                await refreshSize()
                await refreshDiagnosis()
            }
            .confirmationDialog(
                "Delete all recorded entries?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task { await clear() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This only deletes HealthWake's own copies. Nothing in the Health app is touched.")
            }
        }
    }

    private var deliverySection: some View {
        Section {
            Toggle("Watch health data", isOn: Binding(
                get: { environment.isGloballyEnabled },
                set: { newValue in Task { await environment.setGloballyEnabled(newValue) } }
            ))
        } header: {
            Text("Background delivery")
        } footer: {
            Text("Off means no background delivery and no actions. Switching it back on starts watching from that moment; entries from the pause are not caught up.")
        }
    }

    private var storageSection: some View {
        Section {
            LabeledContent("Recorded entries", value: storedSize)
            Button("Delete recorded entries", role: .destructive) {
                showClearConfirmation = true
            }
            .disabled(isClearing)
            Button("Clear finished and failed actions") {
                Task {
                    try? await environment.queue.clearFinished()
                }
            }
        } header: {
            Text("Storage")
        } footer: {
            Text("HealthWake keeps its own copy of every entry it has seen, so it can show them over time.")
        }
    }

    private var diagnosisSection: some View {
        Section {
            LabeledContent("Health data on this device", value: isHealthAvailable ? "Available" : "Not available")
            LabeledContent("Notifications", value: notificationStatus)
            ForEach(diagnosis) { row in
                LabeledContent(row.name, value: row.wouldPrompt ? "Health would still ask" : "Health has been asked")
            }
            Button {
                openHealthApp()
            } label: {
                Label("Open the Health app", systemImage: "heart.fill")
            }
        } header: {
            Text("Access")
        } footer: {
            Text("Health never tells an app whether reading was allowed. If a type stays silent, check Health under Sources to see what HealthWake may read.")
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: versionText)
        } footer: {
            Text("HealthWake reads from Health and never writes to it.")
        }
    }

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    private func openHealthApp() {
        guard let url = URL(string: "x-apple-health://") else { return }
        UIApplication.shared.open(url)
    }

    private func refreshDiagnosis() async {
        let model = DiagnosisModel(store: environment.healthStore, subscriptions: environment.subscriptions)
        isHealthAvailable = model.isHealthDataAvailable
        diagnosis = await model.rows()
        notificationStatus = await model.notificationStatusText()
    }

    private func refreshSize() async {
        storedSize = await StorageModel(samples: environment.samples).storedSizeText()
    }

    private func clear() async {
        isClearing = true
        try? await StorageModel(samples: environment.samples).clearStoredSamples()
        await refreshSize()
        isClearing = false
    }
}
