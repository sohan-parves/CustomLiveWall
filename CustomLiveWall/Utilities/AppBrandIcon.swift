import AppKit
import SwiftUI

enum AppBrandIcon {
    static var image: NSImage? {
        if let url = Bundle.main.url(forResource: "icon", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        return NSApp.applicationIconImage
    }

    static func applyApplicationIcon() {
        guard let image = image else { return }
        NSApp.applicationIconImage = image
    }
}

struct AppBrandIconView: View {
    var size: CGFloat = 52
    var cornerRadius: CGFloat = 14

    var body: some View {
        Group {
            if let image = AppBrandIcon.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [.blue.opacity(0.85), .purple.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "sparkles")
                        .font(.system(size: size * 0.45, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}
