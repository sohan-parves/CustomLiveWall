import AVFoundation
import AppKit

enum VideoThumbnailGenerator {
    static func thumbnail(for url: URL, size: CGSize = CGSize(width: 320, height: 180)) async -> NSImage? {
        await withCheckedContinuation { continuation in
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = size

            let time = CMTime(seconds: 0.5, preferredTimescale: 600)
            generator.generateCGImageAsynchronously(for: time) { cgImage, _, error in
                guard let cgImage, error == nil else {
                    continuation.resume(returning: nil)
                    return
                }

                let image = NSImage(
                    cgImage: cgImage,
                    size: NSSize(width: cgImage.width, height: cgImage.height)
                )
                continuation.resume(returning: image)
            }
        }
    }

    static func bundledThumbnail(resourceName: String, ext: String) async -> NSImage? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: ext) else { return nil }
        return await thumbnail(for: url)
    }
}
