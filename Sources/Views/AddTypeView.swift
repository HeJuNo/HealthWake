import SwiftUI

/// Typauswahl: der ganze Katalog, durchsuchbar, nach Gruppen sortiert.
/// Vor dem Systemdialog erklaert ein Satz, wozu HealthWake den Typ liest --
/// der Dialog selbst laesst sich nur einmal zeigen.
struct AddTypeView: View {
    let onAdd: (String) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var pending: HealthTypeDescriptor?

    private var groups: [(HealthTypeGroup, [HealthTypeDescriptor])] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return HealthTypeCatalog.grouped()
        }
        let matches = Set(HealthTypeCatalog.search(query).map(\.identifier))
        return HealthTypeCatalog.grouped().compactMap { group, members in
            let kept = members.filter { matches.contains($0.identifier) }
            return kept.isEmpty ? nil : (group, kept)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups, id: \.0) { group, members in
                    Section(group.displayName) {
                        ForEach(members) { descriptor in
                            Button {
                                pending = descriptor
                            } label: {
                                row(descriptor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $query, prompt: "Search health types")
            .navigationTitle("Add a type")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert(
                pending.map { "Watch \($0.displayName)?" } ?? "",
                isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })
            ) {
                Button("Cancel", role: .cancel) { pending = nil }
                Button("Continue") {
                    guard let descriptor = pending else { return }
                    pending = nil
                    Task {
                        await onAdd(descriptor.identifier)
                        dismiss()
                    }
                }
            } message: {
                Text("HealthWake will ask Health for read access to this type, and will run your actions whenever a new entry arrives. Watching starts now; earlier entries are left alone.")
            }
        }
    }

    private func row(_ descriptor: HealthTypeDescriptor) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(descriptor.displayName)
                .foregroundStyle(.primary)
            Text(descriptor.kind == .quantity
                 ? (descriptor.defaultUnitString ?? "measurement")
                 : "category")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(descriptor.displayName)
        .accessibilityHint("Adds this health type")
    }
}
