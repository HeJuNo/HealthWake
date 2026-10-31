import Foundation

/// Groesse der Werteablage und das Loeschen davon (Spec 14.3). Als eigenes
/// Modell, damit beides ohne Oberflaeche pruefbar ist.
struct StorageModel: Sendable {
    let samples: SampleStore

    func storedSizeText() async -> String {
        let bytes = (try? samples.totalByteCount()) ?? 0
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    func clearStoredSamples() async throws {
        try samples.removeAll()
    }
}

/// Gescheiterte Auftraege und die Wiederholung von Hand.
struct FailedJobsModel: Sendable {
    let queue: ActionQueue

    func failedJobs() async -> [ActionJob] {
        await queue.all().filter { $0.state == .failed }
    }

    func requeue(_ id: UUID) async {
        try? await queue.requeue(id)
    }
}
