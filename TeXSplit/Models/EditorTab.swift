import AppKit
import Foundation

@MainActor
final class EditorTab: ObservableObject, Identifiable {
    let id: UUID
    @Published var fileURL: URL?
    @Published var title: String
    @Published var sourceCode: String
    @Published var generatedPDFURL: URL?
    @Published var isModified: Bool
    @Published var compilationState: CompilationState
    @Published var compilerOutput: String
    @Published var error: LaTeXError?
    @Published var cursorLine: Int
    @Published var cursorColumn: Int
    @Published var pdfScaleFactor: CGFloat
    @Published var fitPDFToWidth: Bool
    @Published var isAutoPreviewEnabled: Bool

    private let compiler: LaTeXCompiling
    private var debounceTask: Task<Void, Never>?
    private var compileTask: Task<Void, Never>?

    init(
        id: UUID = UUID(),
        fileURL: URL? = nil,
        title: String? = nil,
        sourceCode: String = TeXDocument.defaultContent,
        isModified: Bool = false,
        isAutoPreviewEnabled: Bool = true,
        compiler: LaTeXCompiling = LaTeXCompiler()
    ) {
        self.id = id
        self.fileURL = fileURL
        self.title = title ?? fileURL?.lastPathComponent ?? "Unbenannt"
        self.sourceCode = sourceCode
        self.generatedPDFURL = nil
        self.isModified = isModified
        self.compilationState = .idle
        self.compilerOutput = ""
        self.error = nil
        self.cursorLine = 1
        self.cursorColumn = 1
        self.pdfScaleFactor = 0
        self.fitPDFToWidth = false
        self.isAutoPreviewEnabled = isAutoPreviewEnabled
        self.compiler = compiler
    }

    var displayTitle: String {
        "\(title)\(isModified ? " •" : "")"
    }

    var pdfExportName: String {
        if title.hasSuffix(".tex") {
            return title.replacingOccurrences(of: ".tex", with: ".pdf")
        }
        return "\(title).pdf"
    }

    func updateSource(_ text: String, settings: AppSettings) {
        guard sourceCode != text else { return }
        sourceCode = text
        isModified = true
        scheduleAutoCompile(settings: settings)
    }

    func updateCursor(line: Int, column: Int) {
        cursorLine = max(1, line)
        cursorColumn = max(1, column)
    }

    func markSaved(url: URL) {
        fileURL = url
        title = url.lastPathComponent
        isModified = false
    }

    func scheduleAutoCompile(settings: AppSettings) {
        guard isAutoPreviewEnabled else { return }
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: settings.autoCompileDelayNanoseconds)
                await self?.compile()
            } catch { }
        }
    }

    func compile() async {
        debounceTask?.cancel()
        compileTask?.cancel()
        compiler.cancel()

        compilationState = .compiling
        error = nil
        let source = sourceCode

        let task = Task { [compiler] in
            do {
                let result = try await compiler.compile(source: source)
                await MainActor.run {
                    self.generatedPDFURL = result.pdfURL
                    self.compilerOutput = result.log
                    self.compilationState = .compiled
                    self.error = nil
                }
            } catch is CancellationError {
                await MainActor.run {
                    self.compilationState = .idle
                }
            } catch let compilerError as LaTeXCompilerError {
                await MainActor.run {
                    self.compilationState = .failed
                    switch compilerError {
                    case .compilationFailed(let latexError):
                        self.error = latexError
                        self.compilerOutput = latexError.rawOutput
                    default:
                        let message = compilerError.localizedDescription
                        self.error = LaTeXError(message: message, line: nil, rawOutput: message)
                        self.compilerOutput = message
                    }
                }
            } catch {
                await MainActor.run {
                    let message = error.localizedDescription
                    self.compilationState = .failed
                    self.error = LaTeXError(message: message, line: nil, rawOutput: message)
                    self.compilerOutput = message
                }
            }
        }

        compileTask = task
        await task.value
    }

    func cancelCompile() {
        debounceTask?.cancel()
        compileTask?.cancel()
        compiler.cancel()
    }
}
