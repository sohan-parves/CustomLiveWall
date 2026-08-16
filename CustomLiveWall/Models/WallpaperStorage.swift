import Foundation

final class WallpaperStorage {

    static let shared = WallpaperStorage()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let selectedVideoURL = "selectedVideoURL"
        static let selectedWebURL = "selectedWebURL"
        static let selectedSampleID = "selectedSampleID"
        static let selectedImportedID = "selectedImportedID"
        static let importedWallpapers = "importedWallpapers"
        static let loopVideo = "loopVideo"
        static let pauseOnBattery = "pauseOnBattery"
        static let pauseOnLock = "pauseOnLock"
        static let launchAtLogin = "launchAtLogin"
        static let audioMuted = "audioMuted"
    }

    var selectedVideoURL: URL? {
        get { defaults.url(forKey: Keys.selectedVideoURL) }
        set { defaults.set(newValue, forKey: Keys.selectedVideoURL) }
    }

    var selectedWebURL: URL? {
        get { defaults.url(forKey: Keys.selectedWebURL) }
        set { defaults.set(newValue, forKey: Keys.selectedWebURL) }
    }

    var selectedSampleID: String {
        get { defaults.string(forKey: Keys.selectedSampleID) ?? SampleWallpaperCatalog.defaultSample.id }
        set { defaults.set(newValue, forKey: Keys.selectedSampleID) }
    }

    var selectedImportedID: String? {
        get { defaults.string(forKey: Keys.selectedImportedID) }
        set { defaults.set(newValue, forKey: Keys.selectedImportedID) }
    }

    var importedWallpapers: [ImportedWallpaper] {
        get {
            guard let data = defaults.data(forKey: Keys.importedWallpapers),
                  let wallpapers = try? JSONDecoder().decode([ImportedWallpaper].self, from: data) else {
                return []
            }
            return wallpapers
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults.set(data, forKey: Keys.importedWallpapers)
        }
    }

    var loopVideo: Bool {
        get { defaults.object(forKey: Keys.loopVideo) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.loopVideo) }
    }

    var pauseOnBattery: Bool {
        get { defaults.object(forKey: Keys.pauseOnBattery) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.pauseOnBattery) }
    }

    var pauseOnLock: Bool {
        get { defaults.object(forKey: Keys.pauseOnLock) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.pauseOnLock) }
    }

    var launchAtLogin: Bool {
        get { defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.launchAtLogin) }
    }

    var audioMuted: Bool {
        get { defaults.object(forKey: Keys.audioMuted) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.audioMuted) }
    }
}
