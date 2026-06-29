import Foundation

enum CompilationState: Equatable {
    case idle
    case compiling
    case compiled
    case failed

    var title: String {
        switch self {
        case .idle: "Bereit"
        case .compiling: "Kompiliert ..."
        case .compiled: "Kompiliert"
        case .failed: "Fehler"
        }
    }
}

struct CompilationResult: Equatable {
    let pdfURL: URL
    let log: String
}
