import PDFKit
import SwiftUI

struct PDFPreviewView: NSViewRepresentable {
    var pdfURL: URL?
    @Binding var scale: CGFloat
    @Binding var fitToWidth: Bool
    var onLoadError: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.displaysPageBreaks = true
        pdfView.backgroundColor = .textBackgroundColor
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        if context.coordinator.currentURL != pdfURL {
            context.coordinator.currentURL = pdfURL
            if let pdfURL {
                guard let document = PDFDocument(url: pdfURL) else {
                    DispatchQueue.main.async {
                        onLoadError("PDF konnte nicht geladen werden.")
                    }
                    pdfView.document = nil
                    return
                }
                pdfView.document = document
                pdfView.autoScales = true
            } else {
                pdfView.document = nil
            }
        }

        if fitToWidth {
            pdfView.autoScales = true
        } else if scale > 0 {
            pdfView.autoScales = false
            pdfView.scaleFactor = scale
        }
    }

    final class Coordinator {
        var currentURL: URL?
    }
}
