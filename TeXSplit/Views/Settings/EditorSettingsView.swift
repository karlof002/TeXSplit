import AppKit
import SwiftUI

struct EditorSettingsView: View {
    @ObservedObject var settings: AppSettings

    private var monospaceFonts: [String] {
        let names = NSFontManager.shared.availableFontFamilies
        let preferred = ["SF Mono", "Menlo", "Monaco", "Courier New"]
        return (preferred + names.filter { $0.localizedCaseInsensitiveContains("Mono") || $0.localizedCaseInsensitiveContains("Code") })
            .removingDuplicates()
    }

    var body: some View {
        Form {
            Picker("Schriftart", selection: $settings.editorFontName) {
                ForEach(monospaceFonts, id: \.self) { Text($0).tag($0) }
            }

            HStack {
                Slider(value: $settings.editorFontSize, in: 10...28, step: 1)
                Text("\(Int(settings.editorFontSize)) pt")
                    .monospacedDigit()
                    .frame(width: 48, alignment: .trailing)
            }

            Picker("Tabulatorbreite", selection: $settings.tabWidth) {
                Text("2 Leerzeichen").tag(2)
                Text("4 Leerzeichen").tag(4)
                Text("8 Leerzeichen").tag(8)
            }

            Toggle("Zeilennummern anzeigen", isOn: $settings.showsLineNumbers)
            Toggle("Aktuelle Zeile hervorheben", isOn: $settings.highlightsCurrentLine)
            Toggle("Zeilenumbruch", isOn: $settings.wrapsLines)
            Toggle("Syntax-Highlighting", isOn: $settings.syntaxHighlightingEnabled)
            Toggle("Automatische schließende Klammern", isOn: $settings.autoCloseBrackets)
            Toggle("Rechtschreibprüfung", isOn: $settings.spellCheckingEnabled)
            Toggle("Leerzeichen statt Tab-Zeichen einfügen", isOn: $settings.insertsSpacesForTabs)
        }
        .formStyle(.grouped)
    }
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
