import SwiftUI

struct EditorContainerView: View {
    @ObservedObject var tab: EditorTab
    @ObservedObject var settings: AppSettings
    var updateText: (String) -> Void
    var updateCursor: (Int, Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            CodeEditorView(
                text: Binding(
                    get: { tab.sourceCode },
                    set: updateText
                ),
                settings: settings,
                onCursorChange: updateCursor
            )
        }
        .frame(minWidth: 360)
    }
}
