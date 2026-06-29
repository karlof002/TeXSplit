import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings)
                .tabItem { Label("Allgemein", systemImage: "gearshape") }
            EditorSettingsView(settings: settings)
                .tabItem { Label("Editor", systemImage: "text.cursor") }
            AppearanceSettingsView(settings: settings)
                .tabItem { Label("Darstellung", systemImage: "paintpalette") }
            LaTeXSettingsView()
                .tabItem { Label("LaTeX", systemImage: "function") }
            PreviewSettingsView()
                .tabItem { Label("Vorschau", systemImage: "doc.richtext") }
        }
        .padding()
        .frame(width: 620, height: 420)
    }
}
