import Foundation

struct TeXDocument: Equatable {
    static let defaultContent = """
    \\documentclass{article}
    \\usepackage[utf8]{inputenc}
    \\usepackage[T1]{fontenc}
    \\title{Mein Dokument}
    \\author{}
    \\date{}
    \\begin{document}
    \\maketitle
    Hallo Welt!
    \\end{document}
    """

    var text: String
    var fileURL: URL?
    var hasUnsavedChanges: Bool

    var displayName: String {
        fileURL?.lastPathComponent ?? "Unbenannt.tex"
    }

    init(text: String = Self.defaultContent, fileURL: URL? = nil, hasUnsavedChanges: Bool = false) {
        self.text = text
        self.fileURL = fileURL
        self.hasUnsavedChanges = hasUnsavedChanges
    }
}
