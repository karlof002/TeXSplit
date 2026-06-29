import Foundation

struct ProcessRunResult: Equatable {
    let exitCode: Int32
    let standardOutput: String
    let standardError: String
}

protocol ProcessRunning: Sendable {
    func run(
        executableURL: URL,
        arguments: [String],
        currentDirectoryURL: URL?,
        environment: [String: String]?
    ) async throws -> ProcessRunResult
    func terminateCurrentProcess()
}

enum ProcessRunnerError: LocalizedError {
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case .launchFailed(let message): "Prozess konnte nicht gestartet werden: \(message)"
        }
    }
}

final class DefaultProcessRunner: ProcessRunning, @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?

    func run(
        executableURL: URL,
        arguments: [String],
        currentDirectoryURL: URL?,
        environment: [String: String]? = nil
    ) async throws -> ProcessRunResult {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let process = Process()
                process.executableURL = executableURL
                process.arguments = arguments
                process.currentDirectoryURL = currentDirectoryURL
                process.environment = environment

                let stdout = Pipe()
                let stderr = Pipe()
                process.standardOutput = stdout
                process.standardError = stderr

                process.terminationHandler = { [weak self] process in
                    let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
                    let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
                    self?.clear(process)
                    continuation.resume(returning: ProcessRunResult(
                        exitCode: process.terminationStatus,
                        standardOutput: String(decoding: outputData, as: UTF8.self),
                        standardError: String(decoding: errorData, as: UTF8.self)
                    ))
                }

                do {
                    lock.lock()
                    self.process = process
                    lock.unlock()
                    try process.run()
                } catch {
                    clear(process)
                    continuation.resume(throwing: ProcessRunnerError.launchFailed(error.localizedDescription))
                }
            }
        } onCancel: {
            terminateCurrentProcess()
        }
    }

    func terminateCurrentProcess() {
        lock.lock()
        let process = process
        lock.unlock()
        if process?.isRunning == true {
            process?.terminate()
        }
    }

    private func clear(_ terminatedProcess: Process) {
        lock.lock()
        if process === terminatedProcess {
            process = nil
        }
        lock.unlock()
    }
}
