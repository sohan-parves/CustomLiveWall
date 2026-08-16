import Foundation

enum WallpaperSource: Equatable {
    case video(URL)
    case web(URL)
    case bundledVideo(name: String, ext: String = "mp4")
}
