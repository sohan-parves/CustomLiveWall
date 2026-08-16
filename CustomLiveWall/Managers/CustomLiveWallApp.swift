import SwiftUI

@main
struct CustomLiveWallApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    var body: some Scene {
        // Settings scene provides the settings window when needed
        Settings {
            EmptyView()
        }
    }
}
