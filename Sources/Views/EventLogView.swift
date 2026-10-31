import SwiftUI

/// Das Protokoll: nach Tagen gruppiert, neuester Tag oben, und ganz oben die
/// Auftraege, die aufgegeben haben. Die einzige Stelle, an der man sieht,
/// warum etwas nicht passiert ist.
///
/// Werte stehen nicht als Satz, sondern in Spalten -- Name und App links,
/// Wert und Uhrzeit rechts. Eine Liste, die man senkrecht ueberfliegen
/// kann, ist der ganze Zweck des Protokolls.
struct EventLogView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var days: [LogDay] = []
    @State private var failedJobs: [ActionJob] = []
    @State private var exportText: String?
    @State private var isConfirmingClear = false

    var body: some View {
        NavigationStack {
            Group {
                if days.isEmpty && failedJobs.isEmpty {
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
                    Menu {
                        Button {
                            Task { exportText = await environment.log.exportText() }
                        } label: {
                            Label("Share the log", systemImage: "square.and.arrow.up")
                        }
                        Button(role: .destructive) {
                            isConfirmingClear = true
                        } label: {
                            Label("Clear the log", systemImage: "trash")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                    .disabled(days.isEmpty)
                }
            }
            .confirmationDialog(
                "Delete every entry in the log?",
                isPresented: $isConfirmingClear,
                titleVisibility: .visible
            ) {
                Button("Clear the log", role: .destructive) {
                    Task {
                        try? await environment.log.removeAll()
                        await reload()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This only removes what HealthWake recorded. Your entries in Health and the types you watch stay as they are.")
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
            ForEach(days) { day in
                Section(day.title) {
                    ForEach(day.rows) { row in
                        logRow(row)
                    }
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

    @ViewBuilder
    private func logRow(_ row: LogRow) -> some View {
        switch row.content {
        case let .measurement(typeName, sourceName, value):
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(typeName)
                    Text(sourceName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(value)
                        .fontWeight(.medium)
                        .monospacedDigit()
                    Text(time(row.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(typeName), \(value), from \(sourceName), \(time(row.date))")
        case let .message(text):
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: symbol(for: row.kind))
                    .font(.footnote)
                    .foregroundStyle(tint(for: row.kind))
                    .frame(width: 16)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(text)
                        .foregroundStyle(row.isError ? Color.red : Color.primary)
                    Text(time(row.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(text), \(time(row.date))")
        }
    }

    private func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .standard)
    }

    private func symbol(for kind: LogEntry.Kind) -> String {
        switch kind {
        case .sampleReceived: "heart.text.square"
        case .actionSucceeded: "checkmark.circle.fill"
        case .actionFailed: "exclamationmark.triangle.fill"
        case .sampleDeleted: "trash"
        case .deliveryEnabled: "bell.fill"
        case .deliveryDisabled: "bell.slash.fill"
        case .storeUnavailable: "lock.fill"
        }
    }

    private func tint(for kind: LogEntry.Kind) -> Color {
        switch kind {
        case .actionSucceeded: .green
        case .actionFailed, .storeUnavailable: .red
        case .deliveryDisabled: .orange
        default: .secondary
        }
    }

    private func reload() async {
        days = LogListModel.days(for: await environment.log.entries())
        failedJobs = await FailedJobsModel(queue: environment.queue).failedJobs()
    }
}
