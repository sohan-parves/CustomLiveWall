import Cocoa
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {

    var wallpaperManager: WallpaperManager!
    private var menuBarController: MenuBarController?
    private var cancellables = Set<AnyCancellable>()
    private var wasPlayingBeforeBatteryPause = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppBrandIcon.applyApplicationIcon()
        wallpaperManager = WallpaperManager()
        setupMenuBar()
        setupMonitors()
        wallpaperManager.start()
    }

    private func setupMenuBar() {
        menuBarController = MenuBarController(
            onTogglePlayPause: { [weak self] in
                guard let self else { return }
                if self.wallpaperManager.isPlaying {
                    self.wallpaperManager.stop()
                } else {
                    self.wallpaperManager.start()
                }
            },
            onToggleMute: { [weak self] muted in
                self?.wallpaperManager.setMuted(muted)
            },
            onChooseWallpaper: { [weak self] in
                guard let self else { return }
                WallpaperPicker.pickVideo { url in
                    guard let url else { return }
                    self.wallpaperManager.importVideo(from: url)
                }
            },
            onSelectSample: { [weak self] sample in
                self?.wallpaperManager.selectGalleryItem(.sample(sample))
            },
            onOpenSettings: { [weak self] in
                guard let self else { return }
                SettingsWindowController.shared.showSettings(wallpaperManager: self.wallpaperManager)
            },
            onToggleLaunchAtLogin: { enabled in
                WallpaperStorage.shared.launchAtLogin = enabled
                LoginItemManager.shared.setEnabled(enabled)
            },
            isPlayingProvider: { [weak self] in
                self?.wallpaperManager.isPlaying ?? false
            },
            isMutedProvider: { [weak self] in
                self?.wallpaperManager.isMuted ?? false
            },
            launchAtLoginProvider: {
                WallpaperStorage.shared.launchAtLogin
            },
            currentSourceProvider: { [weak self] in
                self?.wallpaperManager.currentSource
            }
        )

        wallpaperManager.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playing in
                self?.menuBarController?.updateIsPlaying(playing)
            }
            .store(in: &cancellables)

        wallpaperManager.$isMuted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.menuBarController?.updateMenu()
            }
            .store(in: &cancellables)

        wallpaperManager.$currentSource
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.menuBarController?.updateMenu()
            }
            .store(in: &cancellables)
    }

    private func setupMonitors() {
        BatteryMonitor.shared.onPowerSourceChanged = { [weak self] onBattery in
            guard let self, WallpaperStorage.shared.pauseOnBattery else { return }
            if onBattery {
                self.wasPlayingBeforeBatteryPause = self.wallpaperManager.isPlaying
                if self.wasPlayingBeforeBatteryPause {
                    self.wallpaperManager.stop()
                }
            } else if self.wasPlayingBeforeBatteryPause {
                self.wallpaperManager.start()
                self.wasPlayingBeforeBatteryPause = false
            }
        }
        BatteryMonitor.shared.start()

        ScreenLockMonitor.shared.onLockOrSleep = { [weak self] in
            guard let self, WallpaperStorage.shared.pauseOnLock else { return }
            if self.wallpaperManager.isPlaying {
                self.wallpaperManager.stop()
            }
        }
        ScreenLockMonitor.shared.start()
    }
}
