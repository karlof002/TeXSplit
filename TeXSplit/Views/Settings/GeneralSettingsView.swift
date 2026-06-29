import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Toggle("Automatische Vorschau standardmäßig aktivieren", isOn: $settings.autoPreviewEnabledByDefault)

            Picker("Verzögerung der automatischen Kompilierung", selection: $settings.autoCompileDelayMilliseconds) {
                Text("300 ms").tag(300)
                Text("600 ms").tag(600)
                Text("1000 ms").tag(1000)
                Text("1500 ms").tag(1500)
            }

            Toggle("Letzte Sitzung beim Start wiederherstellen", isOn: $settings.restoreLastSession)
            Toggle("Neue Dokumente mit Standardvorlage erstellen", isOn: $settings.useDefaultTemplate)
            Toggle("Bestätigung beim Schließen ungespeicherter Dokumente", isOn: $settings.confirmUnsavedClose)
        }
        .formStyle(.grouped)
    }
}
