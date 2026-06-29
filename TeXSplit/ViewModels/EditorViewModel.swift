import AppKit
import Foundation

@MainActor
final class EditorViewModel: ObservableObject {
    @Published var document = TeXDocument()
    @Published var cursorLine = 1
    @Published var cursorColumn = 1
    @Published var pdfURL: URL?
    @Published var compilerLog = ""
    @Published var error: LaTeXError?
    @Published var statusMessage = "Bereit"
    @Published var compilationState: CompilationState = .idle
    @Published var isAutoPreviewEnabled = true
    @Published var isShowingCompilerLog = false
    @Published var isShowingUnsavedAlert = false
    @Published var pdfScale: CGFloat = 0
    @Published var fitPDFToWidth = false
    @Published var isCompilerMissing = false
    @Published var isShowingPackageInstallAlert = false
    @Published var isInstallingPackage = false

    private let compiler: LaTeXCompiling
    private let fileService: FileService
    private let packageInstaller: TeXPackageInstalling
    private var debounceTask: Task<Void, Never>?
    private var compileTask: Task<Void, Never>?

    init(
        compiler: LaTeXCompiling? = nil,
        fileService: FileService? = nil,
        packageInstaller: TeXPackageInstalling = TeXPackageInstaller()
    ) {
        self.compiler = compiler ?? LaTeXCompiler()
        self.fileService = fileService ?? FileService()
        self.packageInstaller = packageInstaller
    }

    var documentName: String { document.displayName }
    var saveStateTitle: String { document.hasUnsavedChanges ? "Ungespeichert" : "Gespeichert" }
    var missingPackageName: String? { error?.missingPackageName }

    func updateText(_ text: String) {
        guard document.text != text else { return }
        document.text = text
        document.hasUnsavedChanges = true
        scheduleAutoCompile()
    }

    func updateCursor(line: Int, column: Int) {
        cursorLine = max(1, line)
        cursorColumn = max(1, column)
    }

    func newDocument() {
        document = TeXDocument()
        pdfURL = nil
        compilerLog = ""
        error = nil
        isCompilerMissing = false
        isShowingPackageInstallAlert = false
        isInstallingPackage = false
        compilationState = .idle
        statusMessage = "Neues Dokument"
    }

    func openDocument() async {
        do {
            guard let loaded = try await fileService.openTeXFile() else { return }
            document = TeXDocument(text: loaded.text, fileURL: loaded.url, hasUnsavedChanges: false)
            pdfURL = nil
            compilerLog = ""
            error = nil
            isCompilerMissing = false
            isShowingPackageInstallAlert = false
            statusMessage = "Geöffnet"
            scheduleAutoCompile()
        } catch {
            setErrorMessage(error.localizedDescription)
        }
    }

    func save() async {
        if let url = document.fileURL {
            do {
                try fileService.save(text: document.text, to: url)
                document.hasUnsavedChanges = false
                statusMessage = "Gespeichert"
            } catch {
                setErrorMessage(error.localizedDescription)
            }
        } else {
            await saveAs()
        }
    }

    func saveAs() async {
        guard let url = fileService.chooseSaveURL(defaultName: documentName) else { return }
        do {
            try fileService.save(text: document.text, to: url)
            document.fileURL = url
            document.hasUnsavedChanges = false
            statusMessage = "Gespeichert"
        } catch {
            setErrorMessage(error.localizedDescription)
        }
    }

