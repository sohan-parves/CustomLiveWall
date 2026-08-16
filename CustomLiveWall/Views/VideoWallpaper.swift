import Cocoa
import AVFoundation

final class VideoWallpaperView: NSView, WallpaperPlayable {

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?
    private var shouldLoop: Bool
    private var videoURL: URL?

    init(frame: NSRect, url: URL, loop: Bool) {
        self.shouldLoop = loop
        self.videoURL = url
        super.init(frame: frame)
        wantsLayer = true
        setupPlayer(url: url)
    }

    required init?(coder: NSCoder) {
        self.shouldLoop = true
        super.init(coder: coder)
        wantsLayer = true
    }

    func setLoop(_ loop: Bool) {
        shouldLoop = loop
        if let url = videoURL {
            // Recreate player with new loop setting
            playerLayer?.removeFromSuperlayer()
            playerLooper = nil
            player = nil
            setupPlayer(url: url)
            play()
        }
    }

    private func setupPlayer(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        
        if shouldLoop {
            // Use AVPlayerLooper for gapless, smooth looping
            let queuePlayer = AVQueuePlayer(playerItem: playerItem)
            playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
            player = queuePlayer
        } else {
            // Regular player without looping
            let player = AVPlayer(playerItem: playerItem)
            self.player = player
        }

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        self.playerLayer = layer
        self.layer?.addSublayer(layer)
    }

    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func setMuted(_ muted: Bool) {
        player?.isMuted = muted
    }
}
