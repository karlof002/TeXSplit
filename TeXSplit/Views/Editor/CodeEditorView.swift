import AppKit
import SwiftUI

final class CodeTextView: NSTextView {
    var showsLineNumbers = true {
        didSet { needsDisplay = true }
    }
    var lineNumberTheme = EditorThemeProvider.theme(for: .system, appearance: NSApp.effectiveAppearance) {
        didSet { needsDisplay = true }
    }
    var lineNumberFont: NSFont = .monospacedSystemFont(ofSize: 14, weight: .regular) {
        didSet { needsDisplay = true }
    }
    let gutterWidth: CGFloat = 44

    override var acceptsFirstResponder: Bool { true }

    override func drawBackground(in rect: NSRect) {
        super.drawBackground(in: rect)
        drawLineNumbers(in: rect)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    private func drawLineNumbers(in rect: NSRect) {
        guard showsLineNumbers,
              let layoutManager,
              let textContainer,
              layoutManager.numberOfGlyphs > 0 else { return }

        lineNumberTheme.backgroundColor.setFill()
        NSRect(x: visibleRect.minX, y: rect.minY, width: gutterWidth, height: rect.height).fill()

        let text = string as NSString
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        guard glyphRange.location < layoutManager.numberOfGlyphs else { return }

        var lineNumber = LineNumberCalculator.lineNumber(
            forCharacterAt: layoutManager.characterIndexForGlyph(at: glyphRange.location),
            in: text
        )
        var glyphIndex = glyphRange.location
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: lineNumberFont.pointSize - 1, weight: .regular),
            .foregroundColor: lineNumberTheme.lineNumberColor
        ]

        while glyphIndex < NSMaxRange(glyphRange), glyphIndex < layoutManager.numberOfGlyphs {
            var effectiveRange = NSRange(location: 0, length: 0)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &effectiveRange)
            let y = lineRect.minY + textContainerOrigin.y
            let label = "\(lineNumber)" as NSString
            let size = label.size(withAttributes: attributes)
            label.draw(
                at: NSPoint(x: visibleRect.minX + gutterWidth - size.width - 8, y: y),
                withAttributes: attributes
            )
            glyphIndex = NSMaxRange(effectiveRange)
            lineNumber += 1
        }
    }
}

struct CodeEditorView: NSViewRepresentable {
    @Binding var text: String
    @ObservedObject var settings: AppSettings
    var onCursorChange: (Int, Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = false
        textContainer.heightTracksTextView = false
        textContainer.lineFragmentPadding = 0
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)

        let textView = CodeTextView(frame: .zero, textContainer: textContainer)
        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.contentView.drawsBackground = false
        scrollView.hasVerticalRuler = false
        scrollView.rulersVisible = false

