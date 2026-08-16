import Cocoa
import Combine

final class WallpaperManager: ObservableObject {

    static let shared = WallpaperManager()

    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isMuted: Bool = false
    @Published private(set) var currentSource: WallpaperSource
    @Published private(set) var importedWallpapers: [ImportedWallpaper] = []

    private var wallpaperWindows: [NSScreen: WallpaperWindow] = [:]

    var galleryItems: [WallpaperGalleryItem] {
        SampleWallpaperCatalog.samples.map { .sample($0) } +
        importedWallpapers.map { .imported($0) }
    }

    init() {
        self.isMuted = WallpaperStorage.shared.audioMuted
        self.importedWallpapers = WallpaperStorage.shared.importedWallpapers
        self.currentSource = Self.resolveInitialSource(from: WallpaperStorage.shared)
    }

    func setSource(_ source: WallpaperSource) {
        currentSource = source
        switch source {
        case .video(let url):
            WallpaperStorage.shared.selectedWebURL = nil
            if let imported = importedWallpapers.first(where: { ImportedWallpaperStore.shared.resolveURL(for: $0) == url }) {
                WallpaperStorage.shared.selectedImportedID = imported.id
                WallpaperStorage.shared.selectedVideoURL = nil
            } else {
                WallpaperStorage.shared.selectedImportedID = nil
                WallpaperStorage.shared.selectedVideoURL = url
            }
        case .web(let url):
            WallpaperStorage.shared.selectedWebURL = url
            WallpaperStorage.shared.selectedVideoURL = nil
            WallpaperStorage.shared.selectedImportedID = nil
        case .bundledVideo(let name, let ext):
            WallpaperStorage.shared.selectedVideoURL = nil
            WallpaperStorage.shared.selectedWebURL = nil
            WallpaperStorage.shared.selectedImportedID = nil
            if let sample = SampleWallpaperCatalog.samples.first(where: { $0.resourceName == name && $0.ext == ext }) {
                WallpaperStorage.shared.selectedSampleID = sample.id
            }
        }
        refreshAllWindows()
    }

    func selectGalleryItem(_ item: WallpaperGalleryItem) {
        switch item {
        case .sample(let sample):
            selectAndPlay(sample.bundledSource)
        case .imported(let imported):
            guard let url = ImportedWallpaperStore.shared.resolveURL(for: imported) else { return }
            WallpaperStorage.shared.selectedImportedID = imported.id
            selectAndPlay(.video(url))
        }
    }

    func applySample(_ sample: SampleWallpaper) {
        selectGalleryItem(.sample(sample))
    }

    @discardableResult
    func importVideo(from url: URL) -> ImportedWallpaper? {
        do {
            let imported = try ImportedWallpaperStore.shared.importVideo(from: url)
            var wallpapers = WallpaperStorage.shared.importedWallpapers
            wallpapers.removeAll { $0.id == imported.id }
            wallpapers.insert(imported, at: 0)
            WallpaperStorage.shared.importedWallpapers = wallpapers
            importedWallpapers = wallpapers
            selectGalleryItem(.imported(imported))
            return imported
        } catch {
            NSLog("Failed to import wallpaper video: \(error.localizedDescription)")
            return nil
        }
    }

    func removeImportedWallpaper(_ imported: ImportedWallpaper) {
        do {
            try ImportedWallpaperStore.shared.delete(imported)
        } catch {
            NSLog("Failed to delete imported wallpaper: \(error.localizedDescription)")
            return
        }

        var wallpapers = WallpaperStorage.shared.importedWallpapers
        wallpapers.removeAll { $0.id == imported.id }
        WallpaperStorage.shared.importedWallpapers = wallpapers
        importedWallpapers = wallpapers

        if WallpaperStorage.shared.selectedImportedID == imported.id {
            WallpaperStorage.shared.selectedImportedID = nil
            let defaultSample = SampleWallpaperCatalog.defaultSample
            selectAndPlay(defaultSample.bundledSource)
        }
    }

    func selectAndPlay(_ source: WallpaperSource) {
        setSource(source)
        start()
    }

    func refreshAllWindows() {
        for (_, window) in wallpaperWindows {
            window.update(source: currentSource, loop: WallpaperStorage.shared.loopVideo)
            window.setMuted(isMuted)
            if isPlaying {
                window.play()
            }
        }
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        WallpaperStorage.shared.audioMuted = muted
        for (_, window) in wallpaperWindows {
            window.setMuted(muted)
        }
    }

    func start() {
        isPlaying = true

        for screen in NSScreen.screens {
            let window: WallpaperWindow
            if let existing = wallpaperWindows[screen] {
                window = existing
            } else {
                window = WallpaperWindow(screen: screen)
                wallpaperWindows[screen] = window
            }

            if window.contentView == nil {
                window.showWallpaper(source: currentSource, loop: WallpaperStorage.shared.loopVideo)
            } else {
                window.update(source: currentSource, loop: WallpaperStorage.shared.loopVideo)
            }

            window.play()
            window.setMuted(isMuted)
            window.orderFrontRegardless()
        }
    }

    func stop() {
        isPlaying = false
        for (_, window) in wallpaperWindows {
            window.pause()
        }
    }

    func isGalleryItemSelected(_ item: WallpaperGalleryItem) -> Bool {
        switch item {
        case .sample(let sample):
            guard case .bundledVideo(let name, let ext) = currentSource else { return false }
            return sample.resourceName == name && sample.ext == ext
        case .imported(let imported):
            guard case .video(let url) = currentSource else { return false }
            return ImportedWallpaperStore.shared.resolveURL(for: imported) == url
        }
    }

    private static func resolveInitialSource(from storage: WallpaperStorage) -> WallpaperSource {
        if let importedID = storage.selectedImportedID,
           let imported = storage.importedWallpapers.first(where: { $0.id == importedID }),
           let url = ImportedWallpaperStore.shared.resolveURL(for: imported) {
            return .video(url)
        }

        if let url = storage.selectedVideoURL {
            return .video(url)
        }

        if let webURL = storage.selectedWebURL {
            return .web(webURL)
        }

        if let sample = SampleWallpaperCatalog.sample(for: storage.selectedSampleID) {
            return sample.bundledSource
        }

        let defaultSample = SampleWallpaperCatalog.defaultSample
        storage.selectedSampleID = defaultSample.id
        return defaultSample.bundledSource
    }
}
