import Foundation

struct SampleWallpaper: Identifiable, Equatable {
    let id: String
    let name: String
    let subtitle: String
    let resourceName: String
    let ext: String
    let icon: String

    var bundledSource: WallpaperSource {
        .bundledVideo(name: resourceName, ext: ext)
    }
}

enum SampleWallpaperCatalog {
    static let samples: [SampleWallpaper] = [
        SampleWallpaper(
            id: "furina-dance",
            name: "Furina Dance",
            subtitle: "Viral funk dance edit",
            resourceName: "Furina dance driving me crazy(2K_60FPS)",
            ext: "mp4",
            icon: "sparkles"
        ),
        SampleWallpaper(
            id: "anime-mystery",
            name: "Anime Mystery",
            subtitle: "Girl behind curtains",
            resourceName: "Girl Behind Curtains _ [4K] _ Anime Mystery Live Wallpaper now has 1541442 views_(4K_HD)",
            ext: "mp4",
            icon: "moon.stars.fill"
        )
    ]

    static var defaultSample: SampleWallpaper { samples[0] }

    static func sample(for id: String) -> SampleWallpaper? {
        samples.first { $0.id == id }
    }

    static func sample(matching source: WallpaperSource) -> SampleWallpaper? {
        guard case .bundledVideo(let name, let ext) = source else { return nil }
        return samples.first { $0.resourceName == name && $0.ext == ext }
    }
}
