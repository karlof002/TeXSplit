import SwiftUI

struct LaTeXSettingsView: View {
    var body: some View {
        Form {
            LabeledContent("Compiler") {
                Text("Eingebettetes TeX Live")
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Engine") {
                Text("pdflatex")
                    .foregroundStyle(.secondary)
            }
            Text("TeXSplit verwendet zuerst den im App-Bundle enthaltenen Compiler.")
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}
