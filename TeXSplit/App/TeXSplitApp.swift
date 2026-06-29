import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        configureApplicationIcon()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func configureApplicationIcon() {
        guard let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
              let icon = NSImage(contentsOf: iconURL) else { return }
        NSApp.applicationIconImage = icon
    }
}

@main
struct TeXSplitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = AppSettings.shared
    @StateObject private var workspace = WorkspaceViewModel(settings: .shared)

    var body: some Scene {
        WindowGroup("TeXSplit") {
            WorkspaceView(workspace: workspace, settings: settings)
                .onAppear { applyAppearance() }
                .onChange(of: settings.appAppearance) { _, _ in applyAppearance() }
        }
        .defaultSize(width: 1100, height: 720)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Neues Dokument") {
                    workspace.createNewTab()
                }
                .keyboardShortcut("n")

                Button("Neuer Tab") {
                    workspace.createNewTab()
                }
                .keyboardShortcut("t")
            }

            CommandGroup(after: .newItem) {
                Button("Datei öffnen ...") {
                    Task { await workspace.openDocument() }
                }
                .keyboardShortcut("o")

                Button("Speichern") {
                    Task { await workspace.saveActiveTab() }
                }
                .keyboardShortcut("s")

                Button("Speichern unter ...") {
                    Task { await workspace.saveActiveTabAs() }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])

                Button("Tab schließen") {
                    workspace.closeActiveTab()
                }
                .keyboardShortcut("w")

                Button("PDF exportieren ...") {
                    Task { await workspace.exportActivePDF() }
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }

            CommandMenu("Dokument") {
                Button("Kompilieren") {
                    Task { await workspace.compileActiveTab() }
                }
                .keyboardShortcut("r")

                Toggle("Automatische Vorschau", isOn: Binding(
                    get: { workspace.selectedTab?.isAutoPreviewEnabled == true },
                    set: { _ in workspace.toggleAutoPreviewForActiveTab() }
                ))

                Button("Compiler-Ausgabe") {
                    workspace.isShowingCompilerLog = true
                }
            }

            CommandMenu("Ansicht") {
                Toggle("Zeilennummern anzeigen", isOn: $settings.showsLineNumbers)

                Toggle("Zeilenumbruch", isOn: $settings.wrapsLines)

                Button("PDF vergrößern") {
                    workspace.zoomInPDF()
                }
                .keyboardShortcut("+")

                Button("PDF verkleinern") {
                    workspace.zoomOutPDF()
                }
                .keyboardShortcut("-")

                Button("An Breite anpassen") {
                    workspace.fitPDFWidth()
                }
                .keyboardShortcut("9")
            }

            CommandMenu("Fenster") {
                Button("Nächsten Tab anzeigen") { workspace.showNextTab() }
                    .keyboardShortcut("}", modifiers: [.command, .shift])
                Button("Vorherigen Tab anzeigen") { workspace.showPreviousTab() }
                    .keyboardShortcut("{", modifiers: [.command, .shift])
                SettingsLink {
                    Text("Einstellungen ...")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        Settings {
            SettingsView(settings: settings)
        }
    }

    private func applyAppearance() {
        NSApp.appearance = settings.preferredColorScheme.map(NSAppearance.init(named:)) ?? nil
    }
}
