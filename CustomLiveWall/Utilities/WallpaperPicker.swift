import Cocoa
import UniformTypeIdentifiers

enum WallpaperPicker {
    static func pickVideo(relativeTo parentWindow: NSWindow? = nil, completion: @escaping (URL?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .movie,
            .video,
            .mpeg4Movie,
            .quickTimeMovie,
            UTType(filenameExtension: "mp4") ?? .mpeg4Movie,
            UTType(filenameExtension: "mov") ?? .quickTimeMovie,
            UTType(filenameExtension: "m4v") ?? .mpeg4Movie
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Choose Video Wallpaper"

        if let parentWindow {
            panel.beginSheetModal(for: parentWindow) { response in
                completion(response == .OK ? panel.url : nil)
            }
        } else {
            panel.begin { response in
                completion(response == .OK ? panel.url : nil)
            }
        }
    }
}
