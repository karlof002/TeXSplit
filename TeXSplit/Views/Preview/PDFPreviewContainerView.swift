import SwiftUI

struct PDFPreviewContainerView: View {
    @ObservedObject var tab: EditorTab

    var body: some View {
        ZStack {
            if tab.generatedPDFURL == nil {
                VStack(spacing: 12) {
                    Image(systemName: "doc.richtext")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("Noch keine PDF-Vorschau")
                        .font(.headline)
                    Text("Kompiliere das Dokument, um die Vorschau zu erzeugen.")
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            PDFPreviewView(
                pdfURL: tab.generatedPDFURL,
                scale: $tab.pdfScaleFactor,
                fitToWidth: $tab.fitPDFToWidth,
                onLoadError: { message in
                    tab.error = LaTeXError(message: message, line: nil, rawOutput: message)
                }
            )
            .opacity(tab.generatedPDFURL == nil ? 0 : 1)
        }
        .frame(minWidth: 360)
    }
}
