import Testing
import UserNotifications
@testable import HealthWake

/// Ohne Delegaten verwirft iOS jede Mitteilung, die eintrifft, waehrend die
/// App im Vordergrund ist -- lautlos, ohne Fehler, und `add` meldet trotzdem
/// Erfolg. Die App holt beim Wechsel in den Vordergrund nach (scenePhase
/// .active), also entsteht die Mitteilung genau dort.
@Suite struct ForegroundNotificationTests {
    @Test func mitteilungWirdAuchImVordergrundGezeigt() {
        let options = ForegroundNotificationPresenter.presentationOptions
        #expect(options.contains(.banner))
        #expect(options.contains(.sound))
        #expect(options.contains(.list))
    }

    @MainActor
    @Test func anmeldenSetztDenDelegatenDesZentrums() {
        ForegroundNotificationPresenter.install()
        #expect(UNUserNotificationCenter.current().delegate === ForegroundNotificationPresenter.shared)
    }
}
