import SwiftUI

/// Die drei Bedingungen aus Spec 6, als Formular. Alle drei gelten
/// gleichzeitig; was leer bleibt, filtert nicht.
struct FilterEditor: View {
    @Binding var filter: SubscriptionFilter
    let isQuantity: Bool

    private enum Kind: String, CaseIterable, Identifiable {
        case none, above, below, outside
        var id: String { rawValue }
        var label: String {
            switch self {
            case .none: "Every entry"
            case .above: "Above"
            case .below: "Below"
            case .outside: "Outside a range"
            }
        }
    }

    @State private var kind: Kind = .none
    @State private var lower = ""
    @State private var upper = ""
    @State private var intervalMinutes = ""
    @State private var newSource = ""

    var body: some View {
        Section {
            if isQuantity {
                Picker("Trigger on", selection: $kind) {
                    ForEach(Kind.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                if kind != .none {
                    TextField(kind == .outside ? "Lower bound" : "Value", text: $lower)
                        .keyboardType(.decimalPad)
                }
                if kind == .outside {
                    TextField("Upper bound", text: $upper)
                        .keyboardType(.decimalPad)
                }
            } else {
                Text("Category entries have no numeric value, so every entry triggers.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            TextField("Minimum minutes between triggers", text: $intervalMinutes)
                .keyboardType(.numberPad)
        } header: {
            Text("When to trigger")
        } footer: {
            Text("Leave the minimum empty to react to every entry.")
        }

        Section {
            ForEach(filter.allowedSourceNames, id: \.self) { name in
                Text(name)
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            filter.allowedSourceNames.removeAll { $0 == name }
                        }
                    }
            }
            HStack {
                TextField("Source name, exactly as in Health", text: $newSource)
                Button("Add") {
                    let name = newSource.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty, !filter.allowedSourceNames.contains(name) else { return }
                    filter.allowedSourceNames.append(name)
                    newSource = ""
                }
                .disabled(newSource.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        } header: {
            Text("Sources")
        } footer: {
            Text(filter.allowedSourceNames.isEmpty
                 ? "Empty means every app and device that writes this type."
                 : "Only these sources trigger actions.")
        }
        .onAppear(perform: load)
        .onChange(of: kind) { _, _ in store() }
        .onChange(of: lower) { _, _ in store() }
        .onChange(of: upper) { _, _ in store() }
        .onChange(of: intervalMinutes) { _, _ in store() }
    }

    private func load() {
        switch filter.threshold {
        case .none:
            kind = .none
        case .above(let value):
            kind = .above
            lower = format(value)
        case .below(let value):
            kind = .below
            lower = format(value)
        case .outside(let low, let high):
            kind = .outside
            lower = format(low)
            upper = format(high)
        }
        if let interval = filter.minimumInterval {
            intervalMinutes = String(Int(interval / 60))
        }
    }

    private func store() {
        let low = Double(lower.replacingOccurrences(of: ",", with: "."))
        let high = Double(upper.replacingOccurrences(of: ",", with: "."))
        switch kind {
        case .none:
            filter.threshold = .none
        case .above:
            filter.threshold = low.map { .above($0) } ?? .none
        case .below:
            filter.threshold = low.map { .below($0) } ?? .none
        case .outside:
            if let low, let high {
                filter.threshold = .outside(lower: min(low, high), upper: max(low, high))
            } else {
                filter.threshold = .none
            }
        }
        let minutes = Double(intervalMinutes)
        filter.minimumInterval = (minutes.map { $0 * 60 }).flatMap { $0 > 0 ? $0 : nil }
    }

    private func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }
}
