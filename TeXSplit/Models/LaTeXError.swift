import Foundation

struct LaTeXError: Error, Equatable, LocalizedError {
    let message: String
    let line: Int?
    let rawOutput: String
    let missingPackageName: String?

    init(message: String, line: Int?, rawOutput: String, missingPackageName: String? = nil) {
        self.message = message
        self.line = line
        self.rawOutput = rawOutput
        self.missingPackageName = missingPackageName
    }

    var errorDescription: String? {
        if let line {
            return "\(message) (Zeile \(line))"
        }
        return message
    }
}