        context.coordinator.configureTextView(textView, scrollView: scrollView, settings: settings)
        textView.drawsBackground = true
        textView.delegate = context.coordinator
        textView.string = text
        textView.minSize = NSSize(width: scrollView.contentSize.width, height: scrollView.contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.autoresizingMask = [.width]
        textView.textContainer?.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        context.coordinator.textView = textView
        context.coordinator.noteVisibleText(text)

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.boundsDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
        scrollView.contentView.postsBoundsChangedNotifications = true

        context.coordinator.applySettings(to: textView, scrollView: scrollView, settings: settings)
        context.coordinator.highlight(textView, settings: settings)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        context.coordinator.parent = self
        context.coordinator.isApplyingViewUpdate = true
        defer { context.coordinator.isApplyingViewUpdate = false }

        if context.coordinator.isAwaitingBindingUpdate(for: text) {
            context.coordinator.noteVisibleText(textView.string)
        } else if textView.string != text {
            let selectedRanges = textView.selectedRanges
            let visibleOrigin = scrollView.contentView.bounds.origin
            textView.string = text
            textView.selectedRanges = context.coordinator.clampedSelectedRanges(selectedRanges, textLength: (text as NSString).length)
            scrollView.contentView.scroll(to: visibleOrigin)
            scrollView.reflectScrolledClipView(scrollView.contentView)
            context.coordinator.noteVisibleText(text)
        }
        context.coordinator.updateTextGeometry(textView, scrollView: scrollView, settings: settings)
        context.coordinator.applySettings(to: textView, scrollView: scrollView, settings: settings)
        context.coordinator.highlight(textView, settings: settings)
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeEditorView
        weak var textView: NSTextView?
        var isApplyingViewUpdate = false
        private let highlighter = LaTeXSyntaxHighlighter()
        private var isHighlighting = false
        private var pendingCursorReport: Task<Void, Never>?
        private var pendingTextReport: Task<Void, Never>?
        private var pendingTextValue: String?
        private var visibleTextValue = ""

        init(_ parent: CodeEditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            guard !isApplyingViewUpdate else { return }
            guard !isHighlighting else { return }
            noteLocalTextChange(textView.string)
            highlight(textView, settings: parent.settings)
            scheduleCursorReport(textView)
            textView.needsDisplay = true
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            guard !isApplyingViewUpdate else { return }
            scheduleCursorReport(textView)
            updateCurrentLineHighlight(textView, settings: parent.settings)
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                indentSelection(in: textView)
                return true
            }
            if commandSelector == #selector(NSResponder.insertBacktab(_:)) {
                outdentSelection(in: textView)
                return true
            }
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                insertIndentedNewline(in: textView)
                return true
            }
            return false
        }

        @objc func boundsDidChange(_ notification: Notification) {
            textView?.needsDisplay = true
        }

        func configureTextView(_ textView: NSTextView, scrollView: NSScrollView, settings: AppSettings) {
            textView.isEditable = true
            textView.isSelectable = true
            textView.isRichText = false
            textView.allowsUndo = true
            textView.importsGraphics = false
            textView.isHidden = false
            textView.alphaValue = 1
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.isAutomaticDashSubstitutionEnabled = false
            textView.isAutomaticTextReplacementEnabled = false
            textView.isAutomaticSpellingCorrectionEnabled = false
            textView.isVerticallyResizable = true
            textView.isHorizontallyResizable = !settings.wrapsLines
            textView.autoresizingMask = [.width]
            applyTextAppearance(to: textView, settings: settings)
            updateTextGeometry(textView, scrollView: scrollView, settings: settings)
        }

        func noteVisibleText(_ text: String) {
            visibleTextValue = text
        }

        func isAwaitingBindingUpdate(for boundText: String) -> Bool {
            guard let pendingTextValue else { return false }
            if boundText == pendingTextValue {
                self.pendingTextValue = nil
                visibleTextValue = boundText
                return false
            }
            return true
        }

        func applySettings(to textView: NSTextView, scrollView: NSScrollView, settings: AppSettings) {
            let theme = settings.selectedTheme
            let font = settings.editorFont
            textView.isEditable = true
            textView.isSelectable = true
            textView.isRichText = false
            textView.allowsUndo = true
            textView.importsGraphics = false
            textView.isHidden = false
            textView.alphaValue = 1
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.isAutomaticDashSubstitutionEnabled = false
            textView.isAutomaticTextReplacementEnabled = false
            textView.isAutomaticSpellingCorrectionEnabled = false
            textView.isContinuousSpellCheckingEnabled = settings.spellCheckingEnabled
            scrollView.drawsBackground = false
            scrollView.contentView.drawsBackground = false
            applyTextAppearance(to: textView, settings: settings)

            updateTextGeometry(textView, scrollView: scrollView, settings: settings)

            if let codeTextView = textView as? CodeTextView {
                codeTextView.showsLineNumbers = settings.showsLineNumbers
                codeTextView.lineNumberTheme = theme
                codeTextView.lineNumberFont = font
            }
            updateCurrentLineHighlight(textView, settings: settings)
        }

        func applyTextAppearance(to textView: NSTextView, settings: AppSettings) {
            let theme = settings.selectedTheme
            let font = settings.editorFont
            textView.font = font
            textView.backgroundColor = theme.backgroundColor
            textView.textColor = theme.textColor
            textView.insertionPointColor = theme.caretColor
            textView.selectedTextAttributes = [
                .backgroundColor: theme.selectionColor,
                .foregroundColor: theme.selectedTextColor
            ]
            textView.textContainerInset = NSSize(width: settings.showsLineNumbers ? 52 : 8, height: 8)
            textView.typingAttributes = [
                .font: font,
                .foregroundColor: theme.textColor
            ]
        }

        func updateTextGeometry(_ textView: NSTextView, scrollView: NSScrollView, settings: AppSettings) {
            let visibleSize = scrollView.contentSize
            let width = settings.wrapsLines ? max(visibleSize.width, 1) : max(visibleSize.width, 12_000)
            let height = max(visibleSize.height, textView.frame.height, 1)

            textView.isHorizontallyResizable = !settings.wrapsLines
            textView.minSize = NSSize(width: visibleSize.width, height: visibleSize.height)
            textView.maxSize = NSSize(width: settings.wrapsLines ? visibleSize.width : CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

            var frame = textView.frame
            if frame.width != width || frame.height < height {
                frame.size = NSSize(width: width, height: height)
                textView.frame = frame
            }

            textView.textContainer?.widthTracksTextView = settings.wrapsLines
            textView.textContainer?.heightTracksTextView = false
            textView.textContainer?.containerSize = NSSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        }

        func highlight(_ textView: NSTextView, settings: AppSettings) {
            guard !isHighlighting else { return }
            let selectedRanges = textView.selectedRanges
            isHighlighting = true
            defer {
                textView.selectedRanges = clampedSelectedRanges(selectedRanges, textLength: (textView.string as NSString).length)
                textView.typingAttributes = [
                    .font: settings.editorFont,
                    .foregroundColor: settings.selectedTheme.textColor
                ]
                isHighlighting = false
                updateCurrentLineHighlight(textView, settings: settings)
            }
            if settings.syntaxHighlightingEnabled, let storage = textView.textStorage {
                highlighter.highlight(textStorage: storage, theme: settings.selectedTheme, baseFont: settings.editorFont)
            } else if let storage = textView.textStorage {
                let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
                storage.beginEditing()
                storage.setAttributes([
                    .font: settings.editorFont,
                    .foregroundColor: settings.selectedTheme.textColor
                ], range: fullRange)
                storage.endEditing()
            }
        }

        func clampedSelectedRanges(_ ranges: [NSValue], textLength: Int) -> [NSValue] {
            let clamped = ranges.map { value -> NSValue in
                let range = value.rangeValue
                let location = min(max(range.location, 0), textLength)
                let length = min(max(range.length, 0), textLength - location)
                return NSValue(range: NSRange(location: location, length: length))
            }
            return clamped.isEmpty ? [NSValue(range: NSRange(location: textLength, length: 0))] : clamped
        }

        private func updateCurrentLineHighlight(_ textView: NSTextView, settings: AppSettings) {
            guard let layoutManager = textView.layoutManager else { return }
            let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
            layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: fullRange)
            guard settings.highlightsCurrentLine else { return }
            let lineRange = (textView.string as NSString).lineRange(for: textView.selectedRange())
            layoutManager.addTemporaryAttribute(.backgroundColor, value: settings.selectedTheme.currentLineColor, forCharacterRange: lineRange)
        }

        private func indentSelection(in textView: NSTextView) {
            let spaces = String(repeating: " ", count: parent.settings.tabWidth)
            let selectedRange = textView.selectedRange()
            let text = textView.string as NSString
            let lineRange = text.lineRange(for: selectedRange)
            let selectedText = text.substring(with: lineRange)
            let indented = selectedText
                .components(separatedBy: "\n")
                .map { $0.isEmpty ? $0 : spaces + $0 }
                .joined(separator: "\n")
            textView.insertText(indented, replacementRange: lineRange)
        }

        private func outdentSelection(in textView: NSTextView) {
            let selectedRange = textView.selectedRange()
            let text = textView.string as NSString
            let lineRange = text.lineRange(for: selectedRange)
            let selectedText = text.substring(with: lineRange)
            let width = parent.settings.tabWidth
            let outdented = selectedText
                .components(separatedBy: "\n")
                .map { line -> String in
                    let removable = min(width, line.prefix { $0 == " " }.count)
                    return String(line.dropFirst(removable))
                }
                .joined(separator: "\n")
            textView.insertText(outdented, replacementRange: lineRange)
        }

        private func insertIndentedNewline(in textView: NSTextView) {
            let location = textView.selectedRange().location
            let prefix = (textView.string as NSString).substring(to: min(location, (textView.string as NSString).length))
            let currentLine = prefix.components(separatedBy: "\n").last ?? ""
            let indentation = String(currentLine.prefix { $0 == " " || $0 == "\t" })
            textView.insertText("\n\(indentation)", replacementRange: textView.selectedRange())
        }

        private func noteLocalTextChange(_ text: String) {
            visibleTextValue = text
            pendingTextValue = text
            pendingTextReport?.cancel()
            pendingTextReport = Task { @MainActor [weak self] in
                await Task.yield()
                guard let self, !Task.isCancelled else { return }
                self.parent.text = text
            }
        }

        private func scheduleCursorReport(_ textView: NSTextView) {
            let position = cursorPosition(in: textView)
            pendingCursorReport?.cancel()
            pendingCursorReport = Task { @MainActor [weak self] in
                await Task.yield()
                guard let self, !Task.isCancelled else { return }
                self.parent.onCursorChange(position.line, position.column)
            }
        }

        private func cursorPosition(in textView: NSTextView) -> (line: Int, column: Int) {
            let location = min(textView.selectedRange().location, textView.string.utf16.count)
            let prefix = (textView.string as NSString).substring(to: location)
            let line = prefix.filter { $0 == "\n" }.count + 1
            let column = (prefix.components(separatedBy: "\n").last?.count ?? 0) + 1
            return (line, column)
        }
    }
}
