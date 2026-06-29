import Foundation
import XCTest
@testable import TeXSplit

@MainActor
final class WorkspaceViewModelTests: XCTestCase {
    private var settingsSuiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        settingsSuiteName = "TeXSplitTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: settingsSuiteName)
        defaults.removePersistentDomain(forName: settingsSuiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: settingsSuiteName)
        defaults = nil
        settingsSuiteName = nil
        super.tearDown()
    }

    func testCreatesInitialTab() {
        let workspace = makeWorkspace()

        XCTAssertEqual(workspace.tabs.count, 1)
        XCTAssertEqual(workspace.selectedTabID, workspace.tabs.first?.id)
        XCTAssertTrue(workspace.tabs[0].sourceCode.contains("\\documentclass{article}"))
    }

    func testCreatesNewTabAndSelectsIt() {
        let workspace = makeWorkspace()
        let firstID = workspace.selectedTabID

        workspace.createNewTab()

        XCTAssertEqual(workspace.tabs.count, 2)
        XCTAssertNotEqual(workspace.selectedTabID, firstID)
        XCTAssertEqual(workspace.selectedTab?.title, "Unbenannt 2")
    }

    func testSwitchesTabs() {
        let workspace = makeWorkspace()
        let first = workspace.tabs[0]
        workspace.createNewTab()

        workspace.selectTab(first)

        XCTAssertEqual(workspace.selectedTabID, first.id)
    }

    func testClosingLastCleanTabCreatesReplacementTab() async throws {
        let workspace = makeWorkspace()
        let originalID = try XCTUnwrap(workspace.selectedTabID)

        workspace.closeActiveTab()
        try await Task.sleep(nanoseconds: 80_000_000)

        XCTAssertEqual(workspace.tabs.count, 1)
        XCTAssertNotEqual(workspace.selectedTabID, originalID)
    }

    func testUnsavedDocumentShowsModifiedState() {
        let workspace = makeWorkspace()

        workspace.updateActiveSource("changed")

        XCTAssertTrue(workpaceSelectedTab(workspace).isModified)
        XCTAssertTrue(workpaceSelectedTab(workspace).displayTitle.hasSuffix(" •"))
    }

    func testSameFileIsNotOpenedTwice() {
        let workspace = makeWorkspace()
        let url = URL(fileURLWithPath: "/tmp/shared.tex")

        let first = workspace.addOrSelectDocument(url: url, text: "first")
        let second = workspace.addOrSelectDocument(url: url, text: "second")

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(workspace.tabs.filter { $0.fileURL?.standardizedFileURL == url.standardizedFileURL }.count, 1)
        XCTAssertEqual(workspace.selectedTabID, first.id)
    }

    func testDocumentTitleComesFromFileURL() {
        let url = URL(fileURLWithPath: "/tmp/example.tex")
        let tab = EditorTab(fileURL: url, sourceCode: "Hello", isModified: false, compiler: StubWorkspaceCompiler())

        XCTAssertEqual(tab.title, "example.tex")
        XCTAssertEqual(tab.pdfExportName, "example.pdf")
    }

    func testThemeLoadsFromSettings() {
        let settings = makeSettings()
        settings.editorThemeID = .monokai

        XCTAssertEqual(settings.selectedTheme.id, .monokai)
    }

    func testSettingsPersistValues() {
        let settings = makeSettings()
        settings.editorFontSize = 18
        settings.showsLineNumbers = false

        let reloaded = AppSettings(defaults: defaults)

        XCTAssertEqual(reloaded.editorFontSize, 18)
        XCTAssertFalse(reloaded.showsLineNumbers)
    }

    func testSessionEncodesAndDecodes() throws {
        let session = WorkspaceSession(openFilePaths: ["/tmp/a.tex", "/tmp/b.tex"], selectedFilePath: "/tmp/b.tex")
        let data = try JSONEncoder().encode(session)

        let decoded = try JSONDecoder().decode(WorkspaceSession.self, from: data)

        XCTAssertEqual(decoded, session)
    }

    func testLineNumberUpdatesForTextChanges() {
        let firstText = "one\ntwo" as NSString
        let updatedText = "zero\none\ntwo" as NSString

        XCTAssertEqual(LineNumberCalculator.lineNumber(forCharacterAt: firstText.length - 1, in: firstText), 2)
        XCTAssertEqual(LineNumberCalculator.lineNumber(forCharacterAt: updatedText.length - 1, in: updatedText), 3)
    }

    private func makeWorkspace() -> WorkspaceViewModel {
        WorkspaceViewModel(settings: makeSettings())
    }

    private func makeSettings() -> AppSettings {
        let settings = AppSettings(defaults: defaults)
        settings.restoreLastSession = false
        settings.confirmUnsavedClose = false
        settings.autoPreviewEnabledByDefault = false
        return settings
    }

    private func workpaceSelectedTab(_ workspace: WorkspaceViewModel) -> EditorTab {
        guard let tab = workspace.selectedTab else {
            XCTFail("Expected a selected tab")
            return EditorTab(compiler: StubWorkspaceCompiler())
        }
        return tab
    }
}

private actor StubWorkspaceCompiler: LaTeXCompiling {
    func compile(source: String) async throws -> CompilationResult {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("workspace-stub.pdf")
        try Data("%PDF-1.4\n".utf8).write(to: url)
        return CompilationResult(pdfURL: url, log: "ok")
    }

    nonisolated func cancel() { }
}
