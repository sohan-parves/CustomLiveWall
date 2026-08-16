import Cocoa

protocol WallpaperPlayable: AnyObject {
    func play()
    func pause()
    func setLoop(_ loop: Bool)
    func setMuted(_ muted: Bool)
}

final class WallpaperWindow: NSWindow {

    private let targetScreen: NSScreen
    private var content: (NSView & WallpaperPlayable)?

    init(screen: NSScreen) {
        self.targetScreen = screen
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        configure()
    }

    private func configure() {
        isOpaque = true
        backgroundColor = .black
        hasShadow = false
        ignoresMouseEvents = true
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle
        ]
        setFrame(targetScreen.frame, display: true)
    }

    func showWallpaper(source: WallpaperSource, loop: Bool) {
        update(source: source, loop: loop)
        orderFrontRegardless()
    }

    func update(source: WallpaperSource, loop: Bool) {
        // Remove existing content
        if let existing = content {
            existing.removeFromSuperview()
        }

        let newView: (NSView & WallpaperPlayable)
        let frame = contentRect(forFrameRect: frame)

        switch source {
        case .video(let url):
            newView = VideoWallpaperView(frame: frame, url: url, loop: loop)
        case .bundledVideo(let name, let ext):
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                newView = VideoWallpaperView(frame: frame, url: url, loop: loop)
            } else {
                // Fallback to empty black view
                let v = VideoWallpaperView(frame: frame, url: URL(fileURLWithPath: "/dev/null"), loop: loop)
                newView = v
            }
        case .web(let url):
            newView = WebWallpaperView(frame: frame, url: url)
            newView.setLoop(loop)
        }

        newView.autoresizingMask = [.width, .height]
        contentView = NSView(frame: frame)
        contentView?.wantsLayer = true
        contentView?.layer?.backgroundColor = NSColor.black.cgColor
        contentView?.addSubview(newView)
        content = newView
    }

    func play() {
        content?.play()
    }

    func pause() {
        content?.pause()
    }

    func setMuted(_ muted: Bool) {
        content?.setMuted(muted)
    }
}
