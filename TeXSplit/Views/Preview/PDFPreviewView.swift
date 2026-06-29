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
            let previousViewport = context.coordinator.viewportState(in: pdfView)
            context.coordinator.currentURL = pdfURL
            if let pdfURL {
                guard let document = PDFDocument(url: pdfURL) else {
                    DispatchQueue.main.async {
                        onLoadError("PDF konnte nicht geladen werden.")
                    }
                    pdfView.document = nil
                    return
                }
                let hadDocument = pdfView.document != nil
                pdfView.document = document
                if hadDocument {
                    context.coordinator.restoreViewport(previousViewport, in: pdfView)
                } else {
                    pdfView.autoScales = true
                }
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

        struct ViewportState {
            let pageIndex: Int
            let point: NSPoint
            let scaleFactor: CGFloat
            let autoScales: Bool
        }

        func viewportState(in pdfView: PDFView) -> ViewportState? {
            guard let document = pdfView.document,
                  let page = pdfView.currentPage else { return nil }
            let destination = pdfView.currentDestination
            return ViewportState(
                pageIndex: document.index(for: page),
                point: destination?.point ?? .zero,
                scaleFactor: pdfView.scaleFactor,
                autoScales: pdfView.autoScales
            )
        }

        func restoreViewport(_ state: ViewportState?, in pdfView: PDFView) {
            guard let state,
                  let document = pdfView.document,
                  document.pageCount > 0 else { return }

            pdfView.autoScales = state.autoScales
            if !state.autoScales {
                pdfView.scaleFactor = state.scaleFactor
            }

            let pageIndex = min(max(state.pageIndex, 0), document.pageCount - 1)
            guard let page = document.page(at: pageIndex) else { return }
            pdfView.go(to: PDFDestination(page: page, at: state.point))
        }
    }
}
