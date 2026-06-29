import AppKit
import Foundation

@MainActor
final class WorkspaceViewModel: ObservableObject {
    @Published var tabs: [EditorTab] = []
    @Published var selectedTabID: UUID?
    @Published var isShowingCompilerLog = false

    let settings: AppSettings
    private let fileService: FileService
    private let sessionService: SessionRestorationService
    private var untitledCounter = 1

    init(
        settings: AppSettings? = nil,
        fileService: FileService? = nil,
        sessionService: SessionRestorationService = SessionRestorationService()
    ) {
        self.settings = settings ?? AppSettings.shared
        self.fileService = fileService ?? FileService()
        self.sessionService = sessionService

        if self.settings.restoreLastSession, restoreSession() {
            return
        }
        createNewTab()
    }

    var selectedTab: EditorTab? {
        guard let selectedTabID else { return tabs.first }
        return tabs.first { $0.id == selectedTabID } ?? tabs.first
    }

    var canSave: Bool { selectedTab != nil }
    var canExportPDF: Bool { selectedTab?.generatedPDFURL != nil }
    var canShowCompilerOutput: Bool { selectedTab?.compilerOutput.isEmpty == false }

    func createNewTab() {
        let title = "Unbenannt \(untitledCounter)"
        untitledCounter += 1
        let source = settings.useDefaultTemplate ? TeXDocument.defaultContent : ""
        let tab = EditorTab(title: title, sourceCode: source, isAutoPreviewEnabled: settings.autoPreviewEnabledByDefault)
        tabs.append(tab)
        selectedTabID = tab.id
        saveSession()
    }

    func selectTab(_ tab: EditorTab) {
        selectedTabID = tab.id
        saveSession()
    }

    func updateActiveSource(_ text: String) {
        selectedTab?.updateSource(text, settings: settings)
    }

    func updateActiveCursor(line: Int, column: Int) {
        selectedTab?.updateCursor(line: line, column: column)
    }

    func openDocument() async {
        do {
            guard let loaded = try await fileService.openTeXFile() else { return }
            addOrSelectDocument(url: loaded.url, text: loaded.text)
        } catch {
            showError(error.localizedDescription)
        }
    }

    @discardableResult
    func addOrSelectDocument(url: URL, text: String) -> EditorTab {
        if let existing = tabs.first(where: { $0.fileURL?.standardizedFileURL == url.standardizedFileURL }) {
            selectedTabID = existing.id
            saveSession()
            return existing
        }
        let tab = EditorTab(
            fileURL: url,
            sourceCode: text,
            isModified: false,
            isAutoPreviewEnabled: settings.autoPreviewEnabledByDefault
        )
        tabs.append(tab)
        selectedTabID = tab.id
        tab.scheduleAutoCompile(settings: settings)
        saveSession()
        return tab
    }

    func saveActiveTab() async {
        guard let tab = selectedTab else { return }
        await save(tab: tab)
    }

    func saveActiveTabAs() async {
        guard let tab = selectedTab else { return }
        await saveAs(tab: tab)
    }

    @discardableResult
    func save(tab: EditorTab) async -> Bool {
        if let url = tab.fileURL {
            do {
                try fileService.save(text: tab.sourceCode, to: url)
                tab.markSaved(url: url)
                saveSession()
                return true
            } catch {
                showError(error.localizedDescription, in: tab)
                return false
            }
        }
        return await saveAs(tab: tab)
    }

    @discardableResult
    func saveAs(tab: EditorTab) async -> Bool {
        guard let url = fileService.chooseSaveURL(defaultName: tab.title.hasSuffix(".tex") ? tab.title : "\(tab.title).tex") else {
            return false
        }
        if let duplicate = tabs.first(where: { $0.id != tab.id && $0.fileURL?.standardizedFileURL == url.standardizedFileURL }) {
            selectedTabID = duplicate.id
            return false
        }
        do {
            try fileService.save(text: tab.sourceCode, to: url)
            tab.markSaved(url: url)
            saveSession()
            return true
        } catch {
            showError(error.localizedDescription, in: tab)
            return false
        }
    }

    func closeActiveTab() {
        guard let tab = selectedTab else { return }
        close(tab: tab)
    }

