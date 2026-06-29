import Foundation
import XCTest
@testable import TeXSplit

final class LaTeXCompilerTests: XCTestCase {
    func testCreatesTemporarySourceFileAndReturnsGeneratedPDF() async throws {
        let runner = RecordingProcessRunner(exitCode: 0, output: "ok", shouldCreatePDF: true)
        let compiler = LaTeXCompiler(
            runner: runner,
            resolver: CompilerPathResolver(
                fileExists: { path in path == "/Library/TeX/texbin/pdflatex" },
                bundledResourceURL: { nil }
            )
        )

        let result = try await compiler.compile(source: "\\documentclass{article}\\begin{document}Hi\\end{document}")

        XCTAssertTrue(FileManager.default.fileExists(atPath: result.pdfURL.path))
        XCTAssertTrue(runner.arguments.contains { $0.hasPrefix("-output-directory=") })
        XCTAssertTrue(runner.arguments.contains("-interaction=nonstopmode"))
        XCTAssertTrue(runner.arguments.contains("-halt-on-error"))
        XCTAssertEqual(result.log, "ok")
    }

    func testThrowsReadableErrorWhenCompilerIsMissing() async {
        let compiler = LaTeXCompiler(
            runner: RecordingProcessRunner(exitCode: 127, output: "env: pdflatex: No such file or directory", shouldCreatePDF: false),
            resolver: CompilerPathResolver(fileExists: { _ in false }, bundledResourceURL: { nil })
        )

        do {
            _ = try await compiler.compile(source: "test")
            XCTFail("Expected compilerNotFound")
        } catch let error as LaTeXCompilerError {
            XCTAssertEqual(error, .compilerNotFound)
            XCTAssertEqual(error.localizedDescription, "Eingebetteter LaTeX-Compiler fehlt.")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

final class RecordingProcessRunner: ProcessRunning, @unchecked Sendable {
    private let exitCode: Int32
    private let output: String
    private let shouldCreatePDF: Bool
    private(set) var arguments: [String] = []

    init(exitCode: Int32, output: String, shouldCreatePDF: Bool) {
        self.exitCode = exitCode
        self.output = output
        self.shouldCreatePDF = shouldCreatePDF
    }

    func run(
        executableURL: URL,
        arguments: [String],
        currentDirectoryURL: URL?,
        environment: [String: String]?
    ) async throws -> ProcessRunResult {
        self.arguments = arguments
        XCTAssertTrue(arguments.contains { $0.hasSuffix("document.tex") })
        if shouldCreatePDF, let currentDirectoryURL {
            let pdfURL = currentDirectoryURL.appendingPathComponent("document.pdf")
            try Data("%PDF-1.4\n".utf8).write(to: pdfURL)
        }
        return ProcessRunResult(exitCode: exitCode, standardOutput: output, standardError: "")
    }

    func terminateCurrentProcess() { }
}
