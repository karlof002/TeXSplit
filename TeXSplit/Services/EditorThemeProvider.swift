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
                backgroundColor: .textBackgroundColor,
                textColor: .labelColor,
                selectedTextColor: .selectedTextColor,
                caretColor: .labelColor,
                commandColor: NSColor(calibratedRed: 0.48, green: 0.10, blue: 0.68, alpha: 1),
                commentColor: NSColor(calibratedRed: 0.30, green: 0.50, blue: 0.24, alpha: 1),
                mathColor: NSColor(calibratedRed: 0.75, green: 0.32, blue: 0.00, alpha: 1),
                braceColor: NSColor(calibratedRed: 0.12, green: 0.33, blue: 0.72, alpha: 1),
                environmentColor: NSColor(calibratedRed: 0.00, green: 0.42, blue: 0.62, alpha: 1),
                lineNumberColor: .tertiaryLabelColor,
                currentLineColor: NSColor.controlAccentColor.withAlphaComponent(0.10),
                selectionColor: .selectedTextBackgroundColor
            )
        case .xcodeDark:
            return EditorTheme(
                id: id,
                backgroundColor: NSColor(calibratedRed: 0.09, green: 0.10, blue: 0.12, alpha: 1),
                textColor: NSColor(calibratedWhite: 0.86, alpha: 1),
                selectedTextColor: NSColor(calibratedWhite: 1.0, alpha: 1),
                caretColor: NSColor(calibratedWhite: 0.94, alpha: 1),
                commandColor: NSColor(calibratedRed: 0.80, green: 0.58, blue: 1.00, alpha: 1),
                commentColor: NSColor(calibratedRed: 0.45, green: 0.72, blue: 0.43, alpha: 1),
                mathColor: NSColor(calibratedRed: 1.00, green: 0.67, blue: 0.33, alpha: 1),
                braceColor: NSColor(calibratedRed: 0.55, green: 0.75, blue: 1.00, alpha: 1),
                environmentColor: NSColor(calibratedRed: 0.50, green: 0.86, blue: 1.00, alpha: 1),
                lineNumberColor: NSColor(calibratedWhite: 0.45, alpha: 1),
                currentLineColor: NSColor.white.withAlphaComponent(0.08),
                selectionColor: .selectedTextBackgroundColor
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
                commandColor: NSColor(calibratedRed: 0.52, green: 0.60, blue: 0.00, alpha: 1),
                commentColor: NSColor(calibratedRed: 0.35, green: 0.43, blue: 0.46, alpha: 1),
                mathColor: NSColor(calibratedRed: 0.80, green: 0.29, blue: 0.09, alpha: 1),
                braceColor: NSColor(calibratedRed: 0.15, green: 0.55, blue: 0.82, alpha: 1),
                environmentColor: NSColor(calibratedRed: 0.71, green: 0.54, blue: 0.00, alpha: 1),
                lineNumberColor: NSColor(calibratedRed: 0.35, green: 0.43, blue: 0.46, alpha: 1),
                currentLineColor: NSColor.white.withAlphaComponent(0.06),
                selectionColor: NSColor(calibratedRed: 0.03, green: 0.21, blue: 0.26, alpha: 1)
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
