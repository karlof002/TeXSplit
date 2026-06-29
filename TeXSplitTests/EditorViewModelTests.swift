import Foundation
import XCTest
@testable import TeXSplit

@MainActor
final class EditorViewModelTests: XCTestCase {
    func testDocumentStatusChangesWhenTextChanges() {
        let viewModel = EditorViewModel(compiler: StubCompiler(), fileService: FileService())

        viewModel.updateText("changed")

        XCTAssertEqual(viewModel.document.text, "changed")
        XCTAssertTrue(viewModel.document.hasUnsavedChanges)
    }

    func testAutoPreviewDebouncesRapidChanges() async throws {
        let compiler = StubCompiler()
        let viewModel = EditorViewModel(compiler: compiler, fileService: FileService())

        viewModel.scheduleAutoCompile(delayNanoseconds: 80_000_000)
        try await Task.sleep(nanoseconds: 20_000_000)
        viewModel.scheduleAutoCompile(delayNanoseconds: 80_000_000)
        try await Task.sleep(nanoseconds: 180_000_000)
        let compileCount = await compiler.recordedCompileCount()

        XCTAssertEqual(compileCount, 1)
    }
}

actor StubCompiler: LaTeXCompiling {
    private(set) var compileCount = 0

    func compile(source: String) async throws -> CompilationResult {
        compileCount += 1
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("stub.pdf")
        try Data("%PDF-1.4\n".utf8).write(to: url)
        return CompilationResult(pdfURL: url, log: "stub")
    }

    nonisolated func cancel() { }

    func recordedCompileCount() -> Int {
        compileCount
    }
}
