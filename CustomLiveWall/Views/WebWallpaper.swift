import Cocoa
import WebKit

final class WebWallpaperView: NSView, WallpaperPlayable {

    private let webView = WKWebView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    convenience init(frame: NSRect, url: URL) {
        self.init(frame: frame)
        webView.load(URLRequest(url: url))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        wantsLayer = true
        webView.frame = bounds
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        addSubview(webView)
    }

    func play() {
        webView.evaluateJavaScript("document.querySelectorAll('video').forEach(v=>v.play())")
    }

    func pause() {
        webView.evaluateJavaScript("document.querySelectorAll('video').forEach(v=>v.pause())")
    }

    func setLoop(_ loop: Bool) {
        let js = "document.querySelectorAll('video').forEach(v=>v.loop = " + (loop ? "true" : "false") + ")"
        webView.evaluateJavaScript(js)
    }

    func setMuted(_ muted: Bool) {
        let js = "document.querySelectorAll('video').forEach(v=>v.muted = " + (muted ? "true" : "false") + ")"
        webView.evaluateJavaScript(js)
    }
}
