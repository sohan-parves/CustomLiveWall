import Cocoa

final class ScreenLockMonitor {

    static let shared = ScreenLockMonitor()

    var onLockOrSleep: (() -> Void)?
    var onUnlockOrWake: (() -> Void)?

    private var observers: [NSObjectProtocol] = []

    func start() {
        stop()
        let center = DistributedNotificationCenter.default()
        observers.append(center.addObserver(forName: NSNotification.Name("com.apple.screenIsLocked"), object: nil, queue: .main) { [weak self] _ in
            self?.onLockOrSleep?()
        })
        observers.append(center.addObserver(forName: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil, queue: .main) { [weak self] _ in
            self?.onUnlockOrWake?()
        })
        observers.append(center.addObserver(forName: NSNotification.Name("com.apple.screensaver.didstart"), object: nil, queue: .main) { [weak self] _ in
            self?.onLockOrSleep?()
        })
        observers.append(center.addObserver(forName: NSNotification.Name("com.apple.screensaver.didstop"), object: nil, queue: .main) { [weak self] _ in
            self?.onUnlockOrWake?()
        })
    }

    func stop() {
        let center = DistributedNotificationCenter.default()
        for o in observers { center.removeObserver(o) }
        observers.removeAll()
    }
}
