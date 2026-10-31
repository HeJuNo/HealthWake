import SwiftUI

/// Das Protokoll: neueste Zeile zuerst, Fehler hervorgehoben, und ganz oben
/// die Auftraege, die aufgegeben haben. Die einzige Stelle, an der man sieht,
/// warum etwas nicht passiert ist.
struct EventLogView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var entries: [LogEntry] = []
    @State private var failedJobs: [ActionJob] = []
    @State private var exportText: String?

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty && failedJobs.isEmpty {
                    ContentUnavailableView(
                        "Nothing yet",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Entries, actions and errors show up here as they happen.")
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Log")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { exportText = await environment.log.exportText() }
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .disabled(entries.isEmpty)
                }
            }
            .sheet(isPresented: Binding(
                get: { exportText != nil },
                set: { if !$0 { exportText = nil } }
            )) {
                if let exportText {
                    ShareLink(item: exportText) {
                        Label("Share the log", systemImage: "square.and.arrow.up")
                    }
                    .padding()
                    .presentationDetents([.height(160)])
                }
            }
            .task { await reload() }
            .refreshable { await reload() }
        }
    }

    private var list: some View {
        List {
            if !failedJobs.isEmpty {
                Section("Gave up") {
                    ForEach(failedJobs) { job in
                        failedRow(job)
                    }
                }
            }
            Section("Events") {
                ForEach(entries) { entry in
                    entryRow(entry)
                }
            }
        }
    }

    private func failedRow(_ job: ActionJob) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ActionRegistry.action(for: job.actionTypeID)?.displayName ?? job.actionTypeID)
                .font(.body)
            Text(job.lastError ?? "Failed")
                .font(.footnote)
                .foregroundStyle(.red)
            Button("Try again") {
                Task {
                    await FailedJobsModel(queue: environment.queue).requeue(job.id)
                    await environment.pipeline.drainQueue(deadline: Date().addingTimeInterval(20))
                    await reload()
                }
            }
            .buttonStyle(.bordered)
        }
        .accessibilityElement(children: .combine)
    }

    private func entryRow(_ entry: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.message)
                .font(.body)
                .foregroundStyle(entry.isError ? Color.red : Color.primary)
            Text(entry.date.formatted(date: .abbreviated, time: .standard))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.message), \(entry.date.formatted(date: .abbreviated, time: .shortened))")
    }

    private func reload() async {
        entries = await environment.log.entries()
        failedJobs = await FailedJobsModel(queue: environment.queue).failedJobs()
    }
}
