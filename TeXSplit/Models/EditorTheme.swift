import AppKit
import Foundation

struct EditorTheme: Identifiable, Equatable {
    enum ID: String, CaseIterable, Identifiable {
        case system
        case xcodeLight
        case xcodeDark
        case solarizedLight
        case solarizedDark
        case monokai

        var id: String { rawValue }
        var title: String {
            switch self {
            case .system: "System"
            case .xcodeLight: "Xcode Light"
            case .xcodeDark: "Xcode Dark"
            case .solarizedLight: "Solarized Light"
            case .solarizedDark: "Solarized Dark"
            case .monokai: "Monokai"
            }
        }
    }

    let id: ID
    let backgroundColor: NSColor
    let textColor: NSColor
    let selectedTextColor: NSColor
    let caretColor: NSColor
    let commandColor: NSColor
    let commentColor: NSColor
    let mathColor: NSColor
    let braceColor: NSColor
    let environmentColor: NSColor
    let lineNumberColor: NSColor
    let currentLineColor: NSColor
    let selectionColor: NSColor
}
