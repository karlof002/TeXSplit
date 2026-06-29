import SwiftUI

struct PreviewSettingsView: View {
    var body: some View {
        Form {
            LabeledContent("PDF-Vorschau") {
                Text("PDFKit")
                    .foregroundStyle(.secondary)
            }
            Text("Zoom und Breitenanpassung werden pro Tab gespeichert.")
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}
