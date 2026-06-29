import SwiftUI

struct WorkspaceView: View {
    @ObservedObject var workspace: WorkspaceViewModel
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(spacing: 0) {
            DocumentTabBar(workspace: workspace)

            if let tab = workspace.selectedTab {
                HSplitView {
                    EditorContainerView(
                        tab: tab,
                        settings: settings,
                        updateText: workspace.updateActiveSource(_:),
                        updateCursor: workspace.updateActiveCursor(line:column:)
                    )
                    .frame(minWidth: 360, idealWidth: 560, maxWidth: .infinity)

                    PDFPreviewContainerView(tab: tab)
                        .frame(minWidth: 360, idealWidth: 560, maxWidth: .infinity)
                }
            } else {
                ContentUnavailableView("Kein Dokument", systemImage: "doc.text", description: Text("Erstelle oder öffne einen Tab."))
            }

            StatusBarView(workspace: workspace)
        }
        .frame(minWidth: 940, minHeight: 640)
        .toolbar {
            ToolbarItemGroup {
                toolbarButton("Neues Dokument", systemImage: "doc.badge.plus") {
                    workspace.createNewTab()
                }
                .keyboardShortcut("n")

                toolbarButton("Datei öffnen", systemImage: "folder") {
                    Task { await workspace.openDocument() }
                }

                toolbarButton("Speichern", systemImage: "square.and.arrow.down") {
                    Task { await workspace.saveActiveTab() }
                }
                .disabled(!workspace.canSave)

                toolbarButton("Kompilieren", systemImage: "play.fill") {
                    Task { await workspace.compileActiveTab() }
                }
                .disabled(workspace.selectedTab == nil)
            }

            ToolbarItemGroup {
                Button {
                    workspace.toggleAutoPreviewForActiveTab()
                } label: {
                    Label("Automatische Vorschau", systemImage: workspace.selectedTab?.isAutoPreviewEnabled == true ? "bolt.fill" : "bolt")
                }
                .help(workspace.selectedTab?.isAutoPreviewEnabled == true ? "Automatische Vorschau deaktivieren" : "Automatische Vorschau aktivieren")
                .accessibilityLabel("Automatische Vorschau")
                .disabled(workspace.selectedTab == nil)

                Menu {
                    Button("Speichern unter ...") { Task { await workspace.saveActiveTabAs() } }
                    Button("PDF exportieren ...") { Task { await workspace.exportActivePDF() } }
                        .disabled(!workspace.canExportPDF)
                    Divider()
                    Button("Vergrößern") { workspace.zoomInPDF() }
                    Button("Verkleinern") { workspace.zoomOutPDF() }
                    Button("An Breite anpassen") { workspace.fitPDFWidth() }
                    Divider()
                    Button("Compiler-Ausgabe anzeigen") { workspace.isShowingCompilerLog = true }
                        .disabled(!workspace.canShowCompilerOutput)
                    SettingsLink {
                        Label("Einstellungen öffnen", systemImage: "gearshape")
                    }
                } label: {
                    Label("Weitere Aktionen", systemImage: "ellipsis.circle")
                }
                .help("Weitere Aktionen")
                .accessibilityLabel("Weitere Aktionen")
            }
        }
        .sheet(isPresented: $workspace.isShowingCompilerLog) {
            CompilerLogView(log: workspace.selectedTab?.compilerOutput ?? "")
        }
        .background(WindowCloseHandler {
            workspace.closeCurrentWindowAllowed()
        })
    }

    private func toolbarButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .help(title)
        .accessibilityLabel(title)
    }
}
