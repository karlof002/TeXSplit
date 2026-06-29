import Foundation

enum LaTeXCompilerError: LocalizedError, Equatable {
    case compilerNotFound
    case couldNotWriteSource(String)
    case outputPDFMissing
    case compilationFailed(LaTeXError)

    var errorDescription: String? {
        switch self {
        case .compilerNotFound:
            "Eingebetteter LaTeX-Compiler fehlt."
        case .couldNotWriteSource(let message):
            "LaTeX-Quelldatei konnte nicht geschrieben werden: \(message)"
        case .outputPDFMissing:
            "Die Kompilierung wurde beendet, aber es wurde keine PDF-Datei erzeugt."
        case .compilationFailed(let error):
            error.localizedDescription
        }
    }
}

protocol LaTeXCompiling: Sendable {
    func compile(source: String) async throws -> CompilationResult
    func cancel()
}

struct CompilerPathResolver: Sendable {
    var fileExists: @Sendable (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
    var bundledResourceURL: @Sendable () -> URL? = { Bundle.main.resourceURL }

    static let fallbackPATH = [
        "/Library/TeX/texbin",
        "/usr/local/texlive/2026basic/bin/universal-darwin",
        "/usr/local/texlive/2026/bin/universal-darwin",
        "/usr/local/texlive/2025/bin/universal-darwin",
        "/usr/local/bin",
        "/opt/homebrew/bin",
        "/usr/bin",
        "/bin",
        "/usr/sbin",
        "/sbin"
    ].joined(separator: ":")

    func resolve() -> URL {
        if let bundledCompilerURL = bundledCompilerURL() {
            return bundledCompilerURL
        }

        let explicitPaths = [
            "/Library/TeX/texbin/pdflatex",
            "/usr/local/texlive/2026basic/bin/universal-darwin/pdflatex",
            "/usr/local/texlive/2026/bin/universal-darwin/pdflatex",
            "/usr/local/texlive/2025/bin/universal-darwin/pdflatex",
            "/usr/local/bin/pdflatex",
            "/opt/homebrew/bin/pdflatex",
            "/usr/texbin/pdflatex"
        ]

        if let path = explicitPaths.first(where: fileExists) {
            return URL(fileURLWithPath: path)
        }
        return URL(fileURLWithPath: "/usr/bin/env")
    }

    private func bundledCompilerURL() -> URL? {
        guard let resourceURL = bundledResourceURL() else { return nil }

        let relativePaths = [
            "TeXLive/bin/universal-darwin/pdflatex",
            "TeXLive/2026basic/bin/universal-darwin/pdflatex",
            "TeXLive/2026/bin/universal-darwin/pdflatex"
        ]

        for relativePath in relativePaths {
            let url = resourceURL.appendingPathComponent(relativePath)
            if fileExists(url.path) {
                return url
            }
        }

        return nil
    }
}

actor LaTeXCompiler: LaTeXCompiling {
    private let runner: ProcessRunning
    private let resolver: CompilerPathResolver
    private let parser: LaTeXErrorParser
    private let fileManager: FileManager
    private var lastTemporaryDirectory: URL?

    init(
        runner: ProcessRunning = DefaultProcessRunner(),
        resolver: CompilerPathResolver = CompilerPathResolver(),
        parser: LaTeXErrorParser = LaTeXErrorParser(),
        fileManager: FileManager = .default
    ) {
        self.runner = runner
        self.resolver = resolver
        self.parser = parser
        self.fileManager = fileManager
    }

    func compile(source: String) async throws -> CompilationResult {
        runner.terminateCurrentProcess()

        let compilerURL = resolver.resolve()

        let temporaryDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("TeXSplit-\(UUID().uuidString)", isDirectory: true)
        let sourceURL = temporaryDirectory.appendingPathComponent("document.tex")

        do {
            try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
            try source.write(to: sourceURL, atomically: true, encoding: .utf8)
        } catch {
            throw LaTeXCompilerError.couldNotWriteSource(error.localizedDescription)
        }

        let arguments: [String]
        if compilerURL.path == "/usr/bin/env" {
            arguments = ["pdflatex", "-interaction=nonstopmode", "-halt-on-error", "-output-directory=\(temporaryDirectory.path)", sourceURL.path]
        } else {
            arguments = ["-interaction=nonstopmode", "-halt-on-error", "-output-directory=\(temporaryDirectory.path)", sourceURL.path]
        }

        var environment = ProcessInfo.processInfo.environment
        if compilerURL.path == "/usr/bin/env" {
            environment["PATH"] = CompilerPathResolver.fallbackPATH
        } else {
            let compilerDirectory = compilerURL.deletingLastPathComponent().path
            environment["PATH"] = "\(compilerDirectory):\(CompilerPathResolver.fallbackPATH)"
        }

        let result = try await runner.run(
            executableURL: compilerURL,
            arguments: arguments,
            currentDirectoryURL: temporaryDirectory,
            environment: environment
        )
        let log = [result.standardOutput, result.standardError].filter { !$0.isEmpty }.joined(separator: "\n")

        if result.exitCode != 0 {
            if compilerURL.path == "/usr/bin/env", result.exitCode == 127 || log.localizedCaseInsensitiveContains("pdflatex") {
                throw LaTeXCompilerError.compilerNotFound
            }
            throw LaTeXCompilerError.compilationFailed(parser.parse(log))
        }

        let pdfURL = temporaryDirectory.appendingPathComponent("document.pdf")
        guard fileManager.fileExists(atPath: pdfURL.path) else {
            throw LaTeXCompilerError.outputPDFMissing
        }

        cleanupPreviousTemporaryDirectory(keeping: temporaryDirectory)
        lastTemporaryDirectory = temporaryDirectory
        return CompilationResult(pdfURL: pdfURL, log: log)
    }

    nonisolated func cancel() {
        runner.terminateCurrentProcess()
    }

    private func cleanupPreviousTemporaryDirectory(keeping directory: URL) {
        guard let lastTemporaryDirectory, lastTemporaryDirectory != directory else { return }
        try? fileManager.removeItem(at: lastTemporaryDirectory)
    }
}
