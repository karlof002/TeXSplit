import AppKit
import Foundation

enum EditorThemeProvider {
    static func theme(for id: EditorTheme.ID, appearance: NSAppearance) -> EditorTheme {
        if id == .system {
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return theme(for: isDark ? .xcodeDark : .xcodeLight, appearance: appearance)
        }

        switch id {
        case .system:
            return theme(for: .system, appearance: appearance)
        case .xcodeLight:
            return EditorTheme(
                id: id,
                backgroundColor: NSColor(calibratedWhite: 1.0, alpha: 1),
                textColor: NSColor(calibratedRed: 0.12, green: 0.14, blue: 0.16, alpha: 1),
                selectedTextColor: NSColor.white,
                caretColor: NSColor(calibratedRed: 0.10, green: 0.10, blue: 0.10, alpha: 1),
                commandColor: NSColor(calibratedRed: 0.00, green: 0.28, blue: 0.68, alpha: 1),
                commentColor: NSColor(calibratedRed: 0.00, green: 0.47, blue: 0.00, alpha: 1),
                mathColor: NSColor(calibratedRed: 0.72, green: 0.20, blue: 0.00, alpha: 1),
                braceColor: NSColor(calibratedRed: 0.48, green: 0.25, blue: 0.00, alpha: 1),
                environmentColor: NSColor(calibratedRed: 0.15, green: 0.46, blue: 0.56, alpha: 1),
                lineNumberColor: NSColor(calibratedRed: 0.50, green: 0.54, blue: 0.59, alpha: 1),
                currentLineColor: NSColor(calibratedRed: 0.92, green: 0.95, blue: 1.00, alpha: 1),
                selectionColor: NSColor(calibratedRed: 0.00, green: 0.36, blue: 0.78, alpha: 1)
            )
        case .xcodeDark:
            return EditorTheme(
                id: id,
                backgroundColor: NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.12, alpha: 1),
                textColor: NSColor(calibratedRed: 0.83, green: 0.83, blue: 0.83, alpha: 1),
                selectedTextColor: NSColor(calibratedWhite: 1.0, alpha: 1),
                caretColor: NSColor(calibratedRed: 0.92, green: 0.92, blue: 0.92, alpha: 1),
                commandColor: NSColor(calibratedRed: 0.34, green: 0.61, blue: 0.84, alpha: 1),
                commentColor: NSColor(calibratedRed: 0.42, green: 0.60, blue: 0.33, alpha: 1),
                mathColor: NSColor(calibratedRed: 0.81, green: 0.57, blue: 0.36, alpha: 1),
                braceColor: NSColor(calibratedRed: 0.86, green: 0.73, blue: 0.48, alpha: 1),
                environmentColor: NSColor(calibratedRed: 0.31, green: 0.79, blue: 0.69, alpha: 1),
                lineNumberColor: NSColor(calibratedWhite: 0.50, alpha: 1),
                currentLineColor: NSColor(calibratedWhite: 1.0, alpha: 0.06),
                selectionColor: NSColor(calibratedRed: 0.10, green: 0.38, blue: 0.68, alpha: 1)
            )
        case .solarizedLight:
            return EditorTheme(
                id: id,
                backgroundColor: NSColor(calibratedRed: 0.99, green: 0.96, blue: 0.89, alpha: 1),
                textColor: NSColor(calibratedRed: 0.40, green: 0.48, blue: 0.51, alpha: 1),
                selectedTextColor: NSColor(calibratedRed: 0.00, green: 0.17, blue: 0.21, alpha: 1),
                caretColor: NSColor(calibratedRed: 0.40, green: 0.48, blue: 0.51, alpha: 1),
                commandColor: NSColor(calibratedRed: 0.52, green: 0.60, blue: 0.00, alpha: 1),
                commentColor: NSColor(calibratedRed: 0.58, green: 0.63, blue: 0.63, alpha: 1),
                mathColor: NSColor(calibratedRed: 0.80, green: 0.29, blue: 0.09, alpha: 1),
                braceColor: NSColor(calibratedRed: 0.15, green: 0.55, blue: 0.82, alpha: 1),
                environmentColor: NSColor(calibratedRed: 0.71, green: 0.54, blue: 0.00, alpha: 1),
                lineNumberColor: NSColor(calibratedRed: 0.58, green: 0.63, blue: 0.63, alpha: 1),
                currentLineColor: NSColor(calibratedWhite: 0.0, alpha: 0.05),
                selectionColor: NSColor(calibratedRed: 0.86, green: 0.84, blue: 0.75, alpha: 1)
            )
        case .solarizedDark:
            return EditorTheme(
                id: id,
                backgroundColor: NSColor(calibratedRed: 0.00, green: 0.17, blue: 0.21, alpha: 1),
                textColor: NSColor(calibratedRed: 0.51, green: 0.58, blue: 0.59, alpha: 1),
                selectedTextColor: NSColor(calibratedRed: 0.93, green: 0.91, blue: 0.84, alpha: 1),
                caretColor: NSColor(calibratedRed: 0.93, green: 0.91, blue: 0.84, alpha: 1),
                commandColor: NSColor(calibratedRed: 0.15, green: 0.55, blue: 0.82, alpha: 1),
                commentColor: NSColor(calibratedRed: 0.35, green: 0.43, blue: 0.46, alpha: 1),
                mathColor: NSColor(calibratedRed: 0.71, green: 0.54, blue: 0.00, alpha: 1),
                braceColor: NSColor(calibratedRed: 0.80, green: 0.29, blue: 0.09, alpha: 1),
                environmentColor: NSColor(calibratedRed: 0.16, green: 0.63, blue: 0.60, alpha: 1),
                lineNumberColor: NSColor(calibratedRed: 0.35, green: 0.43, blue: 0.46, alpha: 1),
                currentLineColor: NSColor.white.withAlphaComponent(0.06),
                selectionColor: NSColor(calibratedRed: 0.03, green: 0.23, blue: 0.29, alpha: 1)
            )
        case .monokai:
            return EditorTheme(
                id: id,
                backgroundColor: NSColor(calibratedRed: 0.15, green: 0.16, blue: 0.13, alpha: 1),
                textColor: NSColor(calibratedRed: 0.94, green: 0.93, blue: 0.84, alpha: 1),
                selectedTextColor: NSColor(calibratedRed: 0.98, green: 0.97, blue: 0.90, alpha: 1),
                caretColor: NSColor(calibratedRed: 0.98, green: 0.97, blue: 0.90, alpha: 1),
                commandColor: NSColor(calibratedRed: 0.98, green: 0.15, blue: 0.45, alpha: 1),
                commentColor: NSColor(calibratedRed: 0.46, green: 0.44, blue: 0.37, alpha: 1),
                mathColor: NSColor(calibratedRed: 0.91, green: 0.75, blue: 0.24, alpha: 1),
                braceColor: NSColor(calibratedRed: 0.40, green: 0.85, blue: 0.94, alpha: 1),
                environmentColor: NSColor(calibratedRed: 0.65, green: 0.89, blue: 0.18, alpha: 1),
                lineNumberColor: NSColor(calibratedRed: 0.55, green: 0.53, blue: 0.45, alpha: 1),
                currentLineColor: NSColor.white.withAlphaComponent(0.07),
                selectionColor: NSColor(calibratedRed: 0.29, green: 0.28, blue: 0.24, alpha: 1)
            )
        }
    }
}
