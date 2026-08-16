import Cocoa
import AVFoundation

final class WallpaperView: NSView {

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    override init(frame frameRect: NSRect) {

        super.init(frame: frameRect)

        wantsLayer = true

        setupPlayer()
    }

    required init?(coder: NSCoder) {

        super.init(coder: coder)

        wantsLayer = true

        setupPlayer()
    }

    private func setupPlayer() {

        guard let url = Bundle.main.url(
            forResource: "wallpaper",
            withExtension: "mp4"
        ) else {

            print("❌ wallpaper.mp4 not found")

            return
        }

        let player = AVPlayer(url: url)

        self.player = player

        let layer = AVPlayerLayer(player: player)

        layer.videoGravity = .resizeAspectFill

        self.playerLayer = layer

        self.layer?.addSublayer(layer)

        player.play()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoEnded),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
    }

    @objc private func videoEnded() {

        player?.seek(to: .zero)

        player?.play()
    }

    override func layout() {

        super.layout()

        playerLayer?.frame = bounds
    }
}
