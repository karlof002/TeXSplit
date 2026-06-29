import Foundation

struct LaTeXErrorParser {
    func parse(_ output: String) -> LaTeXError {
        let lines = output.components(separatedBy: .newlines)
        let rawMessage = lines.first { $0.hasPrefix("!") }?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "! ", with: "")

        let missingPackage = missingPackageName(in: output)
        let message: String
        if let missingPackage {
            message = "LaTeX-Paket fehlt: \(missingPackage). Installiere es mit tlmgr."
        } else {
            message = rawMessage ?? "LaTeX-Kompilierung fehlgeschlagen."
        }

        let line = firstLineNumber(in: output)
        return LaTeXError(
            message: message,
            line: line,
            rawOutput: enrichedOutput(originalOutput: output, missingPackageName: missingPackage),
            missingPackageName: missingPackage
        )
    }

    func firstLineNumber(in output: String) -> Int? {
        let patterns = [
            #"l\.(\d+)"#,
            #"line\s+(\d+)"#,
            #":(\d+):"#
        ]

        for pattern in patterns {
            if let match = output.range(of: pattern, options: .regularExpression) {
                let fragment = String(output[match])
                if let digits = fragment.range(of: #"\d+"#, options: .regularExpression) {
                    return Int(fragment[digits])
                }
            }
        }
        return nil
    }

    func missingPackageName(in output: String) -> String? {
        guard let match = output.range(
            of: #"File [`']([^`']+\.sty)' not found"#,
            options: .regularExpression
        ) else {
            return nil
        }

        let fragment = String(output[match])
        guard let filenameRange = fragment.range(
            of: #"[^`']+\.sty"#,
            options: .regularExpression
        ) else {
            return nil
        }

        let filename = String(fragment[filenameRange])
        return filename.replacingOccurrences(of: ".sty", with: "")
    }

    private func enrichedOutput(originalOutput: String, missingPackageName: String?) -> String {
        guard let missingPackageName else { return originalOutput }
        return """
        \(originalOutput)

        TeXSplit-Hinweis:
        Das LaTeX-Paket "\(missingPackageName)" fehlt.

        Installation im Terminal:
        sudo /Library/TeX/texbin/tlmgr install \(missingPackageName)

        Falls du BasicTeX frisch installiert hast, kann vorher ein Update noetig sein:
        sudo /Library/TeX/texbin/tlmgr update --self --all
        """
    }
}
