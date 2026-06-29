import SwiftUI

struct StatusBarView: View {
    @ObservedObject var workspace: WorkspaceViewModel

    var body: some View {
        let tab = workspace.selectedTab
        HStack(spacing: 12) {
            Label(tab?.title ?? "Kein Dokument", systemImage: "doc.text")
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 220, alignment: .leading)

            Text("Zeile \(tab?.cursorLine ?? 1), Spalte \(tab?.cursorColumn ?? 1)")
                .foregroundStyle(.secondary)

            Text("UTF-8")
                .foregroundStyle(.secondary)

            Text("LF")
                .foregroundStyle(.secondary)

            Text(tab?.isModified == true ? "Ungespeichert" : "Gespeichert")
                .foregroundStyle(tab?.isModified == true ? .orange : .secondary)

            statusLabel

            Text(tab?.isAutoPreviewEnabled == true ? "Auto-Vorschau" : "Manuell")
                .foregroundStyle(.secondary)

            if let error = tab?.error {
                Text(error.localizedDescription)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.red)
            }

            Spacer()

            Button {
                workspace.isShowingCompilerLog = true
            } label: {
                Label("Compiler-Ausgabe", systemImage: "terminal")
            }
            .help("Compiler-Ausgabe anzeigen")
            .accessibilityLabel("Compiler-Ausgabe anzeigen")
            .disabled(!(tab?.compilerOutput.isEmpty == false))
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.bar)
    }

    private var statusLabel: some View {
        HStack(spacing: 6) {
            if workspace.selectedTab?.compilationState == .compiling {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.65)
                    .frame(width: 14, height: 14)
            }
            Text(workspace.selectedTab?.compilationState.title ?? "Bereit")
                .foregroundStyle(workspace.selectedTab?.compilationState == .failed ? .red : .secondary)
        }
    }
}
