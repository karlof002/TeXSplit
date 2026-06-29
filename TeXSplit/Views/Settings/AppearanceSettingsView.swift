import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Picker("App-Erscheinungsbild", selection: $settings.appAppearance) {
                ForEach(AppAppearance.allCases) { appearance in
                    Text(appearance.title).tag(appearance)
                }
            }

            Picker("Editor-Farbschema", selection: $settings.editorThemeID) {
                ForEach(EditorTheme.ID.allCases) { theme in
                    Text(theme.title).tag(theme)
                }
            }
        }
        .formStyle(.grouped)
    }
}
