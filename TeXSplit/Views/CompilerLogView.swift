import SwiftUI

struct CompilerLogView: View {
    let log: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compiler-Ausgabe")
                .font(.title3)
                .fontWeight(.semibold)

            ScrollView([.vertical, .horizontal]) {
                Text(log.isEmpty ? "Keine Ausgabe vorhanden." : log)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .background(.quaternary.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding()
        .frame(minWidth: 720, minHeight: 420)
    }
}
