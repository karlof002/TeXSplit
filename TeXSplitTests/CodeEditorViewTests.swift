import AppKit
import XCTest
@testable import TeXSplit

@MainActor
final class CodeEditorViewTests: XCTestCase {
    func testThemeColorsKeepTextCaretAndSelectionDistinct() {
        for id in EditorTheme.ID.allCases {
            let theme = EditorThemeProvider.theme(for: id, appearance: NSAppearance(named: .darkAqua) ?? NSApp.effectiveAppearance)

            XCTAssertNotEqual(theme.backgroundColor, theme.textColor, "\(id.title) background/text must contrast")
            XCTAssertNotEqual(theme.selectionColor, theme.selectedTextColor, "\(id.title) selection colors must contrast")
            XCTAssertNotEqual(theme.backgroundColor, theme.caretColor, "\(id.title) caret must be visible")
            XCTAssertNotEqual(theme.commandColor, theme.textColor, "\(id.title) commands should use a dedicated IDE color")
            XCTAssertNotEqual(theme.commentColor, theme.textColor, "\(id.title) comments should use a dedicated IDE color")
            XCTAssertNotEqual(theme.mathColor, theme.textColor, "\(id.title) math should use a dedicated IDE color")
            XCTAssertNotEqual(theme.environmentColor, theme.textColor, "\(id.title) environments should use a dedicated IDE color")
            XCTAssertNotEqual(theme.braceColor, theme.textColor, "\(id.title) braces should use a dedicated IDE color")
        }
    }

    func testApplySettingsConfiguresEditableSelectableTextViewAttributes() {
        let settings = AppSettings(defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        settings.editorThemeID = .xcodeDark
        let editor = CodeEditorView(text: .constant("Hallo"), settings: settings, onCursorChange: { _, _ in })
        let coordinator = CodeEditorView.Coordinator(editor)
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return XCTFail("Expected NSTextView document view")
        }

        coordinator.applySettings(to: textView, scrollView: scrollView, settings: settings)

        XCTAssertTrue(textView.isEditable)
        XCTAssertTrue(textView.isSelectable)
        XCTAssertFalse(textView.isRichText)
        XCTAssertFalse(textView.importsGraphics)
        XCTAssertTrue(textView.allowsUndo)
        XCTAssertFalse(textView.isHidden)
        XCTAssertGreaterThan(textView.alphaValue, 0)
        XCTAssertEqual(textView.textColor, settings.selectedTheme.textColor)
        XCTAssertEqual(textView.insertionPointColor, settings.selectedTheme.caretColor)
        XCTAssertEqual(textView.typingAttributes[.foregroundColor] as? NSColor, settings.selectedTheme.textColor)
        XCTAssertEqual(textView.typingAttributes[.font] as? NSFont, settings.editorFont)
        XCTAssertEqual(textView.selectedTextAttributes[.foregroundColor] as? NSColor, settings.selectedTheme.selectedTextColor)
    }

    func testHighlightPreservesSelectionAndRestoresTypingAttributes() {
        let settings = AppSettings(defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        settings.editorThemeID = .xcodeLight
        let editor = CodeEditorView(text: .constant(#"\section{Einleitung}"#), settings: settings, onCursorChange: { _, _ in })
        let coordinator = CodeEditorView.Coordinator(editor)
        let textView = NSTextView()
        textView.string = #"\section{Einleitung}"#
        textView.setSelectedRange(NSRange(location: 3, length: 4))

        coordinator.applySettings(to: textView, scrollView: NSScrollView(), settings: settings)
        coordinator.highlight(textView, settings: settings)

        XCTAssertEqual(textView.selectedRange(), NSRange(location: 3, length: 4))
        XCTAssertEqual(textView.typingAttributes[.foregroundColor] as? NSColor, settings.selectedTheme.textColor)
        XCTAssertEqual(textView.typingAttributes[.font] as? NSFont, settings.editorFont)
        XCTAssertEqual(textView.string, #"\section{Einleitung}"#)
    }

    func testCoordinatorHighlightKeepsTokenAttributesVisible() {
        let settings = AppSettings(defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        settings.editorThemeID = .xcodeDark
        settings.syntaxHighlightingEnabled = true
        let source = #"\section{Einleitung}"#
        let editor = CodeEditorView(text: .constant(source), settings: settings, onCursorChange: { _, _ in })
        let coordinator = CodeEditorView.Coordinator(editor)
        let textView = NSTextView()
        textView.string = source

        coordinator.applySettings(to: textView, scrollView: NSScrollView(), settings: settings)
        coordinator.highlight(textView, settings: settings)

        XCTAssertEqual(color(in: textView, at: "\\section"), settings.selectedTheme.commandColor)
        XCTAssertEqual(color(in: textView, at: "{"), settings.selectedTheme.braceColor)
        XCTAssertEqual(textView.typingAttributes[.foregroundColor] as? NSColor, settings.selectedTheme.textColor)
    }

    private func color(in textView: NSTextView, at substring: String) -> NSColor? {
        let range = (textView.string as NSString).range(of: substring)
        guard range.location != NSNotFound else { return nil }
        return textView.textStorage?.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? NSColor
    }
}
