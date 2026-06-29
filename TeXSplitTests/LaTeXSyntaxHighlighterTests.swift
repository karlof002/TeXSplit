import AppKit
import Foundation
import XCTest
@testable import TeXSplit

final class LaTeXSyntaxHighlighterTests: XCTestCase {
    func testRecognizesLaTeXCommands() {
        let source = "\\section{Titel}\\textbf{fett}"
        let tokens = LaTeXSyntaxHighlighter().tokens(in: source)

        XCTAssertTrue(tokens.contains { $0.kind == .command && text(source, in: $0.range) == "\\section" })
        XCTAssertTrue(tokens.contains { $0.kind == .command && text(source, in: $0.range) == "\\textbf" })
    }

    func testRecognizesCommentsFromPercentToLineEnd() {
        let source = "Text % Kommentar\nWeiter"
        let tokens = LaTeXSyntaxHighlighter().tokens(in: source)
        let comments = tokens.filter { $0.kind == .comment }

        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual(text(source, in: comments[0].range), "% Kommentar\n")
    }

    func testEscapedPercentDoesNotStartComment() {
        let source = #"100\% Text % Kommentar"#
        let tokens = LaTeXSyntaxHighlighter().tokens(in: source)
        let comments = tokens.filter { $0.kind == .comment }

        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual(text(source, in: comments[0].range), "% Kommentar")
    }

    func testHighlightSetsBaseTextColorAndPreservesString() {
        let source = #"Hallo \section{Einleitung}"#
        let storage = NSTextStorage(string: source)
        let theme = EditorThemeProvider.theme(for: .xcodeDark, appearance: NSAppearance(named: .darkAqua) ?? NSApp.effectiveAppearance)
        let font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)

        LaTeXSyntaxHighlighter().highlight(textStorage: storage, theme: theme, baseFont: font)

        XCTAssertEqual(storage.string, source)
        let firstAttributes = storage.attributes(at: 0, effectiveRange: nil)
        XCTAssertEqual(firstAttributes[.foregroundColor] as? NSColor, theme.textColor)
        XCTAssertEqual(firstAttributes[.font] as? NSFont, font)
    }

    func testHighlightAppliesIDEStyleTokenColors() {
        let source = """
        \\section{Einleitung}
        \\begin{document}
        $E = mc^2$
        % \\section bleibt Kommentar
        \\end{document}
        """
        let storage = NSTextStorage(string: source)
        let theme = EditorThemeProvider.theme(for: .xcodeDark, appearance: NSAppearance(named: .darkAqua) ?? NSApp.effectiveAppearance)
        let font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)

        LaTeXSyntaxHighlighter().highlight(textStorage: storage, theme: theme, baseFont: font)

        XCTAssertEqual(color(in: storage, at: "\\section"), theme.commandColor)
        XCTAssertEqual(color(in: storage, at: "document"), theme.environmentColor)
        XCTAssertEqual(color(in: storage, at: "$E = mc^2$"), theme.mathColor)
        XCTAssertEqual(color(in: storage, at: "{"), theme.braceColor)
        XCTAssertEqual(color(in: storage, at: "% \\section bleibt Kommentar"), theme.commentColor)
        XCTAssertEqual(storage.string, source)
    }

    func testRecognizesMathRegions() {
        let source = #"a $x+y$ b \[ z^2 \] c \( q \)"#
        let tokens = LaTeXSyntaxHighlighter().tokens(in: source)
        let math = tokens.filter { $0.kind == .math }.map { text(source, in: $0.range) }

        XCTAssertTrue(math.contains("$x+y$"))
        XCTAssertTrue(math.contains(#"\[ z^2 \]"#))
        XCTAssertTrue(math.contains(#"\( q \)"#))
    }

    func testRecognizesEnvironmentNames() {
        let source = "\\begin{enumerate}\\item A\\end{enumerate}"
        let tokens = LaTeXSyntaxHighlighter().tokens(in: source)
        let environments = tokens.filter { $0.kind == .environmentName }.map { text(source, in: $0.range) }

        XCTAssertEqual(environments, ["enumerate", "enumerate"])
    }

    func testRecognizesBraces() {
        let source = "\\section[Short]{Long}"
        let tokens = LaTeXSyntaxHighlighter().tokens(in: source)

        XCTAssertEqual(tokens.filter { $0.kind == .brace }.count, 4)
    }

    private func text(_ source: String, in range: NSRange) -> String {
        (source as NSString).substring(with: range)
    }

    private func color(in storage: NSTextStorage, at substring: String) -> NSColor? {
        let range = (storage.string as NSString).range(of: substring)
        guard range.location != NSNotFound else { return nil }
        return storage.attribute(.foregroundColor, at: range.location, effectiveRange: nil) as? NSColor
    }
}
