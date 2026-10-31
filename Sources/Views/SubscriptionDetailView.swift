import SwiftUI

/// Ein Abonnement im Detail: Zustand, Filter, Aktionen.
struct SubscriptionDetailView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var subscription: Subscription
    @State private var notificationsDenied = false

    init(subscription: Subscription) {
        _subscription = State(initialValue: subscription)
    }

    private var descriptor: HealthTypeDescriptor? {
        HealthTypeCatalog.descriptor(for: subscription.typeIdentifier)
    }

    var body: some View {
        Form {
            statusSection
            FilterEditor(
                filter: $subscription.filter,
                isQuantity: descriptor?.kind != .category
            )
            actionsSection
        }
        .navigationTitle(descriptor?.displayName ?? subscription.typeIdentifier)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: subscription) { _, updated in
            Task { await environment.setSubscription(updated) }
        }
        .alert("Notifications are switched off", isPresented: $notificationsDenied) {
            Button("OK") {}
        } message: {
            Text("HealthWake may not show notifications. You can turn them on in the Settings app.")
        }
    }

    private var statusSection: some View {
        Section {
            Toggle("Watch this type", isOn: $subscription.isEnabled)
            LabeledContent("Status", value: SubscriptionStatus.of(subscription, now: Date()).label)
            if let unit = descriptor?.defaultUnitString {
                LabeledContent("Unit", value: unit)
            }
        } footer: {
            Text("HealthWake cannot tell whether Health granted read access. If nothing arrives, check the Health app under Sources.")
        }
    }

    private var actionsSection: some View {
        Section {
            ForEach(subscription.actions) { binding in
                actionRow(binding)
            }
            .onDelete { offsets in
                subscription.actions.remove(atOffsets: offsets)
            }
            Menu {
                ForEach(ActionRegistry.all) { action in
                    Button(action.displayName) {
                        Task { await addAction(action) }
                    }
                }
            } label: {
                Label("Add action", systemImage: "plus")
            }
        } header: {
            Text("Actions")
        } footer: {
            Text(subscription.actions.isEmpty
                 ? "Without an action HealthWake only records the entries."
                 : "Every action runs once per new entry that passes the filter.")
        }
    }

    private func actionRow(_ binding: ActionBinding) -> some View {
        let action = ActionRegistry.action(for: binding.actionTypeID)
        return NavigationLink {
            configView(for: binding, action: action)
        } label: {
            HStack {
                Text(action?.displayName ?? binding.actionTypeID)
                Spacer()
                if !binding.isEnabled {
                    Text("Off").foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func configView(for binding: ActionBinding, action: AnyHealthAction?) -> some View {
        if let action {
            action.makeConfigView(binding.configData) { newData in
                guard let index = subscription.actions.firstIndex(where: { $0.id == binding.id }) else { return }
                subscription.actions[index].configData = newData
            }
        } else {
            ContentUnavailableView(
                "Unknown action",
                systemImage: "questionmark",
                description: Text("This action is not part of this version of HealthWake.")
            )
        }
    }

    private func addAction(_ action: AnyHealthAction) async {
        if action.typeID == NotificationAction.typeID {
            // Erst hier fragen: eine Mitteilungsaktion ist der Anlass.
            let granted = await NotificationAuthorization.requestIfNeeded()
            notificationsDenied = !granted
        }
        guard let data = try? action.defaultConfigData() else { return }
        subscription.actions.append(ActionBinding(
            id: UUID(),
            actionTypeID: action.typeID,
            configData: data,
            isEnabled: true
        ))
    }
}
