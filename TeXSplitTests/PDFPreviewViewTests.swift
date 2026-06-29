import PDFKit
import XCTest
@testable import TeXSplit

@MainActor
final class PDFPreviewViewTests: XCTestCase {
    func testRestoresViewportAfterDocumentReplacement() {
        let pdfView = PDFView()
        pdfView.document = document(pageCount: 3)
        pdfView.autoScales = false
        pdfView.scaleFactor = 1.7

        guard let originalPage = pdfView.document?.page(at: 1) else {
            return XCTFail("Expected original page")
        }
        pdfView.go(to: PDFDestination(page: originalPage, at: NSPoint(x: 40, y: 320)))

        let coordinator = PDFPreviewView.Coordinator()
        let state = coordinator.viewportState(in: pdfView)

        pdfView.document = document(pageCount: 3)
        coordinator.restoreViewport(state, in: pdfView)

        XCTAssertEqual(pdfView.document?.index(for: pdfView.currentPage ?? PDFPage()), 1)
        XCTAssertEqual(pdfView.scaleFactor, 1.7, accuracy: 0.001)
        XCTAssertFalse(pdfView.autoScales)
    }

    private func document(pageCount: Int) -> PDFDocument {
        let document = PDFDocument()
        for index in 0..<pageCount {
            document.insert(PDFPage(), at: index)
        }
        return document
    }
}
