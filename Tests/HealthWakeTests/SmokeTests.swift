import Foundation
import Testing
@testable import HealthWake

@Test func testTargetRuns() {
    // Prueft nur, dass das Testziel gegen das App-Modul geladen wird.
    // Wird durch echte Tests ersetzt, sobald es Typen zu testen gibt.
    #expect(Bundle(for: HealthWakeMarker.self).bundleIdentifier?.isEmpty == false)
}
