import AppKit
import Foundation
import UniformTypeIdentifiers

extension UTType {
    static let tex = UTType(filenameExtension: "tex") ?? .plainText
}

@MainActor
final class FileService {
    func openTeXFile() async throws -> (url: URL, text: String)? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.tex]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart { url.stopAccessingSecurityScopedResource() }
        }
        return (url, try String(contentsOf: url, encoding: .utf8))
    }

    func save(text: String, to url: URL) throws {
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart { url.stopAccessingSecurityScopedResource() }
        }
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    func chooseSaveURL(defaultName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.tex]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = defaultName
        return panel.runModal() == .OK ? panel.url : nil
    }

    func choosePDFExportURL(defaultName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = defaultName
        return panel.runModal() == .OK ? panel.url : nil
    }
}