    func close(tab: EditorTab) {
        Task { @MainActor in
            guard await confirmClose(tab: tab) else { return }
            tab.cancelCompile()
            if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
                tabs.remove(at: index)
                selectedTabID = tabs[safe: min(index, tabs.count - 1)]?.id
            }
            if tabs.isEmpty {
                createNewTab()
            } else {
                saveSession()
            }
        }
    }

    func closeCurrentWindowAllowed() -> Bool {
        let dirty = tabs.contains { $0.isModified }
        if dirty {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = "Ungespeicherte Änderungen"
            alert.informativeText = "Einige Tabs enthalten ungespeicherte Änderungen."
            alert.addButton(withTitle: "Abbrechen")
            alert.addButton(withTitle: "Trotzdem schließen")
            return alert.runModal() == .alertSecondButtonReturn
        }
        return true
    }

    func compileActiveTab() async {
        await selectedTab?.compile()
    }

    func toggleAutoPreviewForActiveTab() {
        guard let tab = selectedTab else { return }
        tab.isAutoPreviewEnabled.toggle()
        if tab.isAutoPreviewEnabled {
            tab.scheduleAutoCompile(settings: settings)
        }
    }

    func exportActivePDF() async {
        guard let tab = selectedTab else { return }
        if tab.generatedPDFURL == nil {
            await tab.compile()
        }
        guard let pdfURL = tab.generatedPDFURL,
              let destination = fileService.choosePDFExportURL(defaultName: tab.pdfExportName) else {
            return
        }
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: pdfURL, to: destination)
        } catch {
            showError(error.localizedDescription, in: tab)
        }
    }

    func zoomInPDF() {
        guard let tab = selectedTab else { return }
        tab.fitPDFToWidth = false
        tab.pdfScaleFactor = tab.pdfScaleFactor == 0 ? 1.2 : min(tab.pdfScaleFactor * 1.2, 5)
    }

    func zoomOutPDF() {
        guard let tab = selectedTab else { return }
        tab.fitPDFToWidth = false
        tab.pdfScaleFactor = tab.pdfScaleFactor == 0 ? 0.8 : max(tab.pdfScaleFactor / 1.2, 0.2)
    }

    func fitPDFWidth() {
        selectedTab?.fitPDFToWidth = true
    }

    func showNextTab() {
        guard let current = selectedTab, let index = tabs.firstIndex(where: { $0.id == current.id }), !tabs.isEmpty else { return }
        selectedTabID = tabs[(index + 1) % tabs.count].id
        saveSession()
    }

    func showPreviousTab() {
        guard let current = selectedTab, let index = tabs.firstIndex(where: { $0.id == current.id }), !tabs.isEmpty else { return }
        selectedTabID = tabs[(index - 1 + tabs.count) % tabs.count].id
        saveSession()
    }

    func toggleLineNumbers() {
        settings.showsLineNumbers.toggle()
    }

    func toggleLineWrapping() {
        settings.wrapsLines.toggle()
    }

    func saveSession() {
        guard settings.restoreLastSession else { return }
        let filePaths = tabs.compactMap { $0.fileURL?.path }
        let selectedPath = selectedTab?.fileURL?.path
        sessionService.save(WorkspaceSession(openFilePaths: filePaths, selectedFilePath: selectedPath))
    }

    private func restoreSession() -> Bool {
        guard let session = sessionService.load(), !session.openFilePaths.isEmpty else { return false }
        let restoredTabs = session.openFilePaths.compactMap { path -> EditorTab? in
            let url = URL(fileURLWithPath: path)
            guard FileManager.default.fileExists(atPath: url.path),
                  let text = try? String(contentsOf: url, encoding: .utf8) else {
                return nil
            }
            return EditorTab(fileURL: url, sourceCode: text, isModified: false, isAutoPreviewEnabled: settings.autoPreviewEnabledByDefault)
        }
        guard !restoredTabs.isEmpty else { return false }
        tabs = restoredTabs
        if let selected = session.selectedFilePath,
           let tab = tabs.first(where: { $0.fileURL?.path == selected }) {
            selectedTabID = tab.id
        } else {
            selectedTabID = tabs.first?.id
        }
        return true
    }

    private func confirmClose(tab: EditorTab) async -> Bool {
        guard settings.confirmUnsavedClose, tab.isModified else { return true }
        let alert = NSAlert()
        alert.messageText = "Änderungen an „\(tab.title)“ sichern?"
        alert.informativeText = "Wenn du nicht sicherst, gehen die Änderungen in diesem Tab verloren."
        alert.addButton(withTitle: "Speichern")
        alert.addButton(withTitle: "Nicht speichern")
        alert.addButton(withTitle: "Abbrechen")
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return await save(tab: tab)
        case .alertSecondButtonReturn:
            return true
        default:
            return false
        }
    }

    private func showError(_ message: String, in tab: EditorTab? = nil) {
        let target = tab ?? selectedTab
        target?.compilationState = .failed
        target?.error = LaTeXError(message: message, line: nil, rawOutput: message)
        target?.compilerOutput = message
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
