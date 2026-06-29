import AppKit
import Foundation

enum LaTeXTokenKind: Equatable {
    case comment
    case command
    case environmentName
    case math
    case brace
}

struct LaTeXToken: Equatable {
    let kind: LaTeXTokenKind
    let range: NSRange
}

final class LaTeXSyntaxHighlighter {
    private let commandRegex = try? NSRegularExpression(pattern: #"\\[a-zA-Z@]+|\\[%&_{}$]"#)
    private let environmentRegex = try? NSRegularExpression(pattern: #"\\(?:begin|end)\{([^}]+)\}"#)
    private let braceRegex = try? NSRegularExpression(pattern: #"[\{\}\[\]]"#)

    func tokens(in text: String) -> [LaTeXToken] {
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        var tokens: [LaTeXToken] = []

        tokens.append(contentsOf: mathTokens(in: text))
        tokens.append(contentsOf: matches(commandRegex, in: text, kind: .command))
        tokens.append(contentsOf: environmentTokens(in: text))
        tokens.append(contentsOf: matches(braceRegex, in: text, kind: .brace))
        tokens.append(contentsOf: commentTokens(in: text))

        return tokens.filter { NSIntersectionRange($0.range, fullRange).length == $0.range.length }
    }

    func highlight(textStorage: NSTextStorage, theme: EditorTheme, baseFont: NSFont) {
        let text = textStorage.string
        let fullRange = NSRange(location: 0, length: (text as NSString).length)

        textStorage.beginEditing()
        defer { textStorage.endEditing() }
        textStorage.setAttributes([
            .font: baseFont,
            .foregroundColor: theme.textColor
        ], range: fullRange)

        for token in tokens(in: text) {
            let color: NSColor
            switch token.kind {
            case .comment: color = theme.commentColor
            case .command: color = theme.commandColor
            case .environmentName: color = theme.environmentColor
            case .math: color = theme.mathColor
            case .brace: color = theme.braceColor
            }
            textStorage.addAttribute(.foregroundColor, value: color, range: token.range)
        }
    }

    private func matches(_ regex: NSRegularExpression?, in text: String, kind: LaTeXTokenKind) -> [LaTeXToken] {
        guard let regex else { return [] }
        let range = NSRange(location: 0, length: (text as NSString).length)
        return regex.matches(in: text, range: range).map { LaTeXToken(kind: kind, range: $0.range) }
    }

    private func environmentTokens(in text: String) -> [LaTeXToken] {
        guard let environmentRegex else { return [] }
        let range = NSRange(location: 0, length: (text as NSString).length)
        return environmentRegex.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            return LaTeXToken(kind: .environmentName, range: match.range(at: 1))
        }
    }

    private func commentTokens(in text: String) -> [LaTeXToken] {
        let nsText = text as NSString
        var tokens: [LaTeXToken] = []
        var lineStart = 0

        while lineStart < nsText.length {
            let lineRange = nsText.lineRange(for: NSRange(location: lineStart, length: 0))
            let line = nsText.substring(with: lineRange) as NSString
            var index = 0
            while index < line.length {
                let char = line.character(at: index)
                if char == 37, !isEscapedPercent(line: line, index: index) {
                    tokens.append(LaTeXToken(
                        kind: .comment,
                        range: NSRange(location: lineRange.location + index, length: line.length - index)
                    ))
                    break
                }
                index += 1
            }
            lineStart = NSMaxRange(lineRange)
        }
        return tokens
    }

    private func isEscapedPercent(line: NSString, index: Int) -> Bool {
        guard index > 0 else { return false }
        var slashCount = 0
        var cursor = index - 1
        while cursor >= 0, line.character(at: cursor) == 92 {
            slashCount += 1
            cursor -= 1
        }
        return slashCount % 2 == 1
    }

    private func mathTokens(in text: String) -> [LaTeXToken] {
        let nsText = text as NSString
        var tokens: [LaTeXToken] = []
        var index = 0

        while index < nsText.length {
            if nsText.substring(with: NSRange(location: index, length: min(2, nsText.length - index))) == "\\(" {
                if let end = rangeOf("\\)", in: nsText, start: index + 2) {
                    tokens.append(LaTeXToken(kind: .math, range: NSRange(location: index, length: NSMaxRange(end) - index)))
                    index = NSMaxRange(end)
                    continue
                }
            }
            if nsText.substring(with: NSRange(location: index, length: min(2, nsText.length - index))) == "\\[" {
                if let end = rangeOf("\\]", in: nsText, start: index + 2) {
                    tokens.append(LaTeXToken(kind: .math, range: NSRange(location: index, length: NSMaxRange(end) - index)))
                    index = NSMaxRange(end)
                    continue
                }
            }
            let char = nsText.character(at: index)
            if char == 36, !isEscapedDollar(nsText, index: index) {
                let delimiterLength = nextCharacters(in: nsText, at: index, equal: "$$") ? 2 : 1
                if let end = findDollarDelimiter(in: nsText, start: index + delimiterLength, delimiterLength: delimiterLength) {
                    tokens.append(LaTeXToken(kind: .math, range: NSRange(location: index, length: end + delimiterLength - index)))
                    index = end + delimiterLength
                    continue
                }
            }
            index += 1
        }
        return tokens
    }

    private func rangeOf(_ needle: String, in text: NSString, start: Int) -> NSRange? {
        let searchRange = NSRange(location: start, length: text.length - start)
        let found = text.range(of: needle, options: [], range: searchRange)
        return found.location == NSNotFound ? nil : found
    }

    private func findDollarDelimiter(in text: NSString, start: Int, delimiterLength: Int) -> Int? {
        var index = start
        while index <= text.length - delimiterLength {
            if delimiterLength == 2, nextCharacters(in: text, at: index, equal: "$$") {
                return index
            }
            if delimiterLength == 1, text.character(at: index) == 36, !isEscapedDollar(text, index: index) {
                return index
            }
            index += 1
        }
        return nil
    }

    private func nextCharacters(in text: NSString, at index: Int, equal value: String) -> Bool {
        guard index + value.count <= text.length else { return false }
        return text.substring(with: NSRange(location: index, length: value.count)) == value
    }

    private func isEscapedDollar(_ text: NSString, index: Int) -> Bool {
        guard index > 0 else { return false }
        var slashCount = 0
        var cursor = index - 1
        while cursor >= 0, text.character(at: cursor) == 92 {
            slashCount += 1
            cursor -= 1
        }
        return slashCount % 2 == 1
    }
}
