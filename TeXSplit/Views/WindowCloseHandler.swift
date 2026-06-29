import AppKit
import SwiftUI

struct WindowCloseHandler: NSViewRepresentable {
    var shouldClose: () -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(shouldClose: shouldClose)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.delegate = context.coordinator
        }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        context.coordinator.shouldClose = shouldClose
        DispatchQueue.main.async {
            view.window?.delegate = context.coordinator
        }
    }

    final class Coordinator: NSObject, NSWindowDelegate {
        var shouldClose: () -> Bool

        init(shouldClose: @escaping () -> Bool) {
            self.shouldClose = shouldClose
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            shouldClose()
        }
    }
}
