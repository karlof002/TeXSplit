import SwiftUI

struct ContentView: View {
    @ObservedObject var workspace: WorkspaceViewModel
    @ObservedObject var settings: AppSettings

    var body: some View {
        WorkspaceView(workspace: workspace, settings: settings)
    }
}
