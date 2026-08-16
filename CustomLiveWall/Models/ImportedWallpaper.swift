import Foundation

struct ImportedWallpaper: Identifiable, Codable, Equatable {
    let id: String
    let displayName: String
    let fileExtension: String
    let addedAt: Date

    var storedFileName: String { "\(id).\(fileExtension)" }

    func fileURL(in directory: URL) -> URL {
        directory.appendingPathComponent(storedFileName)
    }
}

enum WallpaperGalleryItem: Identifiable, Equatable {
    case sample(SampleWallpaper)
    case imported(ImportedWallpaper)

    var id: String {
        switch self {
        case .sample(let sample): return "sample-\(sample.id)"
        case .imported(let imported): return "imported-\(imported.id)"
        }
    }

    var name: String {
        switch self {
        case .sample(let sample): return sample.name
        case .imported(let imported): return imported.displayName
        }
    }

    var subtitle: String {
        switch self {
        case .sample(let sample): return sample.subtitle
        case .imported: return "Imported video"
        }
    }

    var icon: String {
        switch self {
        case .sample(let sample): return sample.icon
        case .imported: return "film.fill"
        }
    }

    var source: WallpaperSource {
        switch self {
        case .sample(let sample):
            return sample.bundledSource
        case .imported(let imported):
            let url = ImportedWallpaperStore.shared.resolveURL(for: imported)
            return .video(url ?? URL(fileURLWithPath: "/dev/null"))
        }
    }
}

final class ImportedWallpaperStore {
    static let shared = ImportedWallpaperStore()

    private let fileManager = FileManager.default

    private var importDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("CustomLiveWall/Imported", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @discardableResult
    func importVideo(from sourceURL: URL) throws -> ImportedWallpaper {
        let id = UUID().uuidString
        let ext = sourceURL.pathExtension.isEmpty ? "mp4" : sourceURL.pathExtension
        let imported = ImportedWallpaper(
            id: id,
            displayName: sourceURL.deletingPathExtension().lastPathComponent,
            fileExtension: ext,
            addedAt: Date()
        )

        let destination = imported.fileURL(in: importDirectory)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: sourceURL, to: destination)
        return imported
    }

    func resolveURL(for imported: ImportedWallpaper) -> URL? {
        let url = imported.fileURL(in: importDirectory)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func delete(_ imported: ImportedWallpaper) throws {
        let url = imported.fileURL(in: importDirectory)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
}
