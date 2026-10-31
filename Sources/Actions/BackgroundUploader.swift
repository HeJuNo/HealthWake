import Foundation

/// Laedt den Rumpf einer HTTP-Aktion mit einer Hintergrund-URLSession hoch.
///
/// Belegt und nicht verhandelbar: eine Hintergrundsitzung kennt nur Upload-
/// und Download-Aufgaben, braucht einen Delegaten und ignoriert Completion-
/// Handler. Ein dataTask laeuft dort gar nicht. Deshalb wandert der Rumpf in
/// eine Datei und geht als uploadTask(with:fromFile:) hinaus.
///
/// Kein Aktor, obwohl es einer sein sollte: ein Aktor kann nicht von NSObject
/// erben, und URLSession verlangt einen NSObject-Delegaten. Stattdessen eine
/// Klasse mit einer Sperre um den veraenderlichen Zustand.
final class BackgroundUploader: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    static let sessionIdentifier = "com.healthwake.upload"
    static let shared = BackgroundUploader()

    private let lock = NSLock()
    private var waiting: [Int: CheckedContinuation<Void, Error>] = [:]
    private var bodyFiles: [Int: URL] = [:]
    private var finishedEvents: (() -> Void)?

    private var sessionStorage: URLSession?

    /// Nicht als "lazy var": das ist auf einer Klasse nicht threadsicher,
    /// und zwei gleichzeitige Aufrufe wuerden zwei Sitzungen mit demselben
    /// Bezeichner erzeugen -- laut Apple ein Fehler.
    private var session: URLSession {
        lock.lock()
        defer { lock.unlock() }
        if let sessionStorage { return sessionStorage }
        let configuration = URLSessionConfiguration.background(withIdentifier: Self.sessionIdentifier)
        // Nicht zeitkritisch, aber auch nicht beliebig spaet: das System soll
        // selbst entscheiden, nur eben nicht auf WLAN und Ladekabel warten.
        configuration.isDiscretionary = false
        configuration.sessionSendsLaunchEvents = true
        configuration.timeoutIntervalForRequest = 60
        // Ein haengender Upload darf das Weckfenster nicht auffressen.
        configuration.timeoutIntervalForResource = 300
        let created = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        sessionStorage = created
        return created
    }

    /// Schickt die Anfrage los und wartet auf das Ergebnis.
    ///
    /// Wird die App vorher abgeschossen, laeuft der Upload weiter, aber auf
    /// dieses await antwortet niemand mehr. Genau dafuer gibt es die
    /// dauerhafte Warteschlange: der Auftrag bleibt "running" und wird beim
    /// naechsten Start zurueckgeholt.
    func send(_ request: URLRequest, body: Data, jobID: UUID) async throws {
        // Eigener Name je Sendung: zwei Bindungen fuer denselben Wert
        // wuerden sich sonst dieselbe Datei teilen.
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("healthwake-upload-\(jobID.uuidString)-\(UUID().uuidString).tmp")
        try body.write(to: fileURL, options: .atomic)

        try await withCheckedThrowingContinuation { (continuation: CheckedThrowingContinuation) in
            let task = session.uploadTask(with: request, fromFile: fileURL)
            lock.lock()
            waiting[task.taskIdentifier] = continuation
            bodyFiles[task.taskIdentifier] = fileURL
            lock.unlock()
            task.resume()
        }
    }

    /// Wird aus dem AppDelegate gerufen, wenn das System die App nur wegen
    /// fertiger Uploads geweckt hat.
    func handleEvents(completionHandler: @escaping () -> Void) {
        lock.lock()
        finishedEvents = completionHandler
        lock.unlock()
        // Zugriff auf session, damit die Sitzung wirklich wieder entsteht --
        // ohne sie bleiben die Delegatenaufrufe aus.
        _ = session
    }

    // MARK: - URLSessionDelegate

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        let continuation = waiting.removeValue(forKey: task.taskIdentifier)
        let fileURL = bodyFiles.removeValue(forKey: task.taskIdentifier)
        lock.unlock()

        if let fileURL { try? FileManager.default.removeItem(at: fileURL) }
        guard let continuation else { return }

        if let error {
            continuation.resume(throwing: error)
            return
        }
        let status = (task.response as? HTTPURLResponse)?.statusCode ?? 0
        if (200..<300).contains(status) {
            continuation.resume()
        } else {
            continuation.resume(throwing: HTTPActionError.status(status))
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        lock.lock()
        let completion = finishedEvents
        finishedEvents = nil
        lock.unlock()
        // Muss auf dem Hauptfaden laufen, so verlangt es UIKit.
        DispatchQueue.main.async { completion?() }
    }
}

private typealias CheckedThrowingContinuation = CheckedContinuation<Void, Error>
