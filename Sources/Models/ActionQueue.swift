import Foundation

/// Ein Auftrag: diese Aktion, mit dieser Einstellung, fuer dieses Ereignis.
/// Wird geschrieben, bevor der Anker vorrueckt -- deshalb ueberlebt er den
/// Abschuss der App mitten im Weckfenster.
struct ActionJob: Codable, Sendable, Identifiable, Equatable {
    enum State: String, Codable, Sendable {
        case pending
        case running
        case done
        case failed
    }

    let id: UUID
    let sampleUUID: UUID
    let actionBindingID: UUID
    let actionTypeID: String
    let event: HealthSampleEvent
    let configData: Data
    var state: State
    var attempts: Int
    var nextAttemptAt: Date
    var lastError: String?

    /// Dasselbe Sample, dieselbe Bindung -- also derselbe Auftrag. Health
    /// kann denselben Eintrag zweimal zustellen; zweimal feuern darf er nicht.
    var dedupeKey: String { "\(sampleUUID.uuidString):\(actionBindingID.uuidString)" }

    /// Bleibt ueber alle Wiederholungen gleich, damit ein Empfaenger eine
    /// doppelte Zustellung selbst erkennen kann.
    var idempotencyKey: String { sampleUUID.uuidString }
}

/// Dauerhafte Warteschlange als JSONL: jede Zustandsaenderung ist eine neue
/// Zeile, beim Laden gewinnt die letzte Zeile je Auftrag. Anhaengen statt
/// ueberschreiben, damit ein Abschuss mitten im Schreiben hoechstens die
/// letzte Zeile beschaedigt. Vor der Rueckkehr aus enqueue wird fsync
/// gerufen: der Anker darf erst danach vorrruecken (Spec 7.2).
actor ActionQueue {
    /// Wartezeiten zwischen den Versuchen, in Sekunden.
    static let backoff: [TimeInterval] = [30, 120, 600, 3600, 21600]
    /// Nach so vielen Fehlversuchen gilt ein Auftrag als gescheitert und
    /// wartet auf eine Wiederholung von Hand.
    static let maxAttempts = 5

    private let fileURL: URL
    private let now: @Sendable () -> Date
    /// Reihenfolge des ersten Auftretens, damit all() stabil bleibt.
    private var order: [UUID] = []
    private var jobs: [UUID: ActionJob] = [:]
    private var didLoad = false

    init(fileURL: URL, now: @Sendable @escaping () -> Date = Date.init) {
        self.fileURL = fileURL
        self.now = now
    }

    func enqueue(_ newJobs: [ActionJob]) async throws -> Int {
        load()
        let known = Set(jobs.values.map(\.dedupeKey))
        var accepted: [ActionJob] = []
        var seen = known
        for job in newJobs where !seen.contains(job.dedupeKey) {
            seen.insert(job.dedupeKey)
            accepted.append(job)
        }
        guard !accepted.isEmpty else { return 0 }
        for job in accepted { remember(job) }
        try write(accepted)
        return accepted.count
    }

    /// Auftraege, die beim Abschuss noch liefen, sind nie fertig geworden.
    /// Sie gehen zurueck auf pending, ohne Versuch zu zaehlen -- gezaehlt
    /// werden Fehler, nicht Abschuesse.
    func reclaimRunning() async throws -> Int {
        load()
        let stuck = order.compactMap { jobs[$0] }.filter { $0.state == .running }
        guard !stuck.isEmpty else { return 0 }
        let reclaimed = stuck.map { job -> ActionJob in
            var copy = job
            copy.state = .pending
            copy.nextAttemptAt = now()
            return copy
        }
        for job in reclaimed { remember(job) }
        try write(reclaimed)
        return reclaimed.count
    }

    func nextDue() async -> ActionJob? {
        load()
        let current = now()
        return order
            .compactMap { jobs[$0] }
            .filter { $0.state == .pending && $0.nextAttemptAt <= current }
            .min { $0.nextAttemptAt < $1.nextAttemptAt }
    }

    func markRunning(_ id: UUID) async throws {
        try update(id) { $0.state = .running }
    }

    func markDone(_ id: UUID) async throws {
        try update(id) { $0.state = .done }
    }

    func markFailed(_ id: UUID, error: String) async throws {
        let moment = now()
        try update(id) { job in
            job.attempts += 1
            job.lastError = error
            if job.attempts >= Self.maxAttempts {
                job.state = .failed
            } else {
                job.state = .pending
                let step = min(job.attempts - 1, Self.backoff.count - 1)
                job.nextAttemptAt = moment.addingTimeInterval(Self.backoff[step])
            }
        }
    }

    /// Wiederholung von Hand aus der Oberflaeche: zurueck auf Anfang.
    func requeue(_ id: UUID) async throws {
        let moment = now()
        try update(id) { job in
            job.state = .pending
            job.attempts = 0
            job.lastError = nil
            job.nextAttemptAt = moment
        }
    }

    func all() async -> [ActionJob] {
        load()
        return order.compactMap { jobs[$0] }
    }

    // MARK: - Innenleben

    private func remember(_ job: ActionJob) {
        if jobs[job.id] == nil { order.append(job.id) }
        jobs[job.id] = job
    }

    private func update(_ id: UUID, _ change: (inout ActionJob) -> Void) throws {
        load()
        guard var job = jobs[id] else { return }
        change(&job)
        remember(job)
        try write([job])
    }

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: fileURL) else { return }
        for line in data.split(separator: UInt8(ascii: "\n")) where !line.isEmpty {
            // Eine abgeschnittene Zeile wird uebersprungen, der Rest bleibt gueltig.
            guard let job = try? decoder.decode(ActionJob.self, from: Data(line)) else { continue }
            remember(job)
        }
    }

    private func write(_ changed: [ActionJob]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = []
        var data = Data()
        for job in changed {
            data.append(try encoder.encode(job))
            data.append(UInt8(ascii: "\n"))
        }
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            guard FileManager.default.createFile(
                atPath: fileURL.path,
                contents: nil,
                attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
            ) else {
                throw CocoaError(.fileWriteUnknown)
            }
        }
        let handle = try FileHandle(forWritingTo: fileURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
        try handle.synchronize()
    }
}
