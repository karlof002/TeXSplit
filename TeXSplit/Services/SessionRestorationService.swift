import Foundation

struct SessionRestorationService {
    private let fileManager: FileManager
    private let sessionURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        sessionURL = base
            .appendingPathComponent("TeXSplit", isDirectory: true)
            .appendingPathComponent("WorkspaceSession.json")
    }

    func load() -> WorkspaceSession? {
        guard let data = try? Data(contentsOf: sessionURL) else { return nil }
        return try? JSONDecoder().decode(WorkspaceSession.self, from: data)
    }

    func save(_ session: WorkspaceSession) {
        do {
            try fileManager.createDirectory(at: sessionURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(session)
            try data.write(to: sessionURL, options: .atomic)
        } catch {
            NSLog("Could not save TeXSplit session: \(error.localizedDescription)")
        }
    }
}