    func exportPDF() async {
        if pdfURL == nil {
            await compile()
        }
        guard let pdfURL else { return }
        let exportName = documentName.replacingOccurrences(of: ".tex", with: ".pdf")
        guard let destination = fileService.choosePDFExportURL(defaultName: exportName) else { return }
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: pdfURL, to: destination)
            statusMessage = "PDF exportiert"
        } catch {
            setErrorMessage(error.localizedDescription)
        }
    }

    func compile() async {
        debounceTask?.cancel()
        await runCompilation()
    }

    private func runCompilation() async {
        compileTask?.cancel()
        compiler.cancel()

        compilationState = .compiling
        statusMessage = "Kompiliert ..."
        error = nil
        isShowingPackageInstallAlert = false

        let source = document.text
        let task = Task { [compiler] in
            do {
                let result = try await compiler.compile(source: source)
                await MainActor.run {
                    self.pdfURL = result.pdfURL
                    self.compilerLog = result.log
                    self.error = nil
                    self.isCompilerMissing = false
                    self.compilationState = .compiled
                    self.statusMessage = "Kompiliert"
                }
            } catch is CancellationError {
                await MainActor.run {
                    self.compilationState = .idle
                    self.statusMessage = "Abgebrochen"
                }
            } catch let compilerError as LaTeXCompilerError {
                await MainActor.run {
                    self.handleCompilerError(compilerError)
                }
            } catch {
                await MainActor.run {
                    self.setErrorMessage(error.localizedDescription)
                }
            }
        }
        compileTask = task
        await task.value
    }

    func toggleAutoPreview() {
        isAutoPreviewEnabled.toggle()
        if isAutoPreviewEnabled {
            scheduleAutoCompile()
        } else {
            debounceTask?.cancel()
        }
    }

    func zoomInPDF() {
        fitPDFToWidth = false
        pdfScale = pdfScale == 0 ? 1.2 : min(pdfScale * 1.2, 5)
    }

    func zoomOutPDF() {
        fitPDFToWidth = false
        pdfScale = pdfScale == 0 ? 0.8 : max(pdfScale / 1.2, 0.2)
    }

    func actualPDFSize() {
        fitPDFToWidth = false
        pdfScale = 1
    }

    func fitPDFWidth() {
        fitPDFToWidth = true
    }

    func openLaTeXInstallPage() {
        guard let url = URL(string: "https://www.tug.org/texlive/") else { return }
        NSWorkspace.shared.open(url)
    }

    func installMissingPackage() async {
        guard let packageName = missingPackageName else { return }

        isInstallingPackage = true
        compilationState = .compiling
        statusMessage = "Installiere \(packageName) ..."

        do {
            let output = try await packageInstaller.install(packageName: packageName)
            compilerLog = """
            \(compilerLog)

            TeXSplit-Paketinstallation:
            \(output)
            """
            isInstallingPackage = false
            statusMessage = "\(packageName) installiert"
            await compile()
        } catch {
            isInstallingPackage = false
            let packageInstallError = LaTeXError(
                message: error.localizedDescription,
                line: nil,
                rawOutput: error.localizedDescription,
                missingPackageName: packageName
            )
            self.error = packageInstallError
            self.compilerLog = error.localizedDescription
            self.compilationState = .failed
            self.statusMessage = error.localizedDescription
            self.isShowingPackageInstallAlert = false
        }
    }

    func scheduleAutoCompile(delayNanoseconds: UInt64 = 600_000_000) {
        guard isAutoPreviewEnabled else { return }
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: delayNanoseconds)
                await self?.runCompilation()
            } catch { }
        }
    }

    func requestClose() -> Bool {
        if document.hasUnsavedChanges {
            isShowingUnsavedAlert = true
            return false
        }
        return true
    }

    private func handleCompilerError(_ compilerError: LaTeXCompilerError) {
        compilationState = .failed
        statusMessage = compilerError.localizedDescription
        switch compilerError {
        case .compilationFailed(let latexError):
            isCompilerMissing = false
            error = latexError
            compilerLog = latexError.rawOutput
            isShowingPackageInstallAlert = false
        case .compilerNotFound:
            isCompilerMissing = true
            isShowingPackageInstallAlert = false
            error = LaTeXError(message: compilerError.localizedDescription, line: nil, rawOutput: compilerError.localizedDescription)
            compilerLog = """
            Eingebetteter LaTeX-Compiler fehlt.

            TeXSplit ist so konfiguriert, dass ein eigener Compiler im App-Bundle liegen kann.
            Erwartete Pfade im Bundle:

            Contents/Resources/TeXLive/bin/universal-darwin/pdflatex
            Contents/Resources/TeXLive/2026basic/bin/universal-darwin/pdflatex
            Contents/Resources/TeXLive/2026/bin/universal-darwin/pdflatex

            In diesem Entwicklerbuild ist dort noch kein echter TeXLive-Runtime-Ordner enthalten.
            """
            statusMessage = "Eingebetteter Compiler fehlt"
        default:
            isCompilerMissing = false
            isShowingPackageInstallAlert = false
            error = LaTeXError(message: compilerError.localizedDescription, line: nil, rawOutput: compilerError.localizedDescription)
            compilerLog = compilerError.localizedDescription
        }
    }

    private func setErrorMessage(_ message: String) {
        compilationState = .failed
        statusMessage = message
        isCompilerMissing = false
        isShowingPackageInstallAlert = false
        error = LaTeXError(message: message, line: nil, rawOutput: message)
        compilerLog = message
    }
}
