import AppKit

enum LineNumberCalculator {
    static func lineNumber(forCharacterAt characterIndex: Int, in text: NSString) -> Int {
        guard characterIndex > 0 else { return 1 }
        let end = min(characterIndex, text.length)
        var lineNumber = 1
        var index = 0
        while index < end {
            if text.character(at: index) == 10 {
                lineNumber += 1
            }
            index += 1
        }
        return lineNumber
    }
}

final class LineNumberRulerView: NSView {
    weak var textView: NSTextView?
    let ruleThickness: CGFloat = 44
    var theme: EditorTheme = EditorThemeProvider.theme(for: .system, appearance: NSApp.effectiveAppearance) {
        didSet { needsDisplay = true }
    }
    var font: NSFont = .monospacedSystemFont(ofSize: 14, weight: .regular) {
        didSet { needsDisplay = true }
    }

    init(textView: NSTextView) {
        self.textView = textView
        super.init(frame: NSRect(x: 0, y: 0, width: 44, height: 0))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        drawLineNumbers(in: dirtyRect)
    }

    func drawLineNumbers(in rect: NSRect) {
        guard let textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        theme.backgroundColor.setFill()
        rect.fill()

        let text = textView.string as NSString
        let visibleRect = textView.visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        var lineNumber = LineNumberCalculator.lineNumber(forCharacterAt: layoutManager.characterIndexForGlyph(at: glyphRange.location), in: text)
        var glyphIndex = glyphRange.location

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: font.pointSize - 1, weight: .regular),
            .foregroundColor: theme.lineNumberColor
        ]

        while glyphIndex < NSMaxRange(glyphRange) {
            var effectiveRange = NSRange(location: 0, length: 0)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &effectiveRange)
            let y = lineRect.minY + textView.textContainerOrigin.y - visibleRect.minY
            let label = "\(lineNumber)" as NSString
            let size = label.size(withAttributes: attributes)
            label.draw(
                at: NSPoint(x: ruleThickness - size.width - 8, y: y),
                withAttributes: attributes
            )
            glyphIndex = NSMaxRange(effectiveRange)
            lineNumber += 1
        }
    }

}
