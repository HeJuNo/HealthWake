import Foundation
import HealthKit
import UserNotifications

/// Was die App ueber ihren eigenen Zugang sagen kann. Wenig -- aber das
/// Wenige gehoert in die Einstellungen, sonst raet der Benutzer (Spec 8).
struct DiagnosisModel: Sendable {
    struct Row: Sendable, Equatable, Identifiable {
        var id: String { typeIdentifier }
        let typeIdentifier: String
        let name: String
        /// true heisst: Health wuerde noch fragen. Mehr verraet HealthKit
        /// nicht -- ob gelesen werden darf, bleibt geheim (Spec 5.7).
        let wouldPrompt: Bool
    }

    let store: any HealthStoring
    let subscriptions: SubscriptionStore

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func rows() async -> [Row] {
        var rows: [Row] = []
        for subscription in await subscriptions.all() {
            let name = HealthTypeCatalog.descriptor(for: subscription.typeIdentifier)?.displayName
                ?? subscription.typeIdentifier
            let prompt = (try? await store.wouldPrompt(toRead: [subscription.typeIdentifier])) ?? true
            rows.append(Row(typeIdentifier: subscription.typeIdentifier, name: name, wouldPrompt: prompt))
        }
        return rows.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func notificationStatusText() async -> String {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return "Allowed"
        case .denied: return "Switched off"
        case .notDetermined: return "Not asked yet"
        @unknown default: return "Unknown"
        }
    }
}
