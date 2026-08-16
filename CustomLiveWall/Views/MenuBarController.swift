import Cocoa

final class MenuBarController {

    private let statusItem: NSStatusItem

    private let onTogglePlayPause: () -> Void
    private let onToggleMute: (Bool) -> Void
    private let onChooseWallpaper: () -> Void
    private let onSelectSample: (SampleWallpaper) -> Void
    private let onOpenSettings: () -> Void
    private let onToggleLaunchAtLogin: (Bool) -> Void

    private let isPlayingProvider: () -> Bool
    private let isMutedProvider: () -> Bool
    private let launchAtLoginProvider: () -> Bool
    private let currentSourceProvider: () -> WallpaperSource?

    init(
        onTogglePlayPause: @escaping () -> Void,
        onToggleMute: @escaping (Bool) -> Void,
        onChooseWallpaper: @escaping () -> Void,
        onSelectSample: @escaping (SampleWallpaper) -> Void,
        onOpenSettings: @escaping () -> Void,
        onToggleLaunchAtLogin: @escaping (Bool) -> Void,
        isPlayingProvider: @escaping () -> Bool,
        isMutedProvider: @escaping () -> Bool,
        launchAtLoginProvider: @escaping () -> Bool,
        currentSourceProvider: @escaping () -> WallpaperSource?
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.onTogglePlayPause = onTogglePlayPause
        self.onToggleMute = onToggleMute
        self.onChooseWallpaper = onChooseWallpaper
        self.onSelectSample = onSelectSample
        self.onOpenSettings = onOpenSettings
        self.onToggleLaunchAtLogin = onToggleLaunchAtLogin
        self.isPlayingProvider = isPlayingProvider
        self.isMutedProvider = isMutedProvider
        self.launchAtLoginProvider = launchAtLoginProvider
        self.currentSourceProvider = currentSourceProvider

        statusItem.button?.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "LiveWall")
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.appearsDisabled = false

        rebuildMenu()
    }

    func updateIsPlaying(_ playing: Bool) {
        rebuildMenu()
    }

    func updateMenu() {
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let playPauseTitle = isPlayingProvider() ? "Pause" : "Play"
        let playPauseIcon = isPlayingProvider() ? "pause.fill" : "play.fill"
        let playPauseItem = NSMenuItem(
            title: playPauseTitle,
            action: #selector(handleTogglePlayPause),
            keyEquivalent: ""
        )
        playPauseItem.image = NSImage(systemSymbolName: playPauseIcon, accessibilityDescription: nil)
        menu.addItem(playPauseItem)

        let muted = isMutedProvider()
        let muteItem = NSMenuItem(
            title: "Mute Audio",
            action: #selector(handleToggleMute(_:)),
            keyEquivalent: ""
        )
        muteItem.state = muted ? .on : .off
        muteItem.image = NSImage(
            systemSymbolName: muted ? "speaker.slash.fill" : "speaker.wave.2.fill",
            accessibilityDescription: nil
        )
        menu.addItem(muteItem)

        menu.addItem(.separator())

        let samplesMenu = NSMenu()
        for sample in SampleWallpaperCatalog.samples {
            let item = NSMenuItem(
                title: sample.name,
                action: #selector(handleSelectSample(_:)),
                keyEquivalent: ""
            )
            item.representedObject = sample.id
            item.image = NSImage(systemSymbolName: sample.icon, accessibilityDescription: nil)

            if isCurrentSample(sample) {
                item.state = .on
            }

            samplesMenu.addItem(item)
        }

        let samplesParent = NSMenuItem(title: "Sample Wallpapers", action: nil, keyEquivalent: "")
        samplesParent.submenu = samplesMenu
        samplesParent.image = NSImage(systemSymbolName: "photo.on.rectangle.angled", accessibilityDescription: nil)
        menu.addItem(samplesParent)

        menu.addItem(withTitle: "Choose Video File…", action: #selector(handleChooseWallpaper), keyEquivalent: "")

        menu.addItem(.separator())

        let launch = NSMenuItem(title: "Launch at Login", action: #selector(handleToggleLaunchAtLogin(_:)), keyEquivalent: "")
        launch.state = launchAtLoginProvider() ? .on : .off
        launch.target = self
        menu.addItem(launch)

        menu.addItem(withTitle: "Settings…", action: #selector(handleOpenSettings), keyEquivalent: ",")

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit LiveWall", action: #selector(handleQuit), keyEquivalent: "q")

        for item in menu.items { item.target = self }
        statusItem.menu = menu
    }

    private func isCurrentSample(_ sample: SampleWallpaper) -> Bool {
        guard let source = currentSourceProvider() else { return false }
        guard case .bundledVideo(let name, let ext) = source else { return false }
        return sample.resourceName == name && sample.ext == ext
    }

    @objc private func handleTogglePlayPause() { onTogglePlayPause() }

    @objc private func handleToggleMute(_ sender: NSMenuItem) {
        let newValue = sender.state != .on
        sender.state = newValue ? .on : .off
        onToggleMute(newValue)
        rebuildMenu()
    }

    @objc private func handleChooseWallpaper() { onChooseWallpaper() }

    @objc private func handleSelectSample(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let sample = SampleWallpaperCatalog.sample(for: id) else { return }
        onSelectSample(sample)
    }

    @objc private func handleOpenSettings() { onOpenSettings() }

    @objc private func handleToggleLaunchAtLogin(_ sender: NSMenuItem) {
        let newValue = sender.state != .on
        sender.state = newValue ? .on : .off
        onToggleLaunchAtLogin(newValue)
    }

    @objc private func handleQuit() { NSApplication.shared.terminate(nil) }
}
