import AppKit
import SwiftUI

enum SettingsWindowStyle {
    static func apply(to window: NSWindow) {
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor.windowBackgroundColor
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = false
        window.standardWindowButton(.zoomButton)?.isHidden = false

        AppBrandIcon.applyApplicationIcon()
        if let iconURL = Bundle.main.url(forResource: "icon", withExtension: "png") {
            window.representedURL = iconURL
        }
    }
}

struct SettingsWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            SettingsWindowStyle.apply(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct SettingsWindowTitleBar: View {
    var body: some View {
        Color.clear
            .frame(height: 28)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
    }
}
