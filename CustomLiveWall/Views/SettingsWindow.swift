import Cocoa
import SwiftUI

final class SettingsWindowController: NSWindowController, NSWindowDelegate {

    static let shared = SettingsWindowController()

    init() {
        let window = NSWindow()
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func closeSettings() {
        window?.orderOut(nil)
    }

    func showSettings(wallpaperManager: WallpaperManager) {
        if let window {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            SettingsWindowStyle.apply(to: window)
            window.delegate = self
            window.contentViewController = NSHostingController(
                rootView: SettingsView().environmentObject(wallpaperManager)
            )
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
            .environmentObject(wallpaperManager)

        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "CustomLiveWall Settings"
        window.level = .normal
        window.isReleasedWhenClosed = false
        window.delegate = self
        SettingsWindowStyle.apply(to: window)

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowWidth: CGFloat = 780
            let windowHeight: CGFloat = 700
            let x = screenFrame.midX - (windowWidth / 2)
            let y = screenFrame.maxY - windowHeight - 20

            window.setFrame(NSRect(x: x, y: y, width: windowWidth, height: windowHeight), display: true)
        }

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
