import XCTest
@testable import TeXSplit

final class LaTeXErrorParserTests: XCTestCase {
    func testParsesTypicalLatexErrorMessageAndLine() {
        let output = """
        ! Undefined control sequence.
        l.7 \\doesnotexist
        """

        let error = LaTeXErrorParser().parse(output)

        XCTAssertEqual(error.message, "Undefined control sequence.")
        XCTAssertEqual(error.line, 7)
        XCTAssertEqual(error.rawOutput, output)
    }

    func testRecognizesLineNumberVariants() {
        let parser = LaTeXErrorParser()

        XCTAssertEqual(parser.firstLineNumber(in: "document.tex:23: Missing $ inserted."), 23)
        XCTAssertEqual(parser.firstLineNumber(in: "error on line 42"), 42)
    }

    func testParsesMissingStylePackage() {
        let output = """
        ! LaTeX Error: File `enumitem.sty' not found.

        l.9 \\usepackage
        """

        let error = LaTeXErrorParser().parse(output)

        XCTAssertEqual(error.message, "LaTeX-Paket fehlt: enumitem. Installiere es mit tlmgr.")
        XCTAssertEqual(error.line, 9)
        XCTAssertEqual(error.missingPackageName, "enumitem")
        XCTAssertTrue(error.rawOutput.contains("sudo /Library/TeX/texbin/tlmgr install enumitem"))
    }
}
