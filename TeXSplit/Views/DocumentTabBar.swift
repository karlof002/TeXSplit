import SwiftUI

struct DocumentTabBar: View {
    @ObservedObject var workspace: WorkspaceViewModel

    var body: some View {
        HStack(spacing: 4) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(workspace.tabs) { tab in
                        DocumentTabItem(
                            tab: tab,
                            isSelected: workspace.selectedTabID == tab.id,
                            select: { workspace.selectTab(tab) },
                            close: { workspace.close(tab: tab) }
                        )
                    }
                }
                .padding(.horizontal, 8)
            }

            Divider()
                .frame(height: 18)

            Button {
                workspace.createNewTab()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("Neuen Tab erstellen")
            .accessibilityLabel("Neuen Tab erstellen")
            .padding(.trailing, 8)
        }
        .frame(height: 36)
        .background(.bar)
    }
}
