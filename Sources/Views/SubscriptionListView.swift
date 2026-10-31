import SwiftUI

/// Die beobachteten Typen mit ihrem Zustand. Erste Antwort auf die Frage
/// "laeuft es?" -- deshalb steht der Zustand in jeder Zeile, nicht versteckt
/// in einem Detail.
struct SubscriptionListView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var subscriptions: [Subscription] = []
    @State private var isAddingType = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if subscriptions.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Types")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddingType = true
                    } label: {
                        Label("Add type", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingType) {
                AddTypeView { identifier in
                    await add(identifier)
                }
            }
            .alert("Could not add that type", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task { await reload() }
            .refreshable {
                await environment.refreshAllNow()
                await reload()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No types yet", systemImage: "heart.text.square")
        } description: {
            Text("Pick a health type and HealthWake will run your actions whenever a new entry arrives.")
        } actions: {
            Button("Add a type") { isAddingType = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private var list: some View {
        List {
            Section {
                ForEach(subscriptions) { subscription in
                    NavigationLink {
                        SubscriptionDetailView(subscription: subscription)
                    } label: {
                        row(subscription)
                    }
                }
                .onDelete(perform: delete)
            } footer: {
                Text("HealthWake watches these types in the background and runs the actions you configured.")
            }
        }
    }

    private func row(_ subscription: Subscription) -> some View {
        let status = SubscriptionStatus.of(subscription, now: Date())
        let name = HealthTypeCatalog.descriptor(for: subscription.typeIdentifier)?.displayName
            ?? subscription.typeIdentifier
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.body)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { subscription.isEnabled },
                    set: { newValue in Task { await setEnabled(subscription, newValue) } }
                ))
                .labelsHidden()
                .accessibilityLabel("Watch \(name)")
            }
            Text(status.label)
                .font(.footnote)
                .foregroundStyle(status.isAttention ? .orange : .secondary)
            if !subscription.actions.isEmpty {
                Text(actionSummary(subscription))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(status.label)")
    }

    private func actionSummary(_ subscription: Subscription) -> String {
        let names = subscription.actions
            .filter(\.isEnabled)
            .compactMap { ActionRegistry.action(for: $0.actionTypeID)?.displayName }
        return names.isEmpty ? "No actions yet" : names.joined(separator: ", ")
    }

    private func reload() async {
        subscriptions = await environment.subscriptions.all()
            .sorted { lhs, rhs in
                let left = HealthTypeCatalog.descriptor(for: lhs.typeIdentifier)?.displayName ?? lhs.typeIdentifier
                let right = HealthTypeCatalog.descriptor(for: rhs.typeIdentifier)?.displayName ?? rhs.typeIdentifier
                return left.localizedCaseInsensitiveCompare(right) == .orderedAscending
            }
    }

    private func add(_ identifier: String) async {
        do {
            _ = try await environment.addSubscription(typeIdentifier: identifier)
            await reload()
        } catch {
            errorMessage = String(describing: error)
        }
    }

    private func setEnabled(_ subscription: Subscription, _ isEnabled: Bool) async {
        var updated = subscription
        updated.isEnabled = isEnabled
        await environment.setSubscription(updated)
        await reload()
    }

    private func delete(at offsets: IndexSet) {
        let doomed = offsets.map { subscriptions[$0] }
        Task {
            for subscription in doomed {
                await environment.removeSubscription(id: subscription.id)
            }
            await reload()
        }
    }
}
