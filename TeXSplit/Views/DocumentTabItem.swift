import SwiftUI

struct DocumentTabItem: View {
    @ObservedObject var tab: EditorTab
    let isSelected: Bool
    let select: () -> Void
    let close: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text")
                .foregroundStyle(.secondary)
            Text(tab.displayTitle)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 180)
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(.plain)
            .help("Tab schließen")
            .accessibilityLabel("Tab schließen")
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.85) : Color.clear)
        .foregroundStyle(isSelected ? Color(nsColor: .selectedMenuItemTextColor) : Color.primary)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture(perform: select)
        .help(tab.title)
        .accessibilityLabel(tab.displayTitle)
    }
}
